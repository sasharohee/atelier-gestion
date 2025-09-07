-- =====================================================
-- DIAGNOSTIC COMPLET DE L'ISOLATION DES CATÉGORIES
-- =====================================================
-- Vérifie l'état de l'isolation pour toutes les tables de catégories
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'existence des tables de catégories
SELECT '=== TABLES DE CATÉGORIES EXISTANTES ===' as etape;

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('product_categories', 'device_categories', 'device_brands', 'device_models') 
        THEN '✅ Table de catégories'
        ELSE '❌ Autre table'
    END as type_table
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name LIKE '%categor%' OR table_name LIKE '%brand%' OR table_name LIKE '%model%'
ORDER BY table_name;

-- 2. Vérifier le statut RLS pour toutes les tables de catégories
SELECT '=== STATUT RLS DES TABLES ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND (tablename LIKE '%categor%' OR tablename LIKE '%brand%' OR tablename LIKE '%model%')
ORDER BY tablename;

-- 3. Vérifier les politiques RLS existantes
SELECT '=== POLITIQUES RLS EXISTANTES ===' as etape;

SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        WHEN qual LIKE '%auth.role() = ''authenticated''%' THEN '❌ Permissif (tous les utilisateurs)'
        WHEN qual = 'true' THEN '❌ Très permissif'
        ELSE '❓ Autre condition: ' || qual
    END as isolation_type
FROM pg_policies 
WHERE tablename IN ('product_categories', 'device_categories', 'device_brands', 'device_models')
ORDER BY tablename, policyname;

-- 4. Vérifier la présence de la colonne user_id
SELECT '=== COLONNE user_id ===' as etape;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'user_id' THEN '✅ Colonne user_id présente'
        ELSE '❌ Colonne user_id manquante'
    END as user_id_status
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('product_categories', 'device_categories', 'device_brands', 'device_models')
AND column_name = 'user_id'
ORDER BY table_name;

-- 5. Vérifier les triggers existants
SELECT '=== TRIGGERS EXISTANTS ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    CASE 
        WHEN trigger_name LIKE '%user_id%' THEN '✅ Trigger d''isolation'
        ELSE '❓ Autre trigger'
    END as trigger_type
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('product_categories', 'device_categories', 'device_brands', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 6. Compter les données par utilisateur (si user_id existe)
SELECT '=== DONNÉES PAR UTILISATEUR ===' as etape;

-- Pour product_categories
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_categories' AND column_name = 'user_id') THEN
        RAISE NOTICE '=== PRODUCT_CATEGORIES ===';
        FOR rec IN 
            SELECT user_id, COUNT(*) as count 
            FROM product_categories 
            GROUP BY user_id 
            ORDER BY count DESC
        LOOP
            RAISE NOTICE 'User ID: %, Catégories: %', rec.user_id, rec.count;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Colonne user_id manquante dans product_categories';
    END IF;
END $$;

-- Pour device_categories
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'device_categories' AND column_name = 'user_id') THEN
        RAISE NOTICE '=== DEVICE_CATEGORIES ===';
        FOR rec IN 
            SELECT user_id, COUNT(*) as count 
            FROM device_categories 
            GROUP BY user_id 
            ORDER BY count DESC
        LOOP
            RAISE NOTICE 'User ID: %, Catégories: %', rec.user_id, rec.count;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Colonne user_id manquante dans device_categories';
    END IF;
END $$;

-- 7. Test d'isolation avec l'utilisateur actuel
SELECT '=== TEST D''ISOLATION UTILISATEUR ACTUEL ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_count_product_categories INTEGER;
    v_count_device_categories INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Utilisateur connecté: %', v_user_id;
    
    -- Test product_categories
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_categories' AND column_name = 'user_id') THEN
        SELECT COUNT(*) INTO v_count_product_categories 
        FROM product_categories 
        WHERE user_id = v_user_id;
        RAISE NOTICE '✅ Product categories visibles: %', v_count_product_categories;
    ELSE
        RAISE NOTICE '❌ Colonne user_id manquante dans product_categories';
    END IF;
    
    -- Test device_categories
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'device_categories' AND column_name = 'user_id') THEN
        SELECT COUNT(*) INTO v_count_device_categories 
        FROM device_categories 
        WHERE user_id = v_user_id;
        RAISE NOTICE '✅ Device categories visibles: %', v_count_device_categories;
    ELSE
        RAISE NOTICE '❌ Colonne user_id manquante dans device_categories';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. Recommandations
SELECT '=== RECOMMANDATIONS ===' as etape;

SELECT '🔧 ACTIONS NÉCESSAIRES:' as action;
SELECT '1. Exécuter correction_isolation_product_categories_finale.sql' as step1;
SELECT '2. Exécuter correction_isolation_categories_finale.sql' as step2;
SELECT '3. Vérifier que les services frontend utilisent le bon filtrage' as step3;
SELECT '4. Tester l''isolation avec différents utilisateurs' as step4;
