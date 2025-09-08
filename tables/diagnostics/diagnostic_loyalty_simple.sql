-- =====================================================
-- DIAGNOSTIC SIMPLE LOYALTY
-- =====================================================
-- Script pour diagnostiquer et corriger les problèmes de fidélité
-- Fonctionne même sans authentification
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC SIMPLE
SELECT '=== DIAGNOSTIC SIMPLE ===' as etape;

-- Vérifier les données dans loyalty_tiers_advanced
SELECT 
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as total_count,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as null_workshop_id,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count
FROM loyalty_tiers_advanced;

-- Vérifier les données dans loyalty_config
SELECT 
    'loyalty_config' as table_name,
    COUNT(*) as total_count,
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

-- Afficher tous les niveaux
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

-- 6. CRÉER les niveaux par défaut pour tous les utilisateurs
SELECT '=== CRÉATION NIVEAUX PAR DÉFAUT ===' as etape;

-- Créer les niveaux par défaut pour chaque utilisateur unique
INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT DISTINCT 
    workshop_id,
    'Bronze',
    0,
    0.00,
    '#CD7F32',
    'Niveau de base',
    true
FROM loyalty_tiers_advanced 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta2 
    WHERE lta2.workshop_id = loyalty_tiers_advanced.workshop_id 
    AND lta2.name = 'Bronze'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT DISTINCT 
    workshop_id,
    'Argent',
    100,
    5.00,
    '#C0C0C0',
    '5% de réduction',
    true
FROM loyalty_tiers_advanced 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta2 
    WHERE lta2.workshop_id = loyalty_tiers_advanced.workshop_id 
    AND lta2.name = 'Argent'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT DISTINCT 
    workshop_id,
    'Or',
    500,
    10.00,
    '#FFD700',
    '10% de réduction',
    true
FROM loyalty_tiers_advanced 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta2 
    WHERE lta2.workshop_id = loyalty_tiers_advanced.workshop_id 
    AND lta2.name = 'Or'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT DISTINCT 
    workshop_id,
    'Platine',
    1000,
    15.00,
    '#E5E4E2',
    '15% de réduction',
    true
FROM loyalty_tiers_advanced 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta2 
    WHERE lta2.workshop_id = loyalty_tiers_advanced.workshop_id 
    AND lta2.name = 'Platine'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT DISTINCT 
    workshop_id,
    'Diamant',
    2000,
    20.00,
    '#B9F2FF',
    '20% de réduction',
    true
FROM loyalty_tiers_advanced 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta2 
    WHERE lta2.workshop_id = loyalty_tiers_advanced.workshop_id 
    AND lta2.name = 'Diamant'
);

-- 7. CRÉER la configuration par défaut pour tous les utilisateurs
SELECT '=== CRÉATION CONFIGURATION PAR DÉFAUT ===' as etape;

-- Créer la configuration par défaut pour chaque utilisateur unique
INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT DISTINCT 
    workshop_id,
    'points_per_euro',
    '1',
    'Points gagnés par euro dépensé'
FROM loyalty_config 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config lc2 
    WHERE lc2.workshop_id = loyalty_config.workshop_id 
    AND lc2.key = 'points_per_euro'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT DISTINCT 
    workshop_id,
    'minimum_purchase',
    '10',
    'Montant minimum pour gagner des points'
FROM loyalty_config 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config lc2 
    WHERE lc2.workshop_id = loyalty_config.workshop_id 
    AND lc2.key = 'minimum_purchase'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT DISTINCT 
    workshop_id,
    'bonus_threshold',
    '100',
    'Seuil pour bonus de points'
FROM loyalty_config 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config lc2 
    WHERE lc2.workshop_id = loyalty_config.workshop_id 
    AND lc2.key = 'bonus_threshold'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT DISTINCT 
    workshop_id,
    'bonus_multiplier',
    '1.5',
    'Multiplicateur de bonus'
FROM loyalty_config 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config lc2 
    WHERE lc2.workshop_id = loyalty_config.workshop_id 
    AND lc2.key = 'bonus_multiplier'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT DISTINCT 
    workshop_id,
    'points_expiry_days',
    '365',
    'Durée de validité des points en jours'
FROM loyalty_config 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config lc2 
    WHERE lc2.workshop_id = loyalty_config.workshop_id 
    AND lc2.key = 'points_expiry_days'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT DISTINCT 
    workshop_id,
    'auto_tier_upgrade',
    'true',
    'Mise à jour automatique des niveaux de fidélité'
FROM loyalty_config 
WHERE workshop_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config lc2 
    WHERE lc2.workshop_id = loyalty_config.workshop_id 
    AND lc2.key = 'auto_tier_upgrade'
);

-- 8. NETTOYER les clients avec des tier_id invalides
SELECT '=== NETTOYAGE CLIENTS ===' as etape;

-- Supprimer les current_tier_id qui ne correspondent à aucun tier existant
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL 
AND current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

-- 9. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les niveaux après correction
SELECT 
    'Niveaux après correction' as info,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- Vérifier les configurations après correction
SELECT 
    'Configurations après correction' as info,
    workshop_id,
    key,
    value,
    description
FROM loyalty_config 
ORDER BY workshop_id, key;

-- Vérifier les clients après correction
SELECT 
    'Clients après correction' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    CASE 
        WHEN current_tier_id IS NULL THEN 'Aucun tier'
        WHEN current_tier_id IN (SELECT id FROM loyalty_tiers_advanced) THEN 'Tier valide'
        ELSE 'Tier invalide'
    END as tier_status
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Diagnostic simple effectué' as message;
SELECT '✅ Niveaux par défaut créés pour tous les utilisateurs' as niveaux;
SELECT '✅ Configuration par défaut créée pour tous les utilisateurs' as config;
SELECT '✅ Clients nettoyés (tier_id invalides supprimés)' as nettoyage;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Vérifiez l''interface après redéploiement' as note;
