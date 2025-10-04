-- Script pour vérifier l'état actuel de device_models
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier toutes les colonnes
SELECT '=== TOUTES LES COLONNES DE DEVICE_MODELS ===' as info;

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

-- 2. Vérifier spécifiquement la colonne description
SELECT '=== VÉRIFICATION COLONNE DESCRIPTION ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '✅ Colonne description EXISTE'
        ELSE '❌ Colonne description MANQUANTE'
    END as description_status;

-- 3. Vérifier les colonnes NOT NULL
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

-- 4. Vérifier les données de référence
SELECT '=== DONNÉES DE RÉFÉRENCE ===' as info;

-- Marques
SELECT 
    'Marques disponibles:' as info,
    COUNT(*) as count
FROM public.device_brands
WHERE is_active = true;

-- Catégories
SELECT 
    'Catégories disponibles:' as info,
    COUNT(*) as count
FROM public.device_categories
WHERE is_active = true;

-- 5. Résumé des problèmes
SELECT '=== RÉSUMÉ DES PROBLÈMES ===' as info;

SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '❌ PROBLÈME 1: Colonne description manquante'
        ELSE '✅ Colonne description présente'
    END as problem_1,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.device_brands WHERE is_active = true LIMIT 1
        )
        THEN '❌ PROBLÈME 2: Aucune marque active'
        ELSE '✅ Marques actives disponibles'
    END as problem_2,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.device_categories WHERE is_active = true LIMIT 1
        )
        THEN '❌ PROBLÈME 3: Aucune catégorie active'
        ELSE '✅ Catégories actives disponibles'
    END as problem_3;

SELECT 'Vérification terminée' as final_status;


