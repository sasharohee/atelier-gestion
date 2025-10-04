-- Script pour identifier les colonnes requises de device_models
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Structure complète de la table
SELECT '=== STRUCTURE COMPLÈTE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Colonnes NOT NULL (obligatoires)
SELECT '=== COLONNES OBLIGATOIRES (NOT NULL) ===' as info;

SELECT 
    column_name,
    data_type,
    column_default,
    'OBLIGATOIRE' as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 3. Colonnes NULLABLE (optionnelles)
SELECT '=== COLONNES OPTIONNELLES (NULLABLE) ===' as info;

SELECT 
    column_name,
    data_type,
    column_default,
    'OPTIONNELLE' as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'YES'
ORDER BY column_name;

-- 4. Vérifier les valeurs par défaut
SELECT '=== VALEURS PAR DÉFAUT ===' as info;

SELECT 
    column_name,
    column_default,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND column_default IS NOT NULL
ORDER BY column_name;

-- 5. Tester l'insertion avec seulement les colonnes obligatoires
SELECT '=== TEST INSERTION COLONNES OBLIGATOIRES ===' as info;

-- Identifier les colonnes obligatoires
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 6. Résumé des colonnes requises
SELECT '=== RÉSUMÉ DES COLONNES REQUISES ===' as info;

SELECT 
    'Colonnes obligatoires:' as type,
    STRING_AGG(column_name, ', ') as columns
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'NO'
UNION ALL
SELECT 
    'Colonnes optionnelles:' as type,
    STRING_AGG(column_name, ', ') as columns
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'YES';

-- 7. Actions recommandées
SELECT '=== ACTIONS RECOMMANDÉES ===' as info;

SELECT 
    '1. Exécuter identify_brand_column_ultimate.sql' as action_1,
    '2. Exécuter fix_brand_column_ultimate.sql' as action_2,
    '3. Vérifier que toutes les colonnes obligatoires sont fournies' as action_3;

SELECT 'Identification des colonnes terminée' as final_status;