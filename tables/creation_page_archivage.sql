-- Script de création et optimisation pour la page d''archivage des réparations
-- Version: 1.0
-- Date: 2025

-- 1. Vérifier et mettre à jour les contraintes de statut pour inclure 'returned'
DO $$
BEGIN
    -- Supprimer l'ancienne contrainte si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'repairs_status_check' 
        AND table_name = 'repairs'
    ) THEN
        ALTER TABLE repairs DROP CONSTRAINT repairs_status_check;
    END IF;
    
    -- Ajouter la nouvelle contrainte avec tous les statuts valides
    ALTER TABLE repairs ADD CONSTRAINT repairs_status_check 
        CHECK (status IN ('new', 'in_progress', 'waiting_parts', 'waiting_delivery', 'completed', 'cancelled', 'returned'));
        
    RAISE NOTICE 'Contrainte de statut mise à jour avec succès';
END $$;

-- 2. Créer des index pour optimiser les performances de la page d''archivage
-- Index sur le statut pour filtrer rapidement les réparations restituées
CREATE INDEX IF NOT EXISTS idx_repairs_status ON repairs(status);

-- Index composite sur statut et date de mise à jour pour le tri chronologique
CREATE INDEX IF NOT EXISTS idx_repairs_status_updated_at ON repairs(status, updated_at DESC);

-- Index sur client_id pour les jointures rapides
CREATE INDEX IF NOT EXISTS idx_repairs_client_id ON repairs(client_id);

-- Index sur device_id pour les jointures rapides
CREATE INDEX IF NOT EXISTS idx_repairs_device_id ON repairs(device_id);

-- Index sur is_paid pour filtrer les réparations payées
CREATE INDEX IF NOT EXISTS idx_repairs_is_paid ON repairs(is_paid);

-- 3. Créer une vue optimisée pour les réparations archivées
CREATE OR REPLACE VIEW archived_repairs_view AS
SELECT 
    r.id,
    r.client_id,
    r.device_id,
    r.description,
    r.issue,
    r.status,
    r.total_price,
    r.is_paid,
    r.created_at,
    r.updated_at,
    r.due_date,
    r.is_urgent,
    -- Informations du client
    c.first_name as client_first_name,
    c.last_name as client_last_name,
    c.email as client_email,
    c.phone as client_phone,
    -- Informations de l'appareil
    d.brand as device_brand,
    d.model as device_model,
    d.type as device_type,
    d.serial_number as device_serial_number
FROM repairs r
LEFT JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
WHERE r.status = 'returned'
ORDER BY r.updated_at DESC;

-- 4. Créer une fonction pour obtenir les statistiques des archives
CREATE OR REPLACE FUNCTION get_archive_stats()
RETURNS TABLE (
    total_archived INTEGER,
    total_paid INTEGER,
    total_unpaid INTEGER,
    total_amount DECIMAL(10,2),
    avg_repair_time_days DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_archived,
        COUNT(*) FILTER (WHERE is_paid = true)::INTEGER as total_paid,
        COUNT(*) FILTER (WHERE is_paid = false)::INTEGER as total_unpaid,
        COALESCE(SUM(total_price), 0) as total_amount,
        COALESCE(
            AVG(
                EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400
            ), 0
        )::DECIMAL(5,2) as avg_repair_time_days
    FROM repairs 
    WHERE status = 'returned';
END;
$$ LANGUAGE plpgsql;

-- 5. Créer une fonction pour rechercher dans les archives
CREATE OR REPLACE FUNCTION search_archived_repairs(
    search_query TEXT DEFAULT '',
    device_type_filter TEXT DEFAULT 'all',
    date_filter TEXT DEFAULT 'all',
    paid_only BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    client_name TEXT,
    device_info TEXT,
    description TEXT,
    issue TEXT,
    total_price DECIMAL(10,2),
    is_paid BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    device_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        CONCAT(c.first_name, ' ', c.last_name) as client_name,
        CONCAT(d.brand, ' ', d.model) as device_info,
        r.description,
        r.issue,
        r.total_price,
        r.is_paid,
        r.created_at,
        r.updated_at,
        d.type as device_type
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE r.status = 'returned'
    AND (
        search_query = '' OR
        LOWER(c.first_name) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(c.last_name) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(c.email) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(d.brand) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(d.model) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(r.description) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(r.issue) LIKE '%' || LOWER(search_query) || '%'
    )
    AND (
        device_type_filter = 'all' OR
        d.type = device_type_filter
    )
    AND (
        NOT paid_only OR
        r.is_paid = true
    )
    AND (
        date_filter = 'all' OR
        CASE date_filter
            WHEN '30days' THEN r.updated_at >= NOW() - INTERVAL '30 days'
            WHEN '90days' THEN r.updated_at >= NOW() - INTERVAL '90 days'
            WHEN '1year' THEN r.updated_at >= NOW() - INTERVAL '1 year'
            ELSE true
        END
    )
    ORDER BY r.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 6. Créer un trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_repair_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS trigger_update_repair_updated_at ON repairs;

-- Créer le trigger
CREATE TRIGGER trigger_update_repair_updated_at
    BEFORE UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION update_repair_updated_at();

-- 7. Créer une fonction pour restaurer une réparation des archives
CREATE OR REPLACE FUNCTION restore_repair_from_archive(repair_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE repairs 
    SET status = 'completed', updated_at = NOW()
    WHERE id = repair_uuid AND status = 'returned';
    
    IF FOUND THEN
        RAISE NOTICE 'Réparation % restaurée avec succès', repair_uuid;
        RETURN true;
    ELSE
        RAISE NOTICE 'Réparation % non trouvée ou pas en archive', repair_uuid;
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 8. Créer une fonction pour obtenir les réparations archivées par période
CREATE OR REPLACE FUNCTION get_archived_repairs_by_period(period_days INTEGER)
RETURNS TABLE (
    id UUID,
    client_name TEXT,
    device_info TEXT,
    total_price DECIMAL(10,2),
    archived_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        CONCAT(c.first_name, ' ', c.last_name) as client_name,
        CONCAT(d.brand, ' ', d.model) as device_info,
        r.total_price,
        r.updated_at as archived_date
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE r.status = 'returned'
    AND r.updated_at >= NOW() - (period_days || ' days')::INTERVAL
    ORDER BY r.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 9. Vérifier les données existantes
DO $$
DECLARE
    archived_count INTEGER;
    returned_count INTEGER;
BEGIN
    -- Compter les réparations avec le statut 'returned'
    SELECT COUNT(*) INTO returned_count FROM repairs WHERE status = 'returned';
    
    -- Compter les réparations dans la vue d''archivage
    SELECT COUNT(*) INTO archived_count FROM archived_repairs_view;
    
    RAISE NOTICE 'Statistiques des archives :';
    RAISE NOTICE '- Réparations avec statut "returned": %', returned_count;
    RAISE NOTICE '- Réparations dans la vue d''archivage: %', archived_count;
    
    -- Afficher quelques exemples de réparations archivées
    RAISE NOTICE 'Exemples de réparations archivées :';
    FOR i IN 1..3 LOOP
        DECLARE
            repair_record RECORD;
        BEGIN
            SELECT * INTO repair_record 
            FROM archived_repairs_view 
            LIMIT 1 OFFSET (i-1);
            
            IF FOUND THEN
                RAISE NOTICE '  - %: % % (% €)', 
                    repair_record.id, 
                    repair_record.client_first_name, 
                    repair_record.client_last_name,
                    repair_record.total_price;
            END IF;
        END;
    END LOOP;
END $$;

-- 10. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '=== Configuration de la page d''archivage terminée ===';
    RAISE NOTICE '✓ Contraintes de statut mises à jour';
    RAISE NOTICE '✓ Index de performance créés';
    RAISE NOTICE '✓ Vue optimisée créée';
    RAISE NOTICE '✓ Fonctions utilitaires créées';
    RAISE NOTICE '✓ Trigger de mise à jour automatique configuré';
    RAISE NOTICE '';
    RAISE NOTICE 'Fonctions disponibles :';
    RAISE NOTICE '- get_archive_stats() : Statistiques des archives';
    RAISE NOTICE '- search_archived_repairs() : Recherche dans les archives';
    RAISE NOTICE '- restore_repair_from_archive() : Restaurer une réparation';
    RAISE NOTICE '- get_archived_repairs_by_period() : Réparations par période';
    RAISE NOTICE '';
    RAISE NOTICE 'Vue disponible : archived_repairs_view';
END $$;
