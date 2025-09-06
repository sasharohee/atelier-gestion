-- =====================================================
-- DIAGNOSTIC DES TABLES DE COMMANDES
-- =====================================================
-- Script pour diagnostiquer les problèmes avec les commandes
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION DE L'EXISTENCE DES TABLES
-- =====================================================

SELECT '=== VÉRIFICATION EXISTENCE TABLES ===' as section;

SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ Table existe'
        ELSE '❌ Table manquante'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('orders', 'order_items', 'suppliers');

-- 2. VÉRIFICATION DE LA STRUCTURE DES TABLES
-- =====================================================

SELECT '=== VÉRIFICATION STRUCTURE TABLES ===' as section;

-- Structure de la table orders
SELECT 
    'orders' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'orders'
ORDER BY ordinal_position;

-- Structure de la table order_items
SELECT 
    'order_items' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'order_items'
ORDER BY ordinal_position;

-- 3. VÉRIFICATION DES POLITIQUES RLS
-- =====================================================

SELECT '=== VÉRIFICATION POLITIQUES RLS ===' as section;

-- Vérifier l'activation RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename;

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        WHEN qual IS NULL THEN '❌ Pas de condition'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, policyname;

-- 4. VÉRIFICATION DES TRIGGERS
-- =====================================================

SELECT '=== VÉRIFICATION TRIGGERS ===' as section;

SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement,
    CASE 
        WHEN trigger_name LIKE '%isolation%' THEN '✅ Trigger isolation'
        WHEN trigger_name LIKE '%total%' THEN '✅ Trigger calcul'
        ELSE 'ℹ️ Autre trigger'
    END as type_trigger
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('orders', 'order_items', 'suppliers')
ORDER BY event_object_table, trigger_name;

-- 5. VÉRIFICATION DES FONCTIONS
-- =====================================================

SELECT '=== VÉRIFICATION FONCTIONS ===' as section;

SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name = 'get_order_stats' THEN '✅ Fonction statistiques'
        WHEN routine_name = 'search_orders' THEN '✅ Fonction recherche'
        WHEN routine_name = 'set_order_isolation' THEN '✅ Fonction isolation'
        WHEN routine_name = 'update_order_total' THEN '✅ Fonction calcul'
        ELSE 'ℹ️ Autre fonction'
    END as type_fonction
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('get_order_stats', 'search_orders', 'set_order_isolation', 'update_order_total')
ORDER BY routine_name;

-- 6. VÉRIFICATION DES DONNÉES EXISTANTES
-- =====================================================

SELECT '=== VÉRIFICATION DONNÉES ===' as section;

-- Compter les commandes existantes
SELECT 
    'orders' as table_name,
    COUNT(*) as nombre_enregistrements
FROM orders
UNION ALL
SELECT 
    'order_items' as table_name,
    COUNT(*) as nombre_enregistrements
FROM order_items
UNION ALL
SELECT 
    'suppliers' as table_name,
    COUNT(*) as nombre_enregistrements
FROM suppliers;

-- 7. VÉRIFICATION DES PARAMÈTRES SYSTÈME
-- =====================================================

SELECT '=== VÉRIFICATION PARAMÈTRES SYSTÈME ===' as section;

-- Vérifier le workshop_id configuré
SELECT 
    key,
    value,
    CASE 
        WHEN key = 'workshop_id' THEN '✅ Workshop ID'
        WHEN key = 'workshop_type' THEN '✅ Type Workshop'
        ELSE 'ℹ️ Autre paramètre'
    END as type_parametre
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type', 'workshop_name');

-- 8. TEST D'INSERTION SIMPLE
-- =====================================================

SELECT '=== TEST D''INSERTION ===' as section;

-- Test d'insertion d'une commande simple
DO $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
    v_order_id UUID;
    v_test_result TEXT;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir un utilisateur
    SELECT id INTO v_user_id
    FROM auth.users 
    LIMIT 1;
    
    -- Test d'insertion
    BEGIN
        INSERT INTO orders (
            order_number,
            supplier_name,
            supplier_email,
            order_date,
            status,
            total_amount,
            notes
        ) VALUES (
            'TEST-' || EXTRACT(EPOCH FROM NOW())::TEXT,
            'Fournisseur Test',
            'test@fournisseur.com',
            CURRENT_DATE,
            'pending',
            0,
            'Commande de test pour diagnostic'
        ) RETURNING id INTO v_order_id;
        
        v_test_result := '✅ Insertion réussie - ID: ' || v_order_id;
        
        -- Nettoyer le test
        DELETE FROM orders WHERE id = v_order_id;
        
    EXCEPTION WHEN OTHERS THEN
        v_test_result := '❌ Erreur insertion: ' || SQLERRM;
    END;
    
    RAISE NOTICE '%', v_test_result;
END $$;

-- 9. VÉRIFICATION DES INDEX
-- =====================================================

SELECT '=== VÉRIFICATION INDEX ===' as section;

SELECT 
    tablename,
    indexname,
    CASE 
        WHEN indexname LIKE '%workshop_id%' THEN '✅ Index isolation'
        WHEN indexname LIKE '%order_id%' THEN '✅ Index relation'
        WHEN indexname LIKE '%status%' THEN '✅ Index statut'
        ELSE 'ℹ️ Autre index'
    END as type_index
FROM pg_indexes 
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, indexname;

-- 10. RÉSUMÉ DU DIAGNOSTIC
-- =====================================================

SELECT '=== RÉSUMÉ DU DIAGNOSTIC ===' as section;

SELECT 
    'Tables créées' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'order_items')
        THEN '✅ OK'
        ELSE '❌ Manquantes'
    END as status
UNION ALL
SELECT 
    'Politiques RLS' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'orders' AND qual LIKE '%workshop_id%')
        THEN '✅ OK'
        ELSE '❌ Manquantes'
    END as status
UNION ALL
SELECT 
    'Triggers isolation' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name LIKE '%isolation%')
        THEN '✅ OK'
        ELSE '❌ Manquants'
    END as status
UNION ALL
SELECT 
    'Fonctions utilitaires' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_order_stats')
        THEN '✅ OK'
        ELSE '❌ Manquantes'
    END as status
UNION ALL
SELECT 
    'Workshop ID configuré' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM system_settings WHERE key = 'workshop_id')
        THEN '✅ OK'
        ELSE '❌ Non configuré'
    END as status;

