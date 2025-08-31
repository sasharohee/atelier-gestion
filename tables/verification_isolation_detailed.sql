-- =====================================================
-- VÉRIFICATION ISOLATION DÉTAILLÉE
-- =====================================================
-- Diagnostic complet pour identifier pourquoi l'isolation ne fonctionne pas
-- Date: 2025-01-23
-- =====================================================

SELECT 'VÉRIFICATION ISOLATION DÉTAILLÉE' as section;

-- 1. VÉRIFIER L'UTILISATEUR ACTUEL ET SON CONTEXTE
-- =====================================================

SELECT 
    'UTILISATEUR ACTUEL' as verification,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN '✅ Authentifié'
        ELSE '❌ Non authentifié'
    END as auth_status;

-- 2. VÉRIFIER SYSTEM_SETTINGS
-- =====================================================

SELECT 
    'SYSTEM_SETTINGS' as verification,
    key,
    value,
    CASE 
        WHEN key = 'workshop_id' THEN '✅ Workshop ID'
        WHEN key = 'workshop_type' THEN '✅ Type Workshop'
        WHEN key = 'workshop_name' THEN '✅ Nom Workshop'
        ELSE 'ℹ️ Autre paramètre'
    END as type_parametre
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type', 'workshop_name')
ORDER BY key;

-- 3. VÉRIFIER SUBSCRIPTION_STATUS
-- =====================================================

SELECT 
    'SUBSCRIPTION_STATUS' as verification,
    user_id,
    email,
    workshop_id,
    created_at,
    CASE 
        WHEN workshop_id IS NOT NULL THEN '✅ Workshop_id défini'
        ELSE '❌ Workshop_id manquant'
    END as workshop_status
FROM subscription_status 
ORDER BY created_at;

-- 4. VÉRIFIER LES COMMANDES ET LEUR WORKSHOP_ID
-- =====================================================

SELECT 
    'COMMANDES DÉTAILLÉES' as verification,
    id,
    order_number,
    workshop_id as order_workshop_id,
    created_by,
    status,
    created_at,
    CASE 
        WHEN workshop_id IS NOT NULL THEN '✅ Workshop_id défini'
        ELSE '❌ Workshop_id manquant'
    END as workshop_status
FROM orders 
ORDER BY created_at DESC;

-- 5. VÉRIFIER LA CORRESPONDANCE WORKSHOP_ID
-- =====================================================

SELECT 
    'CORRESPONDANCE WORKSHOP_ID' as verification,
    o.id as order_id,
    o.order_number,
    o.workshop_id as order_workshop_id,
    ss.workshop_id as user_workshop_id,
    s.value as system_workshop_id,
    o.created_by,
    ss.email,
    CASE 
        WHEN o.workshop_id = ss.workshop_id THEN '✅ CORRESPONDANCE USER'
        ELSE '❌ DIFFÉRENCE USER'
    END as user_match,
    CASE 
        WHEN o.workshop_id = s.value::uuid THEN '✅ CORRESPONDANCE SYSTEM'
        ELSE '❌ DIFFÉRENCE SYSTEM'
    END as system_match
FROM orders o
JOIN subscription_status ss ON o.created_by = ss.user_id
LEFT JOIN system_settings s ON s.key = 'workshop_id'
ORDER BY o.created_at DESC;

-- 6. VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS ORDERS' as verification,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual LIKE '%system_settings%' THEN '✅ Isolation par system_settings'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        WHEN qual IS NULL THEN '❌ Pas de condition'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 7. TESTER LES POLITIQUES RLS MANUELLEMENT
-- =====================================================

SELECT 
    'TEST POLITIQUES RLS' as verification,
    'Exécuter les requêtes suivantes pour tester:' as instruction;

-- Test de la politique SELECT
SELECT 
    'TEST SELECT POLICY' as test,
    COUNT(*) as orders_visible,
    'Nombre de commandes visibles avec la politique actuelle' as description
FROM orders;

-- Test de la condition workshop_id
SELECT 
    'TEST WORKSHOP_ID CONDITION' as test,
    (
        SELECT value::UUID 
        FROM system_settings 
        WHERE key = 'workshop_id' 
        LIMIT 1
    ) as current_workshop_id,
    'Workshop_id actuel depuis system_settings' as description;

-- 8. VÉRIFIER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    'FONCTION ISOLATION' as verification,
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 9. VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    'TRIGGER ISOLATION' as verification,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 10. TESTER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    'TEST FONCTION ISOLATION' as verification,
    'Test de la fonction set_order_isolation:' as instruction;

-- Simuler l'appel de la fonction
DO $$
DECLARE
    v_workshop_id uuid;
    v_user_id uuid;
BEGIN
    -- Récupérer le workshop_id depuis system_settings
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    RAISE NOTICE 'Workshop_id depuis system_settings: %', v_workshop_id;
    RAISE NOTICE 'User_id connecté: %', v_user_id;
END $$;

-- 11. VÉRIFIER LES DONNÉES DE TEST
-- =====================================================

SELECT 
    'DONNÉES DE TEST' as verification,
    'Créer une commande de test pour vérifier l''isolation' as instruction;

-- 12. RÉSUMÉ DIAGNOSTIC
-- =====================================================

SELECT 
    'RÉSUMÉ DIAGNOSTIC' as verification,
    (SELECT COUNT(*) FROM system_settings WHERE key = 'workshop_id') as system_workshop_count,
    (SELECT COUNT(*) FROM subscription_status WHERE workshop_id IS NOT NULL) as users_with_workshop,
    (SELECT COUNT(*) FROM orders) as total_orders,
    (SELECT COUNT(*) FROM orders WHERE workshop_id IS NOT NULL) as orders_with_workshop,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'orders') as rls_policies_count,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name = 'set_order_isolation') as isolation_function_count,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'orders') as trigger_count;

-- 13. RÉSULTAT
-- =====================================================

SELECT 
    'DIAGNOSTIC TERMINÉ' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Vérification détaillée de l''isolation effectuée' as description;
