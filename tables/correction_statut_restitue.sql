-- Script de correction pour ajouter le statut "returned" (Restitué)
-- et s'assurer que les états correspondent bien à "restitué" et non "annulé"
-- Version adaptée pour la structure de base de données existante

-- 1. Vérifier la structure actuelle de la table repairs
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'repairs' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Afficher les statuts actuellement utilisés
SELECT status, COUNT(*) as count
FROM repairs
GROUP BY status
ORDER BY count DESC;

-- 3. Mettre à jour les contraintes de la table repairs pour inclure le nouveau statut
-- Supprimer l'ancienne contrainte si elle existe
ALTER TABLE repairs DROP CONSTRAINT IF EXISTS repairs_status_check;

-- Ajouter la nouvelle contrainte avec tous les statuts valides
ALTER TABLE repairs ADD CONSTRAINT repairs_status_check 
    CHECK (status IN ('new', 'in_progress', 'waiting_parts', 'waiting_delivery', 'completed', 'cancelled', 'returned'));

-- 4. Mettre à jour les vues existantes pour inclure le nouveau statut
-- Vérifier si la vue existe d'abord
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'repair_stats_view') THEN
        DROP VIEW repair_stats_view;
    END IF;
END $$;

CREATE OR REPLACE VIEW repair_stats_view AS
SELECT 
    COUNT(*) as total_repairs,
    COUNT(*) FILTER (WHERE status = 'new') as new_repairs,
    COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_repairs,
    COUNT(*) FILTER (WHERE status = 'waiting_parts') as waiting_parts_repairs,
    COUNT(*) FILTER (WHERE status = 'waiting_delivery') as waiting_delivery_repairs,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_repairs,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_repairs,
    COUNT(*) FILTER (WHERE status = 'returned') as returned_repairs,
    COUNT(*) FILTER (WHERE due_date < CURRENT_DATE AND status NOT IN ('completed', 'cancelled', 'returned')) as overdue_repairs,
    AVG(CASE WHEN status IN ('completed', 'returned') THEN EXTRACT(EPOCH FROM (updated_at - created_at))/86400 END) as avg_completion_days
FROM repairs;

-- 5. Mettre à jour les triggers pour inclure le nouveau statut
-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS check_repair_overdue_trigger ON repairs;

-- Créer la fonction de vérification des réparations en retard
CREATE OR REPLACE FUNCTION check_repair_overdue()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.due_date < CURRENT_DATE AND NEW.status NOT IN ('completed', 'cancelled', 'returned') THEN
        RAISE NOTICE 'Réparation en retard: %', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
CREATE TRIGGER check_repair_overdue_trigger
    AFTER INSERT OR UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION check_repair_overdue();

-- 6. Créer une fonction utilitaire pour convertir les statuts
CREATE OR REPLACE FUNCTION convert_cancelled_to_returned(repair_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE repairs 
    SET status = 'returned', updated_at = NOW()
    WHERE id = repair_id AND status = 'cancelled';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Réparation non trouvée ou statut différent de cancelled';
    END IF;
    
    RAISE NOTICE 'Réparation % convertie de cancelled vers returned', repair_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Créer une fonction pour lister les réparations par statut
CREATE OR REPLACE FUNCTION get_repairs_by_status(repair_status TEXT)
RETURNS TABLE (
    id UUID,
    client_name TEXT,
    device_info TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        CONCAT(c.first_name, ' ', c.last_name) as client_name,
        CONCAT(d.brand, ' ', d.model) as device_info,
        r.status,
        r.created_at,
        r.due_date
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE r.status = repair_status
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 8. Ajouter des commentaires pour clarifier les statuts
COMMENT ON COLUMN repairs.status IS 'Statuts possibles: new (Nouvelle), in_progress (En cours), waiting_parts (En attente de pièces), waiting_delivery (Livraison attendue), completed (Terminée), cancelled (Annulée), returned (Restituée)';

-- 9. Afficher un résumé des statuts actuels
SELECT 
    status,
    COUNT(*) as count,
    CASE 
        WHEN status = 'new' THEN 'Nouvelle'
        WHEN status = 'in_progress' THEN 'En cours'
        WHEN status = 'waiting_parts' THEN 'En attente de pièces'
        WHEN status = 'waiting_delivery' THEN 'Livraison attendue'
        WHEN status = 'completed' THEN 'Terminée'
        WHEN status = 'cancelled' THEN 'Annulée'
        WHEN status = 'returned' THEN 'Restituée'
        ELSE status
    END as status_label
FROM repairs
GROUP BY status
ORDER BY 
    CASE status
        WHEN 'new' THEN 1
        WHEN 'in_progress' THEN 2
        WHEN 'waiting_parts' THEN 3
        WHEN 'waiting_delivery' THEN 4
        WHEN 'completed' THEN 5
        WHEN 'cancelled' THEN 6
        WHEN 'returned' THEN 7
        ELSE 8
    END;

-- 10. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE 'Script de correction des statuts terminé.';
    RAISE NOTICE 'Nouveau statut "returned" (Restitué) ajouté.';
    RAISE NOTICE 'Utilisez la fonction convert_cancelled_to_returned() pour convertir des réparations annulées en restituées si nécessaire.';
    RAISE NOTICE 'Utilisez la fonction get_repairs_by_status() pour lister les réparations par statut.';
END $$;
