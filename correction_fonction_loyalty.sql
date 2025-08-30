-- 🔧 CORRECTION RAPIDE - Fonction get_loyalty_statistics
-- Script de correction rapide pour l'erreur 400 sur get_loyalty_statistics
-- Date: 2025-01-23

-- ============================================================================
-- CORRECTION IMMÉDIATE
-- ============================================================================

-- Supprimer la fonction existante si elle existe
DROP FUNCTION IF EXISTS get_loyalty_statistics();

-- Créer une nouvelle fonction get_loyalty_statistics
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
        COALESCE((SELECT COUNT(*) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)), 0)::INTEGER as total_clients,
        
        -- Clients avec des points
        COALESCE((SELECT COUNT(*) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points > 0), 0)::INTEGER as clients_with_points,
        
        -- Total des points
        COALESCE((SELECT SUM(loyalty_points) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)), 0)::BIGINT as total_points,
        
        -- Moyenne des points
        COALESCE((SELECT AVG(loyalty_points) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points > 0), 0)::NUMERIC as average_points,
        
        -- Clients de niveau supérieur
        COALESCE((SELECT COUNT(*) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points >= 1000), 0)::INTEGER as top_tier_clients,
        
        -- Activité récente (derniers 30 jours)
        COALESCE((SELECT COUNT(*) FROM loyalty_points_history 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND created_at >= NOW() - INTERVAL '30 days'), 0)::INTEGER as recent_activity;
END;
$$;

-- ============================================================================
-- VÉRIFICATION
-- ============================================================================

-- Vérifier que la fonction a été créée
SELECT 
    'Fonction créée' as info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_name = 'get_loyalty_statistics' 
    AND routine_schema = 'public';

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
-- RÉSUMÉ
-- ============================================================================

SELECT 
    'Correction terminée' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_statistics' 
            AND routine_schema = 'public'
        ) 
        THEN '✅ Fonction get_loyalty_statistics corrigée'
        ELSE '❌ Problème avec la correction'
    END as status;

SELECT '🎉 La fonction get_loyalty_statistics est maintenant disponible !' as message;
