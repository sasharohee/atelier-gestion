-- ============================================================================
-- SCRIPT DE VÉRIFICATION DES CORRECTIONS DE MARQUES
-- ============================================================================
-- Ce script vérifie que toutes les corrections ont été appliquées correctement
-- ============================================================================

-- 1. VÉRIFIER L'EXISTENCE DE LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA VUE BRAND_WITH_CATEGORIES ===' as section;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.views 
            WHERE table_name = 'brand_with_categories' 
            AND table_schema = 'public'
        ) 
        THEN '✅ Vue brand_with_categories créée avec succès'
        ELSE '❌ Vue brand_with_categories manquante'
    END as vue_status;

-- Tester la vue avec un utilisateur connecté (si possible)
SELECT '=== TEST DE LA VUE ===' as section;
SELECT COUNT(*) as nombre_de_marques FROM public.brand_with_categories;

-- 2. VÉRIFIER L'EXISTENCE DES FONCTIONS RPC
-- ============================================================================
SELECT '=== VÉRIFICATION DES FONCTIONS RPC ===' as section;

-- Vérifier upsert_brand
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'upsert_brand' 
            AND routine_schema = 'public'
        ) 
        THEN '✅ Fonction upsert_brand créée avec succès'
        ELSE '❌ Fonction upsert_brand manquante'
    END as upsert_brand_status;

-- Vérifier update_brand_categories
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_brand_categories' 
            AND routine_schema = 'public'
        ) 
        THEN '✅ Fonction update_brand_categories créée avec succès'
        ELSE '❌ Fonction update_brand_categories manquante'
    END as update_brand_categories_status;

-- 3. VÉRIFIER LES TABLES DE BASE
-- ============================================================================
SELECT '=== VÉRIFICATION DES TABLES DE BASE ===' as section;

-- Vérifier device_brands
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'device_brands' 
            AND table_schema = 'public'
        ) 
        THEN '✅ Table device_brands existe'
        ELSE '❌ Table device_brands manquante'
    END as device_brands_status;

-- Vérifier brand_categories
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'brand_categories' 
            AND table_schema = 'public'
        ) 
        THEN '✅ Table brand_categories existe'
        ELSE '❌ Table brand_categories manquante'
    END as brand_categories_status;

-- Vérifier device_categories
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'device_categories' 
            AND table_schema = 'public'
        ) 
        THEN '✅ Table device_categories existe'
        ELSE '❌ Table device_categories manquante'
    END as device_categories_status;

-- 4. VÉRIFIER LES POLITIQUES RLS
-- ============================================================================
SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as section;

-- Vérifier RLS sur device_brands
SELECT 
    CASE 
        WHEN relrowsecurity = true 
        THEN '✅ RLS activé sur device_brands'
        ELSE '❌ RLS non activé sur device_brands'
    END as device_brands_rls
FROM pg_class 
WHERE relname = 'device_brands' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Vérifier RLS sur brand_categories
SELECT 
    CASE 
        WHEN relrowsecurity = true 
        THEN '✅ RLS activé sur brand_categories'
        ELSE '❌ RLS non activé sur brand_categories'
    END as brand_categories_rls
FROM pg_class 
WHERE relname = 'brand_categories' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 5. VÉRIFIER LES PERMISSIONS
-- ============================================================================
SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as section;

-- Vérifier les permissions sur la vue
SELECT 
    table_name,
    privilege_type,
    grantee
FROM information_schema.table_privileges 
WHERE table_name = 'brand_with_categories' 
AND table_schema = 'public'
AND grantee = 'authenticated';

-- 6. TEST DE FONCTIONNALITÉ (si utilisateur connecté)
-- ============================================================================
SELECT '=== TEST DE FONCTIONNALITÉ ===' as section;

-- Compter les marques existantes
SELECT COUNT(*) as total_brands FROM public.device_brands;

-- Compter les catégories existantes
SELECT COUNT(*) as total_categories FROM public.device_categories;

-- Compter les associations marques-catégories
SELECT COUNT(*) as total_brand_categories FROM public.brand_categories;

-- 7. RÉSUMÉ FINAL
-- ============================================================================
SELECT '=== RÉSUMÉ FINAL ===' as section;

SELECT 
    'Vue brand_with_categories' as element,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'brand_with_categories' AND table_schema = 'public') 
         THEN 'CRÉÉE' ELSE 'MANQUANTE' END as statut
UNION ALL
SELECT 
    'Fonction upsert_brand' as element,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'upsert_brand' AND routine_schema = 'public') 
         THEN 'CRÉÉE' ELSE 'MANQUANTE' END as statut
UNION ALL
SELECT 
    'Fonction update_brand_categories' as element,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'update_brand_categories' AND routine_schema = 'public') 
         THEN 'CRÉÉE' ELSE 'MANQUANTE' END as statut;

SELECT '=== VÉRIFICATION TERMINÉE ===' as section;

