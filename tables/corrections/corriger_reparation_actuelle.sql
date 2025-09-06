-- Script pour corriger la réparation actuelle sans numéro
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Voir la réparation la plus récente sans numéro
SELECT 
    id,
    created_at,
    status,
    description,
    client_id,
    device_id
FROM repairs 
WHERE repair_number IS NULL
ORDER BY created_at DESC
LIMIT 1;

-- 2. Générer un numéro pour cette réparation
SELECT generate_repair_number() as nouveau_numero;

-- 3. Mettre à jour la réparation avec le numéro généré
-- Remplacez 'REP-20241201-1234' par le numéro généré à l'étape précédente
UPDATE repairs 
SET repair_number = 'REP-20241201-1234'  -- Remplacez par le vrai numéro généré
WHERE repair_number IS NULL
AND id = (
    SELECT id 
    FROM repairs 
    WHERE repair_number IS NULL 
    ORDER BY created_at DESC 
    LIMIT 1
);

-- 4. Vérifier que la mise à jour a fonctionné
SELECT 
    id,
    repair_number,
    status,
    description,
    created_at
FROM repairs 
ORDER BY created_at DESC
LIMIT 3;

-- 5. Afficher les informations complètes de la réparation corrigée
SELECT 
    r.id,
    r.repair_number,
    r.status,
    r.description,
    r.issue,
    r.total_price,
    r.created_at,
    c.first_name,
    c.last_name,
    c.email,
    d.brand,
    d.model
FROM repairs r
JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
WHERE r.repair_number IS NOT NULL
ORDER BY r.created_at DESC
LIMIT 1;
