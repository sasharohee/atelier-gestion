-- Solution avec données existantes
-- Utilise les réparations existantes au lieu d'en créer de nouvelles

-- 1. Nettoyer les fonctions et vues existantes
DROP FUNCTION IF EXISTS get_repair_tracking_info(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_client_repair_history(TEXT);
DROP VIEW IF EXISTS repair_tracking_view;
DROP VIEW IF EXISTS repair_history_view;

-- 2. Créer des vues simples pour l'accès aux données
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

-- 3. Vérifier les données existantes
SELECT 'Vérification des réparations existantes:' as test_name;
SELECT 
    r.id,
    r.repair_number,
    r.status,
    c.email,
    c.first_name,
    c.last_name
FROM repairs r
JOIN clients c ON r.client_id = c.id
ORDER BY r.created_at DESC
LIMIT 5;

-- 4. Vérifier les clients existants
SELECT 'Vérification des clients existants:' as test_name;
SELECT 
    id,
    first_name,
    last_name,
    email
FROM clients
ORDER BY created_at DESC
LIMIT 5;

-- 5. Tester les vues avec les données existantes
SELECT 'Test repair_tracking_view avec données existantes:' as test_name;
SELECT 
    repair_id,
    repair_number,
    repair_status,
    client_email,
    client_first_name,
    client_last_name
FROM repair_tracking_view 
ORDER BY created_at DESC
LIMIT 3;

-- 6. Tester repair_history_view avec données existantes
SELECT 'Test repair_history_view avec données existantes:' as test_name;
SELECT 
    repair_id,
    repair_number,
    repair_status,
    client_email,
    created_at
FROM repair_history_view 
ORDER BY created_at DESC
LIMIT 3;

-- 7. Trouver un client avec des réparations pour le test
SELECT 'Client avec réparations pour test:' as test_name;
SELECT 
    c.email,
    c.first_name,
    c.last_name,
    COUNT(r.id) as repair_count
FROM clients c
JOIN repairs r ON c.id = r.client_id
GROUP BY c.id, c.email, c.first_name, c.last_name
HAVING COUNT(r.id) > 0
ORDER BY repair_count DESC
LIMIT 3;

-- 8. Afficher un message de succès
SELECT '✅ Vues créées avec succès ! Utilisez les données existantes pour tester.' as status;
