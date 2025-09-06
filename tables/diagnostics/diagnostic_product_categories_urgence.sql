-- =====================================================
-- DIAGNOSTIC URGENCE - PRODUCT_CATEGORIES
-- =====================================================
-- Vérification rapide de l'état de l'isolation
-- =====================================================

-- 1. VÉRIFIER L'ÉTAT RLS
SELECT '=== ÉTAT RLS ===' as section;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'product_categories';

-- 2. VÉRIFIER LES COLONNES
SELECT '=== COLONNES ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'workshop_id' THEN '✅ Colonne isolation'
        ELSE 'ℹ️ Autre colonne'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'product_categories'
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES POLITIQUES RLS
SELECT '=== POLITIQUES RLS ===' as section;

SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual LIKE '%role%' THEN '✅ Contrôle par rôle'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'product_categories'
ORDER BY policyname;

-- 4. VÉRIFIER LES DONNÉES
SELECT '=== DONNÉES ===' as section;

SELECT 
    name,
    workshop_id,
    is_active,
    CASE 
        WHEN workshop_id IS NULL THEN '❌ Pas d''isolation'
        ELSE '✅ Isolé'
    END as isolation_status
FROM public.product_categories
ORDER BY sort_order;

-- 5. VÉRIFIER LE WORKSHOP_ID ACTUEL
SELECT '=== WORKSHOP_ID ACTUEL ===' as section;

SELECT 
    key,
    value,
    CASE 
        WHEN key = 'workshop_id' THEN '✅ Workshop ID'
        WHEN key = 'workshop_type' THEN '✅ Type Workshop'
        ELSE 'ℹ️ Autre paramètre'
    END as type_parametre
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type');

-- 6. COMPTER LES DONNÉES PAR WORKSHOP
SELECT '=== COMPTAGE PAR WORKSHOP ===' as section;

SELECT 
    COALESCE(workshop_id::text, 'NULL') as workshop_id,
    COUNT(*) as nombre_categories
FROM public.product_categories
GROUP BY workshop_id
ORDER BY workshop_id;

-- 7. TEST D'ISOLATION SIMPLE
SELECT '=== TEST ISOLATION ===' as section;

DO $$
DECLARE
    current_workshop_id UUID;
    total_categories INTEGER;
    visible_categories INTEGER;
BEGIN
    -- Récupérer le workshop_id actuel
    SELECT value::UUID INTO current_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Compter le total des catégories
    SELECT COUNT(*) INTO total_categories
    FROM public.product_categories;
    
    -- Compter les catégories visibles pour l'atelier actuel
    SELECT COUNT(*) INTO visible_categories
    FROM public.product_categories
    WHERE workshop_id = current_workshop_id;
    
    RAISE NOTICE 'Workshop ID actuel: %', current_workshop_id;
    RAISE NOTICE 'Total catégories: %', total_categories;
    RAISE NOTICE 'Catégories visibles: %', visible_categories;
    
    IF visible_categories = total_categories THEN
        RAISE NOTICE '❌ PROBLÈME: Toutes les catégories sont visibles - Pas d''isolation';
    ELSIF visible_categories = 0 THEN
        RAISE NOTICE '❌ PROBLÈME: Aucune catégorie visible - Isolation trop stricte';
    ELSE
        RAISE NOTICE '✅ Isolation partielle: % catégories visibles sur % total', visible_categories, total_categories;
    END IF;
END $$;





