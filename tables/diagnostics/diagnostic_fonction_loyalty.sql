-- 🔍 DIAGNOSTIC - Fonction get_loyalty_statistics
-- Script pour diagnostiquer et corriger l'erreur 400 sur get_loyalty_statistics
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DE LA FONCTION
-- ============================================================================

SELECT '=== DIAGNOSTIC DE LA FONCTION ===' as section;

-- Vérifier si la fonction existe
SELECT 
    'Existence fonction get_loyalty_statistics' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_statistics' 
            AND routine_schema = 'public'
        ) 
        THEN '✅ Fonction existe'
        ELSE '❌ Fonction n''existe pas'
    END as status;

-- Vérifier les détails de la fonction si elle existe
SELECT 
    'Détails de la fonction' as info,
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_loyalty_statistics' 
    AND routine_schema = 'public';

-- ============================================================================
-- 2. VÉRIFICATION DES TABLES DE FIDÉLITÉ
-- ============================================================================

SELECT '=== VÉRIFICATION DES TABLES DE FIDÉLITÉ ===' as section;

-- Vérifier l'existence des tables de fidélité
SELECT 
    'Tables de fidélité' as info,
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = table_name) 
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as status
FROM (
    SELECT 'loyalty_config' as table_name
    UNION ALL SELECT 'loyalty_tiers_advanced'
    UNION ALL SELECT 'loyalty_points_history'
    UNION ALL SELECT 'loyalty_dashboard'
) as loyalty_tables;

-- Vérifier la structure des tables de fidélité
SELECT 
    'Structure loyalty_config' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'loyalty_config'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. CRÉATION DE LA FONCTION MANQUANTE
-- ============================================================================

SELECT '=== CRÉATION DE LA FONCTION ===' as section;

-- Créer la fonction get_loyalty_statistics si elle n'existe pas
CREATE OR REPLACE FUNCTION get_loyalty_statistics()
RETURNS TABLE (
    total_clients INTEGER,
    clients_with_points INTEGER,
    total_points BIGINT,
    average_points NUMERIC,
    top_tier_clients INTEGER,
    recent_activity INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Total des clients
        (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))::INTEGER as total_clients,
        
        -- Clients avec des points
        (SELECT COUNT(*) FROM clients 
         WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
         AND loyalty_points > 0)::INTEGER as clients_with_points,
        
        -- Total des points
        COALESCE((SELECT SUM(loyalty_points) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)), 0)::BIGINT as total_points,
        
        -- Moyenne des points
        COALESCE((SELECT AVG(loyalty_points) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points > 0), 0)::NUMERIC as average_points,
        
        -- Clients de niveau supérieur
        (SELECT COUNT(*) FROM clients 
         WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
         AND loyalty_points >= 1000)::INTEGER as top_tier_clients,
        
        -- Activité récente (derniers 30 jours)
        (SELECT COUNT(*) FROM loyalty_points_history 
         WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
         AND created_at >= NOW() - INTERVAL '30 days')::INTEGER as recent_activity;
END;
$$;

-- ============================================================================
-- 4. VÉRIFICATION DE LA FONCTION CRÉÉE
-- ============================================================================

SELECT '=== VÉRIFICATION DE LA FONCTION ===' as section;

-- Vérifier que la fonction a été créée
SELECT 
    'Fonction créée' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'get_loyalty_statistics' 
    AND routine_schema = 'public';

-- ============================================================================
-- 5. TEST DE LA FONCTION
-- ============================================================================

SELECT '=== TEST DE LA FONCTION ===' as section;

-- Tester la fonction
SELECT 
    'Test de la fonction' as info,
    total_clients,
    clients_with_points,
    total_points,
    average_points,
    top_tier_clients,
    recent_activity
FROM get_loyalty_statistics();

-- ============================================================================
-- 6. VÉRIFICATION DES PERMISSIONS
-- ============================================================================

SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as section;

-- Vérifier les permissions sur la fonction
SELECT 
    'Permissions fonction' as info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_name = 'get_loyalty_statistics' 
    AND routine_schema = 'public';

-- ============================================================================
-- 7. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction
SELECT 
    'Résumé de la correction' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_statistics' 
            AND routine_schema = 'public'
        ) 
        THEN '✅ Fonction get_loyalty_statistics créée/réparée'
        ELSE '❌ Problème avec la création de la fonction'
    END as function_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM get_loyalty_statistics()) > 0 
        THEN '✅ Fonction fonctionne correctement'
        ELSE '❌ Fonction ne retourne pas de données'
    END as function_test;

-- Message final
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_statistics' 
            AND routine_schema = 'public'
        ) 
        THEN '🎉 SUCCÈS: La fonction get_loyalty_statistics est maintenant disponible !'
        ELSE '⚠️ PROBLÈME: La fonction n''a pas pu être créée'
    END as final_message;
