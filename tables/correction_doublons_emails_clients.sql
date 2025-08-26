-- Script de correction des doublons d'emails dans la table clients
-- Version: 1.0
-- Date: 2025

-- 1. Vérifier les doublons d'emails existants
DO $$
DECLARE
    duplicate_count INTEGER;
    duplicate_records RECORD;
BEGIN
    RAISE NOTICE '=== Vérification des doublons d''emails ===';
    
    -- Compter les doublons
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT email, COUNT(*) as count
        FROM clients
        WHERE email IS NOT NULL AND email != ''
        GROUP BY email
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE 'Nombre de doublons d''emails trouvés: %', duplicate_count;
    
    -- Afficher les doublons
    IF duplicate_count > 0 THEN
        RAISE NOTICE 'Détails des doublons:';
        FOR duplicate_records IN
            SELECT email, COUNT(*) as count, 
                   STRING_AGG(CONCAT(first_name, ' ', last_name, ' (ID: ', id, ')'), ', ') as clients
            FROM clients
            WHERE email IS NOT NULL AND email != ''
            GROUP BY email
            HAVING COUNT(*) > 1
            ORDER BY email
        LOOP
            RAISE NOTICE '  Email: % - % clients: %', 
                duplicate_records.email, 
                duplicate_records.count, 
                duplicate_records.clients;
        END LOOP;
    ELSE
        RAISE NOTICE '✅ Aucun doublon d''email trouvé';
    END IF;
END $$;

-- 2. Créer une fonction pour nettoyer les doublons
CREATE OR REPLACE FUNCTION clean_duplicate_emails()
RETURNS TABLE (
    email TEXT,
    kept_client_id UUID,
    removed_client_id UUID,
    action TEXT
) AS $$
DECLARE
    duplicate_record RECORD;
    client_record RECORD;
    kept_id UUID;
    removed_count INTEGER := 0;
BEGIN
    -- Parcourir tous les doublons
    FOR duplicate_record IN
        SELECT email, COUNT(*) as count
        FROM clients
        WHERE email IS NOT NULL AND email != ''
        GROUP BY email
        HAVING COUNT(*) > 1
    LOOP
        -- Garder le client le plus récent (ou le premier si même date)
        SELECT id INTO kept_id
        FROM clients
        WHERE email = duplicate_record.email
        ORDER BY updated_at DESC, created_at DESC, id
        LIMIT 1;
        
        -- Supprimer les autres clients avec le même email
        FOR client_record IN
            SELECT id
            FROM clients
            WHERE email = duplicate_record.email
            AND id != kept_id
        LOOP
            -- Supprimer les réparations associées au client à supprimer
            DELETE FROM repairs WHERE client_id = client_record.id;
            
            -- Supprimer le client
            DELETE FROM clients WHERE id = client_record.id;
            
            -- Retourner l'information
            email := duplicate_record.email;
            kept_client_id := kept_id;
            removed_client_id := client_record.id;
            action := 'Supprimé';
            RETURN NEXT;
            
            removed_count := removed_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Nettoyage terminé: % clients supprimés', removed_count;
END;
$$ LANGUAGE plpgsql;

-- 3. Créer une fonction pour suggérer des corrections d'email
CREATE OR REPLACE FUNCTION suggest_email_corrections()
RETURNS TABLE (
    client_id UUID,
    current_email TEXT,
    suggested_email TEXT,
    reason TEXT
) AS $$
DECLARE
    client_record RECORD;
    base_email TEXT;
    counter INTEGER;
    new_email TEXT;
BEGIN
    -- Pour chaque client avec un email en doublon
    FOR client_record IN
        SELECT c.id, c.email, c.first_name, c.last_name
        FROM clients c
        WHERE c.email IN (
            SELECT email
            FROM clients
            WHERE email IS NOT NULL AND email != ''
            GROUP BY email
            HAVING COUNT(*) > 1
        )
        ORDER BY c.email, c.created_at
    LOOP
        -- Extraire la partie locale de l'email (avant @)
        base_email := SPLIT_PART(client_record.email, '@', 1);
        
        -- Chercher un email unique
        counter := 1;
        new_email := base_email || counter || '@' || SPLIT_PART(client_record.email, '@', 2);
        
        WHILE EXISTS (SELECT 1 FROM clients WHERE email = new_email) LOOP
            counter := counter + 1;
            new_email := base_email || counter || '@' || SPLIT_PART(client_record.email, '@', 2);
        END LOOP;
        
        client_id := client_record.id;
        current_email := client_record.email;
        suggested_email := new_email;
        reason := 'Doublon d''email détecté';
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. Créer une fonction pour valider les emails
CREATE OR REPLACE FUNCTION validate_email_format(email_address TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validation basique d'email
    RETURN email_address ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql;

-- 5. Créer un trigger pour empêcher les doublons d'emails
CREATE OR REPLACE FUNCTION prevent_duplicate_emails()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si l'email existe déjà (sauf pour l'enregistrement en cours de modification)
    IF EXISTS (
        SELECT 1 FROM clients 
        WHERE email = NEW.email 
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
    ) THEN
        RAISE EXCEPTION 'Un client avec l''email % existe déjà', NEW.email;
    END IF;
    
    -- Valider le format de l'email
    IF NOT validate_email_format(NEW.email) THEN
        RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS trigger_prevent_duplicate_emails ON clients;

-- Créer le trigger
CREATE TRIGGER trigger_prevent_duplicate_emails
    BEFORE INSERT OR UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_emails();

-- 6. Exécuter le nettoyage des doublons (optionnel - décommentez si nécessaire)
-- SELECT * FROM clean_duplicate_emails();

-- 7. Afficher les suggestions de correction (optionnel)
-- SELECT * FROM suggest_email_corrections();

-- 8. Vérification finale
DO $$
DECLARE
    final_duplicate_count INTEGER;
    total_clients INTEGER;
BEGIN
    RAISE NOTICE '=== Vérification finale ===';
    
    -- Compter le nombre total de clients
    SELECT COUNT(*) INTO total_clients FROM clients;
    RAISE NOTICE 'Nombre total de clients: %', total_clients;
    
    -- Vérifier s'il reste des doublons
    SELECT COUNT(*) INTO final_duplicate_count
    FROM (
        SELECT email, COUNT(*) as count
        FROM clients
        WHERE email IS NOT NULL AND email != ''
        GROUP BY email
        HAVING COUNT(*) > 1
    ) duplicates;
    
    IF final_duplicate_count = 0 THEN
        RAISE NOTICE '✅ Aucun doublon d''email restant';
    ELSE
        RAISE NOTICE '⚠️ % doublons d''emails restants', final_duplicate_count;
    END IF;
    
    -- Afficher les statistiques des emails
    RAISE NOTICE 'Statistiques des emails:';
    RAISE NOTICE '- Clients avec email: %', (SELECT COUNT(*) FROM clients WHERE email IS NOT NULL AND email != '');
    RAISE NOTICE '- Clients sans email: %', (SELECT COUNT(*) FROM clients WHERE email IS NULL OR email = '');
    RAISE NOTICE '- Emails uniques: %', (SELECT COUNT(DISTINCT email) FROM clients WHERE email IS NOT NULL AND email != '');
END $$;

-- 9. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Configuration terminée ===';
    RAISE NOTICE '✅ Validation d''email configurée';
    RAISE NOTICE '✅ Trigger anti-doublon créé';
    RAISE NOTICE '✅ Fonctions de nettoyage disponibles';
    RAISE NOTICE '';
    RAISE NOTICE 'Fonctions disponibles :';
    RAISE NOTICE '- clean_duplicate_emails() : Nettoyer les doublons existants';
    RAISE NOTICE '- suggest_email_corrections() : Suggérer des corrections';
    RAISE NOTICE '- validate_email_format() : Valider le format d''email';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ Pour nettoyer les doublons existants, exécutez :';
    RAISE NOTICE '   SELECT * FROM clean_duplicate_emails();';
END $$;
