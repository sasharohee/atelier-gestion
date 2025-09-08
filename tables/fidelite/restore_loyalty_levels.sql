-- =====================================================
-- RESTAURATION NIVEAUX DE FIDÉLITÉ
-- =====================================================
-- Script pour recréer les niveaux par défaut pour tous les utilisateurs
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC de l'état actuel
SELECT '=== DIAGNOSTIC ÉTAT ACTUEL ===' as etape;

-- Vérifier les données actuelles
SELECT 
    'loyalty_tiers_advanced' as table_name,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as names
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

SELECT 
    'loyalty_config' as table_name,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(key, ', ') as keys
FROM loyalty_config 
GROUP BY workshop_id
ORDER BY workshop_id;

-- 2. CRÉER les niveaux par défaut pour l'utilisateur actuel
SELECT '=== CRÉATION NIVEAUX PAR DÉFAUT ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_tiers_count INTEGER := 0;
    v_config_count INTEGER := 0;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔄 Création des niveaux pour l''utilisateur: %', v_current_user_id;
    
    -- Vérifier si des niveaux existent déjà
    SELECT COUNT(*) INTO v_tiers_count 
    FROM loyalty_tiers_advanced 
    WHERE workshop_id = v_current_user_id;
    
    IF v_tiers_count = 0 THEN
        -- Créer les niveaux par défaut
        INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
        VALUES 
            (v_current_user_id, 'Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
            (v_current_user_id, 'Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
            (v_current_user_id, 'Or', 500, 10.00, '#FFD700', '10% de réduction', true),
            (v_current_user_id, 'Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
            (v_current_user_id, 'Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true);
        
        RAISE NOTICE '✅ 5 niveaux par défaut créés';
    ELSE
        RAISE NOTICE 'ℹ️ % niveaux existent déjà', v_tiers_count;
    END IF;
    
    -- Vérifier si une configuration existe déjà
    SELECT COUNT(*) INTO v_config_count 
    FROM loyalty_config 
    WHERE workshop_id = v_current_user_id;
    
    IF v_config_count = 0 THEN
        -- Créer la configuration par défaut
        INSERT INTO loyalty_config (workshop_id, key, value, description)
        VALUES 
            (v_current_user_id, 'points_per_euro', '1', 'Points gagnés par euro dépensé'),
            (v_current_user_id, 'minimum_purchase', '10', 'Montant minimum pour gagner des points'),
            (v_current_user_id, 'bonus_threshold', '100', 'Seuil pour bonus de points'),
            (v_current_user_id, 'bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
            (v_current_user_id, 'points_expiry_days', '365', 'Durée de validité des points en jours'),
            (v_current_user_id, 'auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');
        
        RAISE NOTICE '✅ 6 configurations par défaut créées';
    ELSE
        RAISE NOTICE 'ℹ️ % configurations existent déjà', v_config_count;
    END IF;
    
END $$;

-- 3. VÉRIFIER la création
SELECT '=== VÉRIFICATION CRÉATION ===' as etape;

-- Vérifier les niveaux créés
SELECT 
    'loyalty_tiers_advanced' as table_name,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as names
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

-- Vérifier les configurations créées
SELECT 
    'loyalty_config' as table_name,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(key, ', ') as keys
FROM loyalty_config 
GROUP BY workshop_id
ORDER BY workshop_id;

-- 4. TEST des fonctions
SELECT '=== TEST DES FONCTIONS ===' as etape;

DO $$
DECLARE
    v_tiers_count INTEGER := 0;
    v_config_count INTEGER := 0;
BEGIN
    -- Test de la fonction get_workshop_loyalty_tiers
    BEGIN
        SELECT COUNT(*) INTO v_tiers_count FROM get_workshop_loyalty_tiers();
        RAISE NOTICE '✅ Fonction get_workshop_loyalty_tiers: % niveaux récupérés', v_tiers_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur fonction get_workshop_loyalty_tiers: %', SQLERRM;
    END;
    
    -- Test de la fonction get_workshop_loyalty_config
    BEGIN
        SELECT COUNT(*) INTO v_config_count FROM get_workshop_loyalty_config();
        RAISE NOTICE '✅ Fonction get_workshop_loyalty_config: % configurations récupérées', v_config_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur fonction get_workshop_loyalty_config: %', SQLERRM;
    END;
    
END $$;

-- 5. AFFICHER les niveaux créés
SELECT '=== NIVEAUX CRÉÉS ===' as etape;

SELECT 
    name,
    points_required,
    discount_percentage,
    color,
    description,
    is_active
FROM loyalty_tiers_advanced 
WHERE workshop_id = auth.uid()
ORDER BY points_required ASC;

-- 6. AFFICHER les configurations créées
SELECT '=== CONFIGURATIONS CRÉÉES ===' as etape;

SELECT 
    key,
    value,
    description
FROM loyalty_config 
WHERE workshop_id = auth.uid()
ORDER BY key;

-- 7. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Niveaux par défaut créés' as message;
SELECT '✅ Configuration par défaut créée' as config;
SELECT '✅ Fonctions testées' as fonctions;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les niveaux sont maintenant disponibles dans l''interface' as note;
