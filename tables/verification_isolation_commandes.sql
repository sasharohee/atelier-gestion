-- =====================================================
-- VÉRIFICATION DE L'ISOLATION DES COMMANDES
-- =====================================================
-- Script pour vérifier que l'isolation fonctionne correctement
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION DE LA STRUCTURE DES TABLES
-- =====================================================

SELECT '=== VÉRIFICATION STRUCTURE TABLES ===' as section;

-- Vérifier que les tables existent
SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ Table créée'
        ELSE '❌ Table manquante'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('orders', 'order_items', 'suppliers');

-- Vérifier les colonnes d'isolation
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'workshop_id' THEN '✅ Colonne isolation'
        WHEN column_name = 'created_by' THEN '✅ Colonne traçabilité'
        ELSE 'ℹ️ Autre colonne'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('orders', 'order_items', 'suppliers')
AND column_name IN ('workshop_id', 'created_by')
ORDER BY table_name, column_name;

-- 2. VÉRIFICATION DES POLITIQUES RLS
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

-- 3. VÉRIFICATION DES TRIGGERS
-- =====================================================

SELECT '=== VÉRIFICATION TRIGGERS ===' as section;

-- Vérifier les triggers d'isolation
SELECT 
    trigger_name,
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

-- 4. VÉRIFICATION DES INDEX
-- =====================================================

SELECT '=== VÉRIFICATION INDEX ===' as section;

-- Vérifier les index de performance
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

-- 5. VÉRIFICATION DES FONCTIONS
-- =====================================================

SELECT '=== VÉRIFICATION FONCTIONS ===' as section;

-- Vérifier les fonctions utilitaires
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

-- 6. TEST D'ISOLATION (SIMULATION)
-- =====================================================

SELECT '=== TEST D''ISOLATION ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as test,
    value as workshop_id
FROM system_settings 
WHERE key = 'workshop_id'
LIMIT 1;

-- Vérifier le type de workshop
SELECT 
    'Type workshop' as test,
    value as workshop_type
FROM system_settings 
WHERE key = 'workshop_type'
LIMIT 1;

-- 7. FONCTION DE TEST COMPLÈTE
-- =====================================================

-- Créer une fonction pour tester l'isolation
CREATE OR REPLACE FUNCTION test_order_isolation()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
    v_test_order_id UUID;
    v_test_item_id UUID;
BEGIN
    -- Obtenir les paramètres actuels
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Test 1: Vérifier que les tables sont vides
    RETURN QUERY
    SELECT 
        'Tables vides'::TEXT,
        CASE 
            WHEN (SELECT COUNT(*) FROM orders) = 0 
            AND (SELECT COUNT(*) FROM order_items) = 0 
            AND (SELECT COUNT(*) FROM suppliers) = 0
            THEN '✅ OK'
            ELSE '⚠️ Données existantes'
        END::TEXT,
        'Tables prêtes pour les tests'::TEXT;
    
    -- Test 2: Vérifier les politiques RLS
    RETURN QUERY
    SELECT 
        'Politiques RLS'::TEXT,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM pg_policies 
                WHERE tablename = 'orders' 
                AND qual LIKE '%workshop_id%'
            )
            THEN '✅ OK'
            ELSE '❌ Manquantes'
        END::TEXT,
        'Politiques d''isolation configurées'::TEXT;
    
    -- Test 3: Vérifier les triggers
    RETURN QUERY
    SELECT 
        'Triggers isolation'::TEXT,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE event_object_table = 'orders' 
                AND trigger_name LIKE '%isolation%'
            )
            THEN '✅ OK'
            ELSE '❌ Manquants'
        END::TEXT,
        'Triggers d''isolation configurés'::TEXT;
    
    -- Test 4: Vérifier les fonctions
    RETURN QUERY
    SELECT 
        'Fonctions utilitaires'::TEXT,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM information_schema.routines 
                WHERE routine_name = 'get_order_stats'
            )
            THEN '✅ OK'
            ELSE '❌ Manquantes'
        END::TEXT,
        'Fonctions de statistiques disponibles'::TEXT;
    
    -- Test 5: Vérifier les contraintes
    RETURN QUERY
    SELECT 
        'Contraintes'::TEXT,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM information_schema.table_constraints 
                WHERE table_name = 'orders' 
                AND constraint_type = 'UNIQUE'
            )
            THEN '✅ OK'
            ELSE '❌ Manquantes'
        END::TEXT,
        'Contraintes d''unicité configurées'::TEXT;
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Exécuter le test d'isolation
SELECT * FROM test_order_isolation();

-- 8. RÉSUMÉ DE LA VÉRIFICATION
-- =====================================================

SELECT '=== RÉSUMÉ DE LA VÉRIFICATION ===' as section;

SELECT 
    'Isolation des commandes' as fonctionnalite,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'orders'
        )
        AND EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'orders' 
            AND qual LIKE '%workshop_id%'
        )
        THEN '✅ Prête à l''utilisation'
        ELSE '❌ Configuration incomplète'
    END as status,
    'Tables, politiques RLS et isolation configurées' as description;

