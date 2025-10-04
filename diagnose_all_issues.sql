-- Script de diagnostic complet pour identifier tous les problèmes
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure de device_models
SELECT '=== DIAGNOSTIC DEVICE_MODELS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Vérifier spécifiquement la colonne description
SELECT '=== VÉRIFICATION COLONNE DESCRIPTION ===' as section;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '✅ Colonne description EXISTE'
        ELSE '❌ Colonne description MANQUANTE - PROBLÈME CRITIQUE'
    END as description_status;

-- 3. Vérifier les triggers problématiques
SELECT '=== VÉRIFICATION TRIGGERS ===' as section;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 4. Vérifier les fonctions liées
SELECT '=== VÉRIFICATION FONCTIONS ===' as section;

SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%device_model%'
ORDER BY routine_name;

-- 5. Tester une requête SELECT simple
SELECT '=== TEST REQUÊTE SELECT ===' as section;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
LIMIT 1;

-- 6. Vérifier les tables liées (brands et categories)
SELECT '=== VÉRIFICATION TABLES LIÉES ===' as section;

SELECT 
    'device_brands' as table_name,
    COUNT(*) as row_count
FROM public.device_brands
UNION ALL
SELECT 
    'device_categories' as table_name,
    COUNT(*) as row_count
FROM public.device_categories;

-- 7. Résumé des problèmes identifiés
SELECT '=== RÉSUMÉ DES PROBLÈMES ===' as section;

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
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE event_object_table = 'device_models'
            AND trigger_schema = 'public'
            AND trigger_name LIKE '%ultime%'
        )
        THEN '❌ PROBLÈME 2: Trigger d''authentification strict présent'
        ELSE '✅ Pas de trigger problématique'
    END as problem_2,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.device_brands LIMIT 1
        )
        THEN '❌ PROBLÈME 3: Aucune marque disponible'
        ELSE '✅ Marques disponibles'
    END as problem_3,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.device_categories LIMIT 1
        )
        THEN '❌ PROBLÈME 4: Aucune catégorie disponible'
        ELSE '✅ Catégories disponibles'
    END as problem_4;

-- 8. Actions recommandées
SELECT '=== ACTIONS RECOMMANDÉES ===' as section;

SELECT 
    '1. Exécuter force_add_description.sql' as action_1,
    '2. Exécuter remove_problematic_trigger.sql' as action_2,
    '3. Tester avec test_device_model_complete.sql' as action_3;

SELECT 'Diagnostic terminé' as final_status;


