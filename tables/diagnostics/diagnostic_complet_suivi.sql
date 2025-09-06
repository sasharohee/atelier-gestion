-- Diagnostic complet du problème de suivi des réparations
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier toutes les réparations avec leurs numéros
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.created_at,
    c.email,
    c.first_name,
    c.last_name
FROM repairs r
JOIN clients c ON r.client_id = c.id
ORDER BY r.created_at DESC
LIMIT 10;

-- 2. Vérifier spécifiquement la réparation avec le numéro REP-20250829-1296
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.created_at,
    c.email,
    c.first_name,
    c.last_name
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE r.repair_number = 'REP-20250829-1296';

-- 3. Vérifier si le client test@gmail.com existe
SELECT 
    id,
    first_name,
    last_name,
    email,
    created_at
FROM clients 
WHERE email = 'test@gmail.com';

-- 4. Vérifier les réparations pour le client test@gmail.com
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.created_at,
    c.email
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE c.email = 'test@gmail.com'
ORDER BY r.created_at DESC;

-- 5. Tester la fonction get_repair_tracking_info directement
SELECT * FROM get_repair_tracking_info('REP-20250829-1296', 'test@gmail.com');

-- 6. Tester avec un email différent (si test@gmail.com n'existe pas)
-- Remplacez 'autre@email.com' par un email qui existe dans votre base
SELECT * FROM get_repair_tracking_info('REP-20250829-1296', 'autre@email.com');

-- 7. Vérifier les permissions des fonctions
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name IN ('get_repair_tracking_info', 'get_client_repair_history');

-- 8. Vérifier la structure de la table repairs
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repairs'
ORDER BY ordinal_position;

-- 9. Créer des données de test si nécessaire
-- Créer un client de test
INSERT INTO clients (first_name, last_name, email, phone) 
VALUES ('Test', 'User', 'test@gmail.com', '0123456789')
ON CONFLICT (email) DO NOTHING;

-- Créer un appareil de test
INSERT INTO devices (brand, model, serial_number, type) 
VALUES ('Test', 'Device', 'TEST123', 'smartphone')
ON CONFLICT (serial_number) DO NOTHING;

-- Créer une réparation de test avec le numéro spécifique
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

-- 10. Vérifier le résultat après création
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.created_at,
    c.email
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE r.repair_number = 'REP-20250829-1296';

-- 11. Tester à nouveau la fonction
SELECT * FROM get_repair_tracking_info('REP-20250829-1296', 'test@gmail.com');
