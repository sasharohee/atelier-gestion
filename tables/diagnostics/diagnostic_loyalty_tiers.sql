-- Script de diagnostic pour les niveaux de fidélité
-- Ce script permet de vérifier l'état de la base de données

-- 1. Vérifier la structure de la table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'loyalty_tiers_advanced'
ORDER BY ordinal_position;

-- 2. Vérifier tous les niveaux de fidélité existants
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    description,
    color,
    is_active,
    created_at,
    updated_at
FROM loyalty_tiers_advanced
ORDER BY points_required;

-- 3. Compter les niveaux par nom (pour détecter les doublons)
SELECT 
    name,
    COUNT(*) as count,
    STRING_AGG(id::text, ', ') as ids
FROM loyalty_tiers_advanced
GROUP BY name
HAVING COUNT(*) > 1;

-- 4. Vérifier les contraintes et index
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'loyalty_tiers_advanced';

-- 5. Vérifier les permissions RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    hasrules
FROM pg_tables 
WHERE tablename = 'loyalty_tiers_advanced';

-- 6. Tester une mise à jour directe (remplacer l'ID par un ID réel)
-- UPDATE loyalty_tiers_advanced 
-- SET points_required = 255, updated_at = NOW()
-- WHERE name = 'Argent' AND id = 'REMPLACER_PAR_ID_REEL';

-- 7. Vérifier les logs récents (si disponibles)
SELECT 
    name,
    points_required,
    updated_at
FROM loyalty_tiers_advanced
WHERE name = 'Argent'
ORDER BY updated_at DESC;
