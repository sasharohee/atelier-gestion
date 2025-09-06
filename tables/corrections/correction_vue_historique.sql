-- Correction de la vue repair_history_view
-- Ajoute la colonne client_email manquante

-- 1. Supprimer la vue existante
DROP VIEW IF EXISTS repair_history_view;

-- 2. Recréer la vue avec la colonne client_email
CREATE OR REPLACE VIEW repair_history_view AS
SELECT 
    r.id as repair_id,
    r.repair_number,
    r.status as repair_status,
    r.description as repair_description,
    r.total_price,
    r.is_paid,
    r.created_at,
    d.brand as device_brand,
    d.model as device_model,
    c.email as client_email
FROM repairs r
INNER JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id;

-- 3. Vérifier que la vue fonctionne
SELECT 'Test de la vue repair_history_view:' as test_name;
SELECT * FROM repair_history_view 
WHERE client_email = 'test@gmail.com'
ORDER BY created_at DESC;

-- 4. Vérifier que la vue repair_tracking_view fonctionne aussi
SELECT 'Test de la vue repair_tracking_view:' as test_name;
SELECT * FROM repair_tracking_view 
WHERE repair_number = 'REP-20250829-1296' 
AND client_email = 'test@gmail.com';
