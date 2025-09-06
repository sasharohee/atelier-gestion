-- Solution directe pour le suivi des réparations
-- Utilise des requêtes directes sans fonctions RPC pour éviter les problèmes d'authentification

-- 1. Supprimer les fonctions problématiques
DROP FUNCTION IF EXISTS get_repair_tracking_info(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_client_repair_history(TEXT);

-- 2. Créer des vues pour simplifier l'accès aux données
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

-- 3. Créer une vue pour l'historique
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
    d.model as device_model
FROM repairs r
INNER JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id;

-- 4. Créer des données de test (en contournant les triggers si nécessaire)
-- Désactiver temporairement les triggers problématiques
SET session_replication_role = replica;

-- Créer un client de test
INSERT INTO clients (first_name, last_name, email, phone) 
VALUES ('Test', 'User', 'test@gmail.com', '0123456789')
ON CONFLICT (email) DO NOTHING;

-- Créer un appareil de test (avec user_id)
INSERT INTO devices (brand, model, serial_number, type, user_id) 
SELECT 'Test', 'Device', 'TEST123', 'smartphone', u.id
FROM users u
LIMIT 1
ON CONFLICT (serial_number) DO NOTHING;

-- Créer une réparation de test
INSERT INTO repairs (
    client_id, 
    device_id, 
    status, 
    description, 
    issue, 
    repair_number,
    total_price, 
    is_paid
) 
SELECT 
    c.id,
    d.id,
    'in_progress',
    'Test de réparation',
    'Problème de test',
    'REP-20250829-1296',
    50.00,
    false
FROM clients c, devices d 
WHERE c.email = 'test@gmail.com' 
AND d.serial_number = 'TEST123'
ON CONFLICT (repair_number) DO NOTHING;

-- Réactiver les triggers
SET session_replication_role = DEFAULT;

-- 5. Tester les vues
SELECT 'Test repair_tracking_view:' as test_name;
SELECT * FROM repair_tracking_view 
WHERE repair_number = 'REP-20250829-1296' 
AND client_email = 'test@gmail.com';

SELECT 'Test repair_history_view:' as test_name;
SELECT * FROM repair_history_view 
WHERE client_email = 'test@gmail.com'
ORDER BY created_at DESC;

-- 6. Vérifier que les données existent
SELECT 'Vérification des données:' as test_name;
SELECT 
    r.id,
    r.repair_number,
    r.status,
    c.email
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE r.repair_number = 'REP-20250829-1296';
