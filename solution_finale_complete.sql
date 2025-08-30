-- Solution finale complète pour le suivi des réparations
-- Corrige tous les problèmes en une fois

-- 1. Nettoyer les fonctions et vues existantes
DROP FUNCTION IF EXISTS get_repair_tracking_info(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_client_repair_history(TEXT);
DROP VIEW IF EXISTS repair_tracking_view;
DROP VIEW IF EXISTS repair_history_view;

-- 2. Créer la vue pour le suivi des réparations
CREATE OR REPLACE VIEW repair_tracking_view AS
SELECT 
    r.id as repair_id,
    r.repair_number,
    r.status as repair_status,
    r.description as repair_description,
    r.issue as repair_issue,
    r.estimated_start_date,
    r.estimated_end_date,
    r.start_date,
    r.end_date,
    r.due_date,
    r.is_urgent,
    r.notes,
    r.total_price,
    r.is_paid,
    r.created_at,
    r.updated_at,
    c.first_name as client_first_name,
    c.last_name as client_last_name,
    c.email as client_email,
    c.phone as client_phone,
    d.brand as device_brand,
    d.model as device_model,
    d.serial_number as device_serial_number,
    d.type as device_type,
    u.first_name as technician_first_name,
    u.last_name as technician_last_name
FROM repairs r
INNER JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
LEFT JOIN users u ON r.assigned_technician_id = u.id;

-- 3. Créer la vue pour l'historique des réparations
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

-- 4. Créer un client de test
INSERT INTO clients (first_name, last_name, email, phone) 
VALUES ('Test', 'User', 'test@gmail.com', '0123456789')
ON CONFLICT (email) DO NOTHING;

-- 5. Créer une réparation de test SANS appareil (pour éviter les contraintes)
INSERT INTO repairs (
    client_id, 
    device_id,  -- NULL pour éviter les contraintes
    status, 
    description, 
    issue, 
    repair_number,
    total_price, 
    is_paid
) 
SELECT 
    c.id,
    NULL,  -- Pas d'appareil
    'in_progress',
    'Test de réparation sans appareil',
    'Problème de test simple',
    'REP-20250829-1296',
    50.00,
    false
FROM clients c
WHERE c.email = 'test@gmail.com'
ON CONFLICT (repair_number) DO NOTHING;

-- 6. Vérifier que les vues sont créées
SELECT 'Vérification des vues:' as test_name;
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_name IN ('repair_tracking_view', 'repair_history_view')
AND table_schema = 'public';

-- 7. Tester la vue repair_tracking_view
SELECT 'Test repair_tracking_view:' as test_name;
SELECT 
    repair_id,
    repair_number,
    repair_status,
    client_email,
    client_first_name,
    client_last_name
FROM repair_tracking_view 
WHERE repair_number = 'REP-20250829-1296' 
AND client_email = 'test@gmail.com';

-- 8. Tester la vue repair_history_view
SELECT 'Test repair_history_view:' as test_name;
SELECT 
    repair_id,
    repair_number,
    repair_status,
    client_email,
    created_at
FROM repair_history_view 
WHERE client_email = 'test@gmail.com'
ORDER BY created_at DESC;

-- 9. Vérifier que la réparation existe dans la table de base
SELECT 'Vérification de la réparation:' as test_name;
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.description,
    c.email,
    r.device_id
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE r.repair_number = 'REP-20250829-1296';

-- 10. Afficher un message de succès
SELECT '✅ Configuration terminée avec succès !' as status;
