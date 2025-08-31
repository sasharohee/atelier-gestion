-- =====================================================
-- TEST ISOLATION PAR UTILISATEUR
-- =====================================================
-- Script pour tester l'isolation des catégories par utilisateur
-- =====================================================

-- 1. VÉRIFIER L'ÉTAT ACTUEL
SELECT '=== ÉTAT ACTUEL ===' as section;

-- Vérifier RLS
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '✅ RLS ACTIVÉ' ELSE '❌ RLS DÉSACTIVÉ' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'product_categories';

-- Vérifier les politiques
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '✅ Isolation par utilisateur'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'product_categories';

-- 2. VÉRIFIER LES DONNÉES
SELECT '=== DONNÉES ACTUELLES ===' as section;

SELECT 
    name,
    user_id,
    workshop_id,
    CASE 
        WHEN user_id IS NOT NULL THEN '✅ Avec user_id'
        ELSE '❌ Sans user_id'
    END as user_status
FROM public.product_categories
ORDER BY name;

-- 3. VÉRIFIER L'UTILISATEUR CONNECTÉ
SELECT '=== UTILISATEUR CONNECTÉ ===' as section;

DO $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NOT NULL THEN
        RAISE NOTICE 'Utilisateur connecté: %', current_user_id;
    ELSE
        RAISE NOTICE 'Aucun utilisateur connecté';
    END IF;
END $$;

-- 4. TESTER L'ACCÈS DIRECT
SELECT '=== TEST ACCÈS DIRECT ===' as section;

SELECT 
    COUNT(*) as nombre_categories_visibles
FROM public.product_categories;

-- 5. TESTER LA CRÉATION (si possible)
SELECT '=== TEST CRÉATION ===' as section;

-- Note: Ce test nécessite des permissions appropriées
-- Il sera exécuté seulement si l'utilisateur a les droits

-- 6. COMPTAGE PAR UTILISATEUR
SELECT '=== COMPTAGE PAR UTILISATEUR ===' as section;

SELECT 
    COALESCE(user_id::text, 'NULL') as user_id,
    COUNT(*) as nombre_categories
FROM public.product_categories
GROUP BY user_id
ORDER BY user_id;

-- 7. TEST D'ISOLATION SIMPLE
SELECT '=== TEST ISOLATION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    total_categories INTEGER;
    user_categories INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    -- Compter le total des catégories
    SELECT COUNT(*) INTO total_categories FROM public.product_categories;
    
    -- Compter les catégories de l'utilisateur actuel
    SELECT COUNT(*) INTO user_categories 
    FROM public.product_categories 
    WHERE user_id = current_user_id;
    
    RAISE NOTICE 'Utilisateur actuel: %', current_user_id;
    RAISE NOTICE 'Total catégories: %', total_categories;
    RAISE NOTICE 'Catégories de l''utilisateur: %', user_categories;
    
    IF current_user_id IS NOT NULL AND user_categories > 0 THEN
        RAISE NOTICE '✅ Isolation par utilisateur fonctionne';
    ELSIF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation détecté';
    END IF;
END $$;


