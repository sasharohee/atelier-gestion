-- Vérification simple des données pour le suivi des réparations

-- 1. Vérifier les clients existants
SELECT 'Clients existants:' as info;
SELECT 
    id,
    first_name,
    last_name,
    email
FROM clients
ORDER BY created_at DESC
LIMIT 5;

-- 2. Vérifier les réparations existantes
SELECT 'Réparations existantes:' as info;
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.description,
    c.email,
    c.first_name,
    c.last_name
FROM repairs r
JOIN clients c ON r.client_id = c.id
ORDER BY r.created_at DESC
LIMIT 5;

-- 3. Vérifier les réparations avec numéros
SELECT 'Réparations avec numéros:' as info;
SELECT 
    r.id,
    r.repair_number,
    r.status,
    c.email
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE r.repair_number IS NOT NULL
ORDER BY r.created_at DESC
LIMIT 5;

-- 4. Test avec un client spécifique (remplacez par un email existant)
SELECT 'Test avec client spécifique:' as info;
SELECT 
    c.email,
    c.first_name,
    c.last_name,
    COUNT(r.id) as repair_count
FROM clients c
LEFT JOIN repairs r ON c.id = r.client_id
GROUP BY c.id, c.email, c.first_name, c.last_name
HAVING COUNT(r.id) > 0
ORDER BY repair_count DESC
LIMIT 3;
