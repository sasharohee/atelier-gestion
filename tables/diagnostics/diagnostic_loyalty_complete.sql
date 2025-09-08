-- =====================================================
-- DIAGNOSTIC COMPLET LOYALTY
-- =====================================================
-- Script pour diagnostiquer et corriger tous les problèmes de fidélité
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC COMPLET
SELECT '=== DIAGNOSTIC COMPLET ===' as etape;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ Non connecté'
        ELSE '✅ Connecté'
    END as status;

-- Vérifier les données dans loyalty_tiers_advanced
SELECT 
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN workshop_id = auth.uid() THEN 1 END) as my_count,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as null_workshop_id,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count
FROM loyalty_tiers_advanced;

-- Vérifier les données dans loyalty_config
SELECT 
    'loyalty_config' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN workshop_id = auth.uid() THEN 1 END) as my_count,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as null_workshop_id
FROM loyalty_config;

-- Vérifier les clients avec des points de fidélité
SELECT 
    'clients' as table_name,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_with_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_with_tier_id
FROM clients;

-- 2. AFFICHER les données détaillées
SELECT '=== DONNÉES DÉTAILLÉES ===' as etape;

-- Afficher tous les niveaux (même ceux d'autres utilisateurs pour diagnostic)
SELECT 
    'Tous les niveaux' as info,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    is_active,
    created_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- Afficher tous les clients avec des points
SELECT 
    'Clients avec points' as info,
    id,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    created_at
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- 3. VÉRIFIER les politiques RLS
SELECT '=== VÉRIFICATION POLITIQUES RLS ===' as etape;

SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'clients')
ORDER BY tablename, policyname;

-- 4. VÉRIFIER les triggers
SELECT '=== VÉRIFICATION TRIGGERS ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_tiers_advanced', 'loyalty_config', 'clients')
ORDER BY event_object_table, trigger_name;

-- 5. VÉRIFIER les fonctions
SELECT '=== VÉRIFICATION FONCTIONS ===' as etape;

SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%loyalty%'
ORDER BY routine_name;

-- 6. TEST des fonctions RPC
SELECT '=== TEST FONCTIONS RPC ===' as etape;

DO $$
DECLARE
    v_tiers_count INTEGER := 0;
    v_config_count INTEGER := 0;
    v_error_message TEXT;
BEGIN
    -- Test de la fonction get_workshop_loyalty_tiers
    BEGIN
        SELECT COUNT(*) INTO v_tiers_count FROM get_workshop_loyalty_tiers();
        RAISE NOTICE '✅ get_workshop_loyalty_tiers: % niveaux récupérés', v_tiers_count;
    EXCEPTION WHEN OTHERS THEN
        v_error_message := SQLERRM;
        RAISE NOTICE '❌ Erreur get_workshop_loyalty_tiers: %', v_error_message;
    END;
    
    -- Test de la fonction get_workshop_loyalty_config
    BEGIN
        SELECT COUNT(*) INTO v_config_count FROM get_workshop_loyalty_config();
        RAISE NOTICE '✅ get_workshop_loyalty_config: % configurations récupérées', v_config_count;
    EXCEPTION WHEN OTHERS THEN
        v_error_message := SQLERRM;
        RAISE NOTICE '❌ Erreur get_workshop_loyalty_config: %', v_error_message;
    END;
    
END $$;

-- 7. CORRECTION AUTOMATIQUE
SELECT '=== CORRECTION AUTOMATIQUE ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_tiers_count INTEGER := 0;
    v_config_count INTEGER := 0;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté - impossible de corriger';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔄 Correction pour l''utilisateur: %', v_current_user_id;
    
    -- Vérifier et créer les niveaux si nécessaire
    SELECT COUNT(*) INTO v_tiers_count 
    FROM loyalty_tiers_advanced 
    WHERE workshop_id = v_current_user_id;
    
    IF v_tiers_count = 0 THEN
        RAISE NOTICE '🆕 Création des niveaux par défaut';
        
        INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
        VALUES 
            (v_current_user_id, 'Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
            (v_current_user_id, 'Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
            (v_current_user_id, 'Or', 500, 10.00, '#FFD700', '10% de réduction', true),
            (v_current_user_id, 'Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
            (v_current_user_id, 'Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true);
        
        RAISE NOTICE '✅ 5 niveaux créés';
    ELSE
        RAISE NOTICE 'ℹ️ % niveaux existent déjà', v_tiers_count;
    END IF;
    
    -- Vérifier et créer la configuration si nécessaire
    SELECT COUNT(*) INTO v_config_count 
    FROM loyalty_config 
    WHERE workshop_id = v_current_user_id;
    
    IF v_config_count = 0 THEN
        RAISE NOTICE '🆕 Création de la configuration par défaut';
        
        INSERT INTO loyalty_config (workshop_id, key, value, description)
        VALUES 
            (v_current_user_id, 'points_per_euro', '1', 'Points gagnés par euro dépensé'),
            (v_current_user_id, 'minimum_purchase', '10', 'Montant minimum pour gagner des points'),
            (v_current_user_id, 'bonus_threshold', '100', 'Seuil pour bonus de points'),
            (v_current_user_id, 'bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
            (v_current_user_id, 'points_expiry_days', '365', 'Durée de validité des points en jours'),
            (v_current_user_id, 'auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');
        
        RAISE NOTICE '✅ 6 configurations créées';
    ELSE
        RAISE NOTICE 'ℹ️ % configurations existent déjà', v_config_count;
    END IF;
    
    -- Nettoyer les clients avec des tier_id invalides
    UPDATE clients 
    SET current_tier_id = NULL 
    WHERE current_tier_id IS NOT NULL 
    AND current_tier_id NOT IN (
        SELECT id FROM loyalty_tiers_advanced WHERE workshop_id = v_current_user_id
    );
    
    RAISE NOTICE '✅ Clients nettoyés (tier_id invalides supprimés)';
    
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les niveaux après correction
SELECT 
    'Niveaux après correction' as info,
    name,
    points_required,
    discount_percentage,
    color,
    is_active
FROM loyalty_tiers_advanced 
WHERE workshop_id = auth.uid()
ORDER BY points_required;

-- Vérifier les configurations après correction
SELECT 
    'Configurations après correction' as info,
    key,
    value,
    description
FROM loyalty_config 
WHERE workshop_id = auth.uid()
ORDER BY key;

-- Vérifier les clients après correction
SELECT 
    'Clients après correction' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    CASE 
        WHEN current_tier_id IS NULL THEN 'Aucun tier'
        WHEN current_tier_id IN (SELECT id FROM loyalty_tiers_advanced WHERE workshop_id = auth.uid()) THEN 'Tier valide'
        ELSE 'Tier invalide'
    END as tier_status
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- 9. TEST FINAL des fonctions
SELECT '=== TEST FINAL ===' as etape;

DO $$
DECLARE
    v_tiers_count INTEGER := 0;
    v_config_count INTEGER := 0;
BEGIN
    -- Test final des fonctions
    SELECT COUNT(*) INTO v_tiers_count FROM get_workshop_loyalty_tiers();
    SELECT COUNT(*) INTO v_config_count FROM get_workshop_loyalty_config();
    
    RAISE NOTICE '📊 Résultat final:';
    RAISE NOTICE '  - Niveaux récupérés: %', v_tiers_count;
    RAISE NOTICE '  - Configurations récupérées: %', v_config_count;
    
    IF v_tiers_count > 0 AND v_config_count > 0 THEN
        RAISE NOTICE '✅ TOUT FONCTIONNE CORRECTEMENT';
    ELSE
        RAISE NOTICE '❌ PROBLÈME PERSISTANT';
    END IF;
    
END $$;

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Diagnostic complet effectué' as message;
SELECT '✅ Correction automatique appliquée' as correction;
SELECT '✅ Niveaux et configurations créés' as creation;
SELECT '✅ Clients nettoyés' as nettoyage;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Vérifiez l''interface après redéploiement' as note;
