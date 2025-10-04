-- Script pour identifier le problème de la colonne "brand"
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
ORDER BY ordinal_position;c

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

-- 3. Vérifier toutes les colonnes NOT NULL
SELECT '=== COLONNES NOT NULL ===' as info;

SELECT 
    column_name,
    data_type,
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
    tc.constraint_name,
    tc.constraint_type,
    ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'device_models' 
AND tc.table_schema = 'public'
ORDER BY tc.constraint_name;

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
LIMIT 3;

-- 6. Vérifier les tables liées
SELECT '=== TABLES LIÉES ===' as info;

-- Marques disponibles
SELECT 
    'Marques disponibles:' as info,
    COUNT(*) as count
FROM public.device_brands
WHERE is_active = true;

SELECT 
    id,
    name,
    is_active
FROM public.device_brands 
WHERE is_active = true
LIMIT 3;

-- Catégories disponibles
SELECT 
    'Catégories disponibles:' as info,
    COUNT(*) as count
FROM public.device_categories
WHERE is_active = true;

SELECT 
    id,
    name,
    is_active
FROM public.device_categories 
WHERE is_active = true
LIMIT 3;

-- 7. Résumé des problèmes identifiés
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
        THEN '❌ PROBLÈME 1: Colonne "brand" NOT NULL mais non fournie'
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
        THEN '❌ PROBLÈME 2: Colonne "brand_id" NOT NULL mais non fournie'
        ELSE '✅ Pas de problème avec la colonne "brand_id"'
    END as problem_2,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.device_brands WHERE is_active = true LIMIT 1
        )
        THEN '❌ PROBLÈME 3: Aucune marque active disponible'
        ELSE '✅ Marques actives disponibles'
    END as problem_3,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.device_categories WHERE is_active = true LIMIT 1
        )
        THEN '❌ PROBLÈME 4: Aucune catégorie active disponible'
        ELSE '✅ Catégories actives disponibles'
    END as problem_4;

SELECT 'Diagnostic terminé' as final_status;
