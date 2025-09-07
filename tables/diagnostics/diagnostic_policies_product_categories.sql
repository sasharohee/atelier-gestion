-- =====================================================
-- DIAGNOSTIC POLITIQUES PRODUCT_CATEGORIES
-- =====================================================
-- Script pour diagnostiquer l'état des politiques RLS
-- sur la table product_categories
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état RLS de la table
SELECT '=== ÉTAT RLS DE LA TABLE ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status,
    CASE 
        WHEN rowsecurity THEN 'La table utilise Row Level Security'
        ELSE 'La table n''utilise PAS Row Level Security'
    END as description
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'product_categories';

-- 2. Lister toutes les politiques existantes
SELECT '=== POLITIQUES EXISTANTES ===' as etape;

SELECT 
    policyname as nom_politique,
    cmd as commande,
    qual as condition,
    with_check as verification,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Utilise auth.uid() mais pas user_id'
        WHEN qual IS NULL THEN '❌ Aucune condition'
        ELSE '❌ Autre condition'
    END as type_isolation
FROM pg_policies 
WHERE tablename = 'product_categories'
ORDER BY policyname;

-- 3. Vérifier la structure de la table
SELECT '=== STRUCTURE DE LA TABLE ===' as etape;

SELECT 
    column_name as colonne,
    data_type as type,
    is_nullable as nullable,
    column_default as valeur_par_defaut
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'product_categories'
ORDER BY ordinal_position;

-- 4. Vérifier les contraintes
SELECT '=== CONTRAINTES ===' as etape;

SELECT 
    constraint_name as nom_contrainte,
    constraint_type as type_contrainte,
    table_name as table
FROM information_schema.table_constraints 
WHERE table_schema = 'public'
AND table_name = 'product_categories'
ORDER BY constraint_name;

-- 5. Vérifier les triggers
SELECT '=== TRIGGERS ===' as etape;

SELECT 
    trigger_name as nom_trigger,
    event_manipulation as evenement,
    action_timing as moment,
    action_statement as action
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'product_categories'
ORDER BY trigger_name;

-- 6. Test de l'isolation actuelle
SELECT '=== TEST D''ISOLATION ACTUELLE ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_count_all UUID;
    v_count_user UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Compter toutes les catégories (devrait être limité par RLS)
    SELECT COUNT(*) INTO v_count_all FROM public.product_categories;
    
    -- Compter les catégories de l'utilisateur (devrait être identique si RLS fonctionne)
    SELECT COUNT(*) INTO v_count_user FROM public.product_categories WHERE user_id = v_user_id;
    
    RAISE NOTICE '📊 Résultats du test:';
    RAISE NOTICE '  - Total catégories visibles: %', v_count_all;
    RAISE NOTICE '  - Catégories de l''utilisateur: %', v_count_user;
    
    IF v_count_all = v_count_user THEN
        RAISE NOTICE '✅ Isolation fonctionne correctement';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation détecté';
        RAISE NOTICE '💡 Les politiques RLS ne filtrent pas correctement';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 7. Recommandations
SELECT '=== RECOMMANDATIONS ===' as etape;

DO $$
DECLARE
    v_rls_enabled BOOLEAN;
    v_policy_count INTEGER;
    v_user_id_column_exists BOOLEAN;
BEGIN
    -- Vérifier si RLS est activé
    SELECT rowsecurity INTO v_rls_enabled
    FROM pg_tables 
    WHERE schemaname = 'public' AND tablename = 'product_categories';
    
    -- Compter les politiques
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies 
    WHERE tablename = 'product_categories';
    
    -- Vérifier si la colonne user_id existe
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_categories' 
        AND column_name = 'user_id'
    ) INTO v_user_id_column_exists;
    
    RAISE NOTICE '📋 État actuel:';
    RAISE NOTICE '  - RLS activé: %', CASE WHEN v_rls_enabled THEN 'Oui' ELSE 'Non' END;
    RAISE NOTICE '  - Nombre de politiques: %', v_policy_count;
    RAISE NOTICE '  - Colonne user_id existe: %', CASE WHEN v_user_id_column_exists THEN 'Oui' ELSE 'Non' END;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions recommandées:';
    
    IF NOT v_rls_enabled THEN
        RAISE NOTICE '  1. Activer RLS: ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;';
    END IF;
    
    IF v_policy_count = 0 THEN
        RAISE NOTICE '  2. Créer des politiques RLS basées sur user_id';
    ELSIF v_policy_count > 0 THEN
        RAISE NOTICE '  2. Vérifier que les politiques utilisent user_id = auth.uid()';
    END IF;
    
    IF NOT v_user_id_column_exists THEN
        RAISE NOTICE '  3. Ajouter la colonne user_id: ALTER TABLE public.product_categories ADD COLUMN user_id UUID;';
    END IF;
    
    IF v_rls_enabled AND v_policy_count > 0 AND v_user_id_column_exists THEN
        RAISE NOTICE '  ✅ Configuration semble correcte - vérifier les données';
    END IF;
    
END $$;
