-- =====================================================
-- DIAGNOSTIC RLS PRODUCTION - VERCEL
-- =====================================================
-- Script pour diagnostiquer l'état de l'isolation en production
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as etape;
SELECT 
    auth.uid() as user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN '✅ Utilisateur connecté'
        ELSE '❌ Aucun utilisateur connecté'
    END as status;

-- 2. Vérifier l'état RLS de toutes les tables critiques
SELECT '=== ÉTAT RLS DES TABLES ===' as etape;

SELECT 
    tablename as table,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status,
    CASE 
        WHEN rowsecurity THEN 'Sécurisé'
        ELSE '🚨 VULNÉRABLE - Données visibles par tous'
    END as securite
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'clients', 'repairs', 'product_categories', 'device_categories', 
    'device_brands', 'device_models', 'parts', 'products', 'services'
)
ORDER BY 
    CASE WHEN rowsecurity THEN 1 ELSE 0 END,
    tablename;

-- 3. Vérifier les politiques RLS
SELECT '=== POLITIQUES RLS ===' as etape;

SELECT 
    tablename as table,
    policyname as politique,
    cmd as commande,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Utilise auth.uid() mais pas user_id'
        WHEN qual IS NULL THEN '❌ Aucune condition'
        ELSE '❌ Autre condition'
    END as type_isolation,
    qual as condition
FROM pg_policies 
WHERE tablename IN (
    'clients', 'repairs', 'product_categories', 'device_categories', 
    'device_brands', 'device_models', 'parts', 'products', 'services'
)
ORDER BY tablename, policyname;

-- 4. Compter les données par utilisateur
SELECT '=== DONNÉES PAR UTILISATEUR ===' as etape;

-- Clients par utilisateur
SELECT 
    'clients' as table,
    user_id,
    COUNT(*) as nombre_enregistrements
FROM clients 
GROUP BY user_id
ORDER BY nombre_enregistrements DESC;

-- Réparations par utilisateur
SELECT 
    'repairs' as table,
    user_id,
    COUNT(*) as nombre_enregistrements
FROM repairs 
GROUP BY user_id
ORDER BY nombre_enregistrements DESC;

-- Catégories de produits par utilisateur
SELECT 
    'product_categories' as table,
    user_id,
    COUNT(*) as nombre_enregistrements
FROM product_categories 
GROUP BY user_id
ORDER BY nombre_enregistrements DESC;

-- 5. Vérifier les données sans user_id
SELECT '=== DONNÉES SANS user_id ===' as etape;

SELECT 
    'clients' as table,
    COUNT(*) as sans_user_id
FROM clients 
WHERE user_id IS NULL

UNION ALL

SELECT 
    'repairs' as table,
    COUNT(*) as sans_user_id
FROM repairs 
WHERE user_id IS NULL

UNION ALL

SELECT 
    'product_categories' as table,
    COUNT(*) as sans_user_id
FROM product_categories 
WHERE user_id IS NULL

UNION ALL

SELECT 
    'device_categories' as table,
    COUNT(*) as sans_user_id
FROM device_categories 
WHERE user_id IS NULL;

-- 6. Test d'isolation (simulation)
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_total_clients INTEGER;
    v_user_clients INTEGER;
    v_total_repairs INTEGER;
    v_user_repairs INTEGER;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Clients
    SELECT COUNT(*) INTO v_total_clients FROM clients;
    SELECT COUNT(*) INTO v_user_clients FROM clients WHERE user_id = v_user_id;
    
    RAISE NOTICE '📊 Clients:';
    RAISE NOTICE '  - Total: %', v_total_clients;
    RAISE NOTICE '  - Utilisateur: %', v_user_clients;
    
    IF v_total_clients = v_user_clients THEN
        RAISE NOTICE '  ✅ Isolation clients OK';
    ELSE
        RAISE NOTICE '  ❌ PROBLÈME: Isolation clients défaillante';
    END IF;
    
    -- Test 2: Réparations
    SELECT COUNT(*) INTO v_total_repairs FROM repairs;
    SELECT COUNT(*) INTO v_user_repairs FROM repairs WHERE user_id = v_user_id;
    
    RAISE NOTICE '📊 Réparations:';
    RAISE NOTICE '  - Total: %', v_total_repairs;
    RAISE NOTICE '  - Utilisateur: %', v_user_repairs;
    
    IF v_total_repairs = v_user_repairs THEN
        RAISE NOTICE '  ✅ Isolation réparations OK';
    ELSE
        RAISE NOTICE '  ❌ PROBLÈME: Isolation réparations défaillante';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 7. Vérifier les triggers
SELECT '=== TRIGGERS ===' as etape;

SELECT 
    event_object_table as table,
    trigger_name as trigger,
    action_statement as action
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN (
    'clients', 'repairs', 'product_categories', 'device_categories', 
    'device_brands', 'device_models', 'parts', 'products', 'services'
)
ORDER BY event_object_table, trigger_name;

-- 8. Recommandations
SELECT '=== RECOMMANDATIONS ===' as etape;

DO $$
DECLARE
    v_tables_sans_rls INTEGER;
    v_policies_manquantes INTEGER;
    v_donnees_sans_user_id INTEGER;
BEGIN
    -- Compter les tables sans RLS
    SELECT COUNT(*) INTO v_tables_sans_rls
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename IN (
        'clients', 'repairs', 'product_categories', 'device_categories', 
        'device_brands', 'device_models', 'parts', 'products', 'services'
    )
    AND NOT rowsecurity;
    
    -- Compter les tables sans politiques
    SELECT COUNT(DISTINCT tablename) INTO v_policies_manquantes
    FROM pg_tables t
    WHERE t.schemaname = 'public'
    AND t.tablename IN (
        'clients', 'repairs', 'product_categories', 'device_categories', 
        'device_brands', 'device_models', 'parts', 'products', 'services'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_policies p 
        WHERE p.tablename = t.tablename
    );
    
    -- Compter les données sans user_id
    SELECT 
        (SELECT COUNT(*) FROM clients WHERE user_id IS NULL) +
        (SELECT COUNT(*) FROM repairs WHERE user_id IS NULL) +
        (SELECT COUNT(*) FROM product_categories WHERE user_id IS NULL)
    INTO v_donnees_sans_user_id;
    
    RAISE NOTICE '📋 État actuel:';
    RAISE NOTICE '  - Tables sans RLS: %', v_tables_sans_rls;
    RAISE NOTICE '  - Tables sans politiques: %', v_policies_manquantes;
    RAISE NOTICE '  - Données sans user_id: %', v_donnees_sans_user_id;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions URGENTES à effectuer:';
    
    IF v_tables_sans_rls > 0 THEN
        RAISE NOTICE '  1. 🚨 Activer RLS sur les tables sans sécurité';
    END IF;
    
    IF v_policies_manquantes > 0 THEN
        RAISE NOTICE '  2. 🚨 Créer des politiques RLS basées sur user_id';
    END IF;
    
    IF v_donnees_sans_user_id > 0 THEN
        RAISE NOTICE '  3. 🚨 Mettre à jour les données sans user_id';
    END IF;
    
    IF v_tables_sans_rls = 0 AND v_policies_manquantes = 0 AND v_donnees_sans_user_id = 0 THEN
        RAISE NOTICE '  ✅ Configuration semble correcte';
        RAISE NOTICE '  💡 Vérifiez les variables d''environnement Vercel';
    END IF;
    
END $$;
