-- Vérification de l'état actuel de system_settings
-- Date: 2024-01-24

-- 1. VÉRIFIER SI LA TABLE EXISTE
SELECT 
    '=== VÉRIFICATION TABLE SYSTEM_SETTINGS ===' as info;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'system_settings';

-- 2. VÉRIFIER LA STRUCTURE ACTUELLE
SELECT 
    '=== STRUCTURE ACTUELLE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES CONTRAINTES
SELECT 
    '=== CONTRAINTES ===' as info;

SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'system_settings';

-- 4. VÉRIFIER LES INDEX
SELECT 
    '=== INDEX ===' as info;

SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'system_settings';

-- 5. VÉRIFIER LES DONNÉES
SELECT 
    '=== DONNÉES ===' as info;

SELECT COUNT(*) as nombre_lignes FROM system_settings;

-- 6. TEST DE REQUÊTE SIMPLE
SELECT 
    '=== TEST REQUÊTE ===' as info;

-- Test avec les colonnes existantes
SELECT 
    column_name
FROM information_schema.columns 
WHERE table_name = 'system_settings'
AND column_name IN ('user_id', 'category', 'key', 'value', 'description');

-- 7. MESSAGE DE FIN
SELECT 
    '=== VÉRIFICATION TERMINÉE ===' as status,
    'Vérifiez les résultats ci-dessus pour diagnostiquer le problème' as message;
