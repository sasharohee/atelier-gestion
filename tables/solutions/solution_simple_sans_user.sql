-- Solution simple pour le suivi des réparations
-- Utilise des requêtes directes sans contraintes d'utilisateur

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
    d.model as device_model,
    c.email as client_email
FROM repairs r
INNER JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id;

-- 4. Vérifier s'il y a des utilisateurs
SELECT 'Vérification des utilisateurs:' as test_name;
SELECT COUNT(*) as user_count FROM users;

-- 5. Créer des données de test de manière sécurisée
-- Créer un client de test
INSERT INTO clients (first_name, last_name, email, phone) 
VALUES ('Test', 'User', 'test@gmail.com', '0123456789')
ON CONFLICT (email) DO NOTHING;

-- Créer un appareil de test seulement s'il y a des utilisateurs
DO $$
DECLARE
    user_exists BOOLEAN;
    user_id UUID;
BEGIN
    -- Vérifier s'il y a des utilisateurs
    SELECT EXISTS(SELECT 1 FROM users LIMIT 1) INTO user_exists;
    
    IF user_exists THEN
        -- Prendre le premier utilisateur
        SELECT id INTO user_id FROM users LIMIT 1;
        
        -- Créer l'appareil avec l'utilisateur
        INSERT INTO devices (brand, model, serial_number, type, user_id) 
        VALUES ('Test', 'Device', 'TEST123', 'smartphone', user_id)
        ON CONFLICT (serial_number) DO NOTHING;
        
        RAISE NOTICE 'Appareil créé avec user_id: %', user_id;
    ELSE
        RAISE NOTICE 'Aucun utilisateur trouvé, impossible de créer l''appareil';
    END IF;
END $$;

-- 6. Créer une réparation de test (sans appareil si nécessaire)
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
FROM clients c
LEFT JOIN devices d ON d.serial_number = 'TEST123'
WHERE c.email = 'test@gmail.com'
ON CONFLICT (repair_number) DO NOTHING;

-- 7. Tester les vues
SELECT 'Test repair_tracking_view:' as test_name;
SELECT * FROM repair_tracking_view 
WHERE repair_number = 'REP-20250829-1296' 
AND client_email = 'test@gmail.com';

SELECT 'Test repair_history_view:' as test_name;
SELECT * FROM repair_history_view 
WHERE client_email = 'test@gmail.com'
ORDER BY created_at DESC;

-- 8. Vérifier que les données existent
SELECT 'Vérification des données:' as test_name;
SELECT 
    r.id,
    r.repair_number,
    r.status,
    c.email,
    d.brand as device_brand
FROM repairs r
JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
WHERE r.repair_number = 'REP-20250829-1296';
