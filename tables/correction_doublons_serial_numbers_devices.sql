-- Script de correction des doublons de numéros de série dans la table devices
-- Version: 1.0
-- Date: 2025

-- 1. Vérifier les doublons de numéros de série existants
DO $$
DECLARE
    duplicate_count INTEGER;
    duplicate_records RECORD;
BEGIN
    RAISE NOTICE '=== Vérification des doublons de numéros de série ===';
    
    -- Compter les doublons
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT serial_number, COUNT(*) as count
        FROM devices
        WHERE serial_number IS NOT NULL AND serial_number != ''
        GROUP BY serial_number
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE 'Nombre de doublons de numéros de série trouvés: %', duplicate_count;
    
    -- Afficher les doublons
    IF duplicate_count > 0 THEN
        RAISE NOTICE 'Détails des doublons:';
        FOR duplicate_records IN
            SELECT serial_number, COUNT(*) as count, 
                   STRING_AGG(CONCAT(brand, ' ', model, ' (ID: ', id, ')'), ', ') as devices
            FROM devices
            WHERE serial_number IS NOT NULL AND serial_number != ''
            GROUP BY serial_number
            HAVING COUNT(*) > 1
            ORDER BY serial_number
        LOOP
            RAISE NOTICE '  Numéro de série: % - % appareils: %', 
                duplicate_records.serial_number, 
                duplicate_records.count, 
                duplicate_records.devices;
        END LOOP;
    ELSE
        RAISE NOTICE '✅ Aucun doublon de numéro de série trouvé';
    END IF;
END $$;

-- 2. Créer une fonction pour nettoyer les doublons
CREATE OR REPLACE FUNCTION clean_duplicate_serial_numbers()
RETURNS TABLE (
    serial_number TEXT,
    kept_device_id UUID,
    removed_device_id UUID,
    action TEXT
) AS $$
DECLARE
    duplicate_record RECORD;
    device_record RECORD;
    kept_id UUID;
    removed_count INTEGER := 0;
BEGIN
    -- Parcourir tous les doublons
    FOR duplicate_record IN
        SELECT serial_number, COUNT(*) as count
        FROM devices
        WHERE serial_number IS NOT NULL AND serial_number != ''
        GROUP BY serial_number
        HAVING COUNT(*) > 1
    LOOP
        -- Garder l'appareil le plus récent (ou le premier si même date)
        SELECT id INTO kept_id
        FROM devices
        WHERE serial_number = duplicate_record.serial_number
        ORDER BY updated_at DESC, created_at DESC, id
        LIMIT 1;
        
        -- Supprimer les autres appareils avec le même numéro de série
        FOR device_record IN
            SELECT id
            FROM devices
            WHERE serial_number = duplicate_record.serial_number
            AND id != kept_id
        LOOP
            -- Supprimer les réparations associées à l'appareil à supprimer
            DELETE FROM repairs WHERE device_id = device_record.id;
            
            -- Supprimer l'appareil
            DELETE FROM devices WHERE id = device_record.id;
            
            -- Retourner l'information
            serial_number := duplicate_record.serial_number;
            kept_device_id := kept_id;
            removed_device_id := device_record.id;
            action := 'Supprimé';
            RETURN NEXT;
            
            removed_count := removed_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Nettoyage terminé: % appareils supprimés', removed_count;
END;
$$ LANGUAGE plpgsql;

-- 3. Créer une fonction pour suggérer des corrections de numéros de série
CREATE OR REPLACE FUNCTION suggest_serial_number_corrections()
RETURNS TABLE (
    device_id UUID,
    current_serial_number TEXT,
    suggested_serial_number TEXT,
    reason TEXT
) AS $$
DECLARE
    device_record RECORD;
    base_serial TEXT;
    counter INTEGER;
    new_serial TEXT;
BEGIN
    -- Pour chaque appareil avec un numéro de série en doublon
    FOR device_record IN
        SELECT d.id, d.serial_number, d.brand, d.model
        FROM devices d
        WHERE d.serial_number IN (
            SELECT serial_number
            FROM devices
            WHERE serial_number IS NOT NULL AND serial_number != ''
            GROUP BY serial_number
            HAVING COUNT(*) > 1
        )
        ORDER BY d.serial_number, d.created_at
    LOOP
        -- Utiliser le numéro de série comme base
        base_serial := device_record.serial_number;
        
        -- Chercher un numéro de série unique
        counter := 1;
        new_serial := base_serial || '_' || counter;
        
        WHILE EXISTS (SELECT 1 FROM devices WHERE serial_number = new_serial) LOOP
            counter := counter + 1;
            new_serial := base_serial || '_' || counter;
        END LOOP;
        
        device_id := device_record.id;
        current_serial_number := device_record.serial_number;
        suggested_serial_number := new_serial;
        reason := 'Doublon de numéro de série détecté';
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. Créer une fonction pour valider les numéros de série
CREATE OR REPLACE FUNCTION validate_serial_number_format(serial_number TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validation basique de numéro de série
    -- Permet les lettres, chiffres, tirets, underscores
    RETURN serial_number ~* '^[A-Za-z0-9\-_]+$';
END;
$$ LANGUAGE plpgsql;

-- 5. Créer un trigger pour empêcher les doublons de numéros de série
CREATE OR REPLACE FUNCTION prevent_duplicate_serial_numbers()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si le numéro de série existe déjà (sauf pour l'enregistrement en cours de modification)
    IF NEW.serial_number IS NOT NULL AND NEW.serial_number != '' THEN
        IF EXISTS (
            SELECT 1 FROM devices 
            WHERE serial_number = NEW.serial_number 
            AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
        ) THEN
            RAISE EXCEPTION 'Un appareil avec le numéro de série % existe déjà', NEW.serial_number;
        END IF;
        
        -- Valider le format du numéro de série
        IF NOT validate_serial_number_format(NEW.serial_number) THEN
            RAISE EXCEPTION 'Format de numéro de série invalide: %', NEW.serial_number;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS trigger_prevent_duplicate_serial_numbers ON devices;

-- Créer le trigger
CREATE TRIGGER trigger_prevent_duplicate_serial_numbers
    BEFORE INSERT OR UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_serial_numbers();

-- 6. Créer une fonction pour générer des numéros de série uniques
CREATE OR REPLACE FUNCTION generate_unique_serial_number(base_serial TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    new_serial TEXT;
    counter INTEGER := 1;
BEGIN
    -- Si aucun numéro de base fourni, générer un numéro par défaut
    IF base_serial IS NULL OR base_serial = '' THEN
        base_serial := 'SN' || EXTRACT(EPOCH FROM NOW())::TEXT;
    END IF;
    
    new_serial := base_serial;
    
    -- Chercher un numéro de série unique
    WHILE EXISTS (SELECT 1 FROM devices WHERE serial_number = new_serial) LOOP
        counter := counter + 1;
        new_serial := base_serial || '_' || counter;
    END LOOP;
    
    RETURN new_serial;
END;
$$ LANGUAGE plpgsql;

-- 7. Exécuter le nettoyage des doublons (optionnel - décommentez si nécessaire)
-- SELECT * FROM clean_duplicate_serial_numbers();

-- 8. Afficher les suggestions de correction (optionnel)
-- SELECT * FROM suggest_serial_number_corrections();

-- 9. Vérification finale
DO $$
DECLARE
    final_duplicate_count INTEGER;
    total_devices INTEGER;
    devices_with_serial INTEGER;
    devices_without_serial INTEGER;
BEGIN
    RAISE NOTICE '=== Vérification finale ===';
    
    -- Compter le nombre total d'appareils
    SELECT COUNT(*) INTO total_devices FROM devices;
    RAISE NOTICE 'Nombre total d''appareils: %', total_devices;
    
    -- Compter les appareils avec/sans numéro de série
    SELECT COUNT(*) INTO devices_with_serial FROM devices WHERE serial_number IS NOT NULL AND serial_number != '';
    SELECT COUNT(*) INTO devices_without_serial FROM devices WHERE serial_number IS NULL OR serial_number = '';
    
    RAISE NOTICE 'Appareils avec numéro de série: %', devices_with_serial;
    RAISE NOTICE 'Appareils sans numéro de série: %', devices_without_serial;
    
    -- Vérifier s'il reste des doublons
    SELECT COUNT(*) INTO final_duplicate_count
    FROM (
        SELECT serial_number, COUNT(*) as count
        FROM devices
        WHERE serial_number IS NOT NULL AND serial_number != ''
        GROUP BY serial_number
        HAVING COUNT(*) > 1
    ) duplicates;
    
    IF final_duplicate_count = 0 THEN
        RAISE NOTICE '✅ Aucun doublon de numéro de série restant';
    ELSE
        RAISE NOTICE '⚠️ % doublons de numéros de série restants', final_duplicate_count;
    END IF;
    
    -- Afficher les statistiques des numéros de série
    RAISE NOTICE 'Statistiques des numéros de série:';
    RAISE NOTICE '- Numéros de série uniques: %', (SELECT COUNT(DISTINCT serial_number) FROM devices WHERE serial_number IS NOT NULL AND serial_number != '');
END $$;

-- 10. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Configuration terminée ===';
    RAISE NOTICE '✅ Validation de numéro de série configurée';
    RAISE NOTICE '✅ Trigger anti-doublon créé';
    RAISE NOTICE '✅ Fonctions de nettoyage disponibles';
    RAISE NOTICE '';
    RAISE NOTICE 'Fonctions disponibles :';
    RAISE NOTICE '- clean_duplicate_serial_numbers() : Nettoyer les doublons existants';
    RAISE NOTICE '- suggest_serial_number_corrections() : Suggérer des corrections';
    RAISE NOTICE '- validate_serial_number_format() : Valider le format';
    RAISE NOTICE '- generate_unique_serial_number() : Générer un numéro unique';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ Pour nettoyer les doublons existants, exécutez :';
    RAISE NOTICE '   SELECT * FROM clean_duplicate_serial_numbers();';
END $$;
