-- Script pour corriger le problème de contrainte unique
-- Exécutez ces requêtes dans l'ordre dans Supabase

-- 1. Vérifier les contraintes actuelles
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'loyalty_tiers_advanced'
AND tc.constraint_type = 'UNIQUE';

-- 2. Vérifier s'il y a des doublons qui causent le problème
SELECT 
    name,
    COUNT(*) as count,
    STRING_AGG(id::text, ', ') as ids
FROM loyalty_tiers_advanced
GROUP BY name
HAVING COUNT(*) > 1;

-- 3. Supprimer les doublons en gardant seulement le plus récent
-- (Décommentez et exécutez si des doublons sont trouvés)
/*
WITH duplicates AS (
    SELECT 
        id,
        name,
        ROW_NUMBER() OVER (PARTITION BY name ORDER BY updated_at DESC, created_at DESC) as rn
    FROM loyalty_tiers_advanced
)
DELETE FROM loyalty_tiers_advanced
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);
*/

-- 4. Vérifier la contrainte unique problématique
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'loyalty_tiers_advanced'::regclass
AND contype = 'u';

-- 5. Si nécessaire, supprimer la contrainte problématique
-- (Décommentez seulement si la contrainte cause des problèmes)
/*
ALTER TABLE loyalty_tiers_advanced 
DROP CONSTRAINT IF EXISTS loyalty_tiers_workshop_name_unique;
*/

-- 6. Vérifier l'état final
SELECT 
    name,
    points_required,
    discount_percentage,
    updated_at
FROM loyalty_tiers_advanced
ORDER BY points_required;
