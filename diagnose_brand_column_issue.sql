-- Script pour diagnostiquer le problème de la colonne "brand"
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure complète de device_models
SELECT '=== STRUCTURE COMPLÈTE DE DEVICE_MODELS ===' as info;

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

-- 2. Vérifier spécifiquement la colonne "brand"
SELECT '=== VÉRIFICATION COLONNE BRAND ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND column_name = 'brand';

-- 3. Vérifier les contraintes NOT NULL
SELECT '=== CONTRAINTES NOT NULL ===' as info;

SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 4. Vérifier les contraintes de la table
SELECT '=== CONTRAINTES DE LA TABLE ===' as info;

SELECT 
    constraint_name,
    constraint_type,
    column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'device_models' 
AND tc.table_schema = 'public'
ORDER BY constraint_name;

-- 5. Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active,
    created_at
FROM public.device_models 
ORDER BY created_at DESC
LIMIT 5;

-- 6. Vérifier les tables liées
SELECT '=== TABLES LIÉES ===' as info;

SELECT 
    'device_brands' as table_name,
    COUNT(*) as row_count
FROM public.device_brands
UNION ALL
SELECT 
    'device_categories' as table_name,
    COUNT(*) as row_count
FROM public.device_categories;

-- 7. Tester l'insertion avec toutes les colonnes requises
SELECT '=== TEST INSERTION AVEC TOUTES LES COLONNES ===' as info;

-- D'abord, vérifier quelles colonnes sont NOT NULL
SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 8. Résumé des problèmes identifiés
SELECT '=== RÉSUMÉ DES PROBLÈMES ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'brand'
            AND is_nullable = 'NO'
        )
        THEN '❌ PROBLÈME: Colonne "brand" NOT NULL mais non fournie'
        ELSE '✅ Pas de problème avec la colonne "brand"'
    END as problem_1,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'brand_id'
            AND is_nullable = 'NO'
        )
        THEN '❌ PROBLÈME: Colonne "brand_id" NOT NULL mais non fournie'
        ELSE '✅ Pas de problème avec la colonne "brand_id"'
    END as problem_2;

SELECT 'Diagnostic terminé' as final_status;


