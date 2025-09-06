-- Diagnostic des problèmes de suppression d'utilisateurs
-- Date: 2024-01-24
-- Ce script identifie toutes les contraintes qui empêchent la suppression d'utilisateurs

-- ========================================
-- 1. DIAGNOSTIC DES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- ========================================

SELECT 
    'CONTRAINTES DE CLÉS ÉTRANGÈRES' as diagnostic_type,
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule,
    CASE 
        WHEN rc.delete_rule = 'CASCADE' THEN '✅ CASCADE - Suppression en cascade'
        WHEN rc.delete_rule = 'SET NULL' THEN '⚠️ SET NULL - Met à NULL'
        WHEN rc.delete_rule = 'RESTRICT' THEN '❌ RESTRICT - Empêche la suppression'
        WHEN rc.delete_rule = 'NO ACTION' THEN '❌ NO ACTION - Empêche la suppression'
        ELSE '❓ ' || rc.delete_rule
    END as impact_suppression
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'users'
    AND ccu.table_schema = 'auth'
ORDER BY tc.table_name, tc.constraint_name;

-- ========================================
-- 2. DIAGNOSTIC DES POLITIQUES RLS
-- ========================================

SELECT 
    'POLITIQUES RLS' as diagnostic_type,
    schemaname,
    tablename,
    policyname,
    cmd,
    qual,
    with_check,
    CASE 
        WHEN cmd = 'DELETE' THEN '🔍 Politique DELETE'
        WHEN cmd = 'ALL' THEN '🔍 Politique ALL (inclut DELETE)'
        ELSE 'ℹ️ ' || cmd
    END as type_politique
FROM pg_policies 
WHERE schemaname = 'public'
    AND (cmd = 'DELETE' OR cmd = 'ALL')
ORDER BY tablename, policyname;

-- ========================================
-- 3. DIAGNOSTIC DES TRIGGERS SUR AUTH.USERS
-- ========================================

SELECT 
    'TRIGGERS AUTH.USERS' as diagnostic_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    CASE 
        WHEN event_manipulation = 'DELETE' THEN '⚠️ Trigger sur DELETE'
        WHEN event_manipulation = 'ALL' THEN '⚠️ Trigger sur ALL (inclut DELETE)'
        ELSE 'ℹ️ ' || event_manipulation
    END as impact_suppression
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
    AND event_object_schema = 'auth'
ORDER BY trigger_name;

-- ========================================
-- 4. DIAGNOSTIC DES TABLES AVEC DONNÉES LIÉES
-- ========================================

-- Vérifier quelles tables ont des données liées à des utilisateurs
SELECT 
    'DONNÉES LIÉES' as diagnostic_type,
    'subscription_status' as table_name,
    COUNT(*) as nombre_enregistrements,
    COUNT(DISTINCT user_id) as utilisateurs_uniques
FROM public.subscription_status
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'system_settings',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.system_settings
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'clients',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.clients
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'repairs',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.repairs
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'products',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.products
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'sales',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.sales
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'appointments',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.appointments
UNION ALL
SELECT 
    'DONNÉES LIÉES',
    'devices',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM public.devices;

-- ========================================
-- 5. DIAGNOSTIC DES PERMISSIONS
-- ========================================

SELECT 
    'PERMISSIONS' as diagnostic_type,
    table_name,
    privilege_type,
    grantee,
    CASE 
        WHEN privilege_type = 'DELETE' THEN '🔍 Permission DELETE'
        WHEN privilege_type = 'ALL' THEN '🔍 Permission ALL (inclut DELETE)'
        ELSE 'ℹ️ ' || privilege_type
    END as type_permission
FROM information_schema.role_table_grants 
WHERE table_name IN ('users', 'subscription_status', 'system_settings', 'clients', 'repairs', 'products', 'sales', 'appointments', 'devices')
    AND table_schema = 'public'
    AND privilege_type IN ('DELETE', 'ALL')
ORDER BY table_name, grantee;

-- ========================================
-- 6. RÉSUMÉ DU DIAGNOSTIC
-- ========================================

SELECT 
    'RÉSUMÉ' as diagnostic_type,
    'Contraintes RESTRICT/NO ACTION' as probleme,
    COUNT(*) as nombre_problemes
FROM information_schema.referential_constraints AS rc
JOIN information_schema.table_constraints AS tc
    ON rc.constraint_name = tc.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'users'
    AND ccu.table_schema = 'auth'
    AND rc.delete_rule IN ('RESTRICT', 'NO ACTION')
UNION ALL
SELECT 
    'RÉSUMÉ',
    'Politiques RLS DELETE',
    COUNT(*)
FROM pg_policies 
WHERE schemaname = 'public'
    AND (cmd = 'DELETE' OR cmd = 'ALL')
UNION ALL
SELECT 
    'RÉSUMÉ',
    'Triggers sur DELETE',
    COUNT(*)
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
    AND event_object_schema = 'auth'
    AND (event_manipulation = 'DELETE' OR event_manipulation = 'ALL');

-- ========================================
-- 7. RECOMMANDATIONS
-- ========================================

SELECT 
    'RECOMMANDATIONS' as diagnostic_type,
    '1. Modifier les contraintes RESTRICT/NO ACTION en CASCADE' as action,
    'Permet la suppression en cascade des données liées' as justification
UNION ALL
SELECT 
    'RECOMMANDATIONS',
    '2. Vérifier les politiques RLS DELETE',
    'S''assurer que les admins peuvent supprimer des utilisateurs'
UNION ALL
SELECT 
    'RECOMMANDATIONS',
    '3. Supprimer les triggers problématiques',
    'Éviter les conflits lors de la suppression'
UNION ALL
SELECT 
    'RECOMMANDATIONS',
    '4. Créer une fonction RPC pour la suppression',
    'Contrôler le processus de suppression avec SECURITY DEFINER';
