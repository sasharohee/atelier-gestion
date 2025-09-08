-- =====================================================
-- CORRECTION DIRECTE LOYALTY
-- =====================================================
-- Script pour corriger directement les données sans fonctions RPC
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC de l'état actuel
SELECT '=== DIAGNOSTIC ÉTAT ACTUEL ===' as etape;

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

-- 2. AFFICHER les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as etape;

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

-- Afficher toutes les configurations
SELECT 
    'Toutes les configurations' as info,
    workshop_id,
    key,
    value,
    description
FROM loyalty_config 
ORDER BY workshop_id, key;

-- 3. CRÉER des données pour tous les utilisateurs existants
SELECT '=== CRÉATION DONNÉES POUR TOUS LES UTILISATEURS ===' as etape;

-- Créer des niveaux par défaut pour tous les utilisateurs qui n'en ont pas
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

-- Créer des configurations par défaut pour tous les utilisateurs qui n'en ont pas
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

-- 4. CRÉER des données pour les utilisateurs qui n'ont aucune donnée
SELECT '=== CRÉATION DONNÉES POUR NOUVEAUX UTILISATEURS ===' as etape;

-- Créer des niveaux par défaut pour les utilisateurs qui n'ont aucune donnée
INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    au.id,
    'Bronze',
    0,
    0.00,
    '#CD7F32',
    'Niveau de base',
    true
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    au.id,
    'Argent',
    100,
    5.00,
    '#C0C0C0',
    '5% de réduction',
    true
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    au.id,
    'Or',
    500,
    10.00,
    '#FFD700',
    '10% de réduction',
    true
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    au.id,
    'Platine',
    1000,
    15.00,
    '#E5E4E2',
    '15% de réduction',
    true
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    au.id,
    'Diamant',
    2000,
    20.00,
    '#B9F2FF',
    '20% de réduction',
    true
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

-- Créer des configurations par défaut pour les utilisateurs qui n'ont aucune donnée
INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    au.id,
    'points_per_euro',
    '1',
    'Points gagnés par euro dépensé'
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    au.id,
    'minimum_purchase',
    '10',
    'Montant minimum pour gagner des points'
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    au.id,
    'bonus_threshold',
    '100',
    'Seuil pour bonus de points'
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    au.id,
    'bonus_multiplier',
    '1.5',
    'Multiplicateur de bonus'
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    au.id,
    'points_expiry_days',
    '365',
    'Durée de validité des points en jours'
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    au.id,
    'auto_tier_upgrade',
    'true',
    'Mise à jour automatique des niveaux de fidélité'
FROM auth.users au
WHERE au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_tiers_advanced WHERE workshop_id IS NOT NULL)
AND au.id NOT IN (SELECT DISTINCT workshop_id FROM loyalty_config WHERE workshop_id IS NOT NULL);

-- 5. NETTOYER les clients avec des tier_id invalides
SELECT '=== NETTOYAGE CLIENTS ===' as etape;

-- Supprimer les current_tier_id qui ne correspondent à aucun tier existant
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL 
AND current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

-- 6. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les niveaux après création
SELECT 
    'Niveaux après création' as info,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as names
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

-- Vérifier les configurations après création
SELECT 
    'Configurations après création' as info,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(key, ', ') as keys
FROM loyalty_config 
GROUP BY workshop_id
ORDER BY workshop_id;

-- Vérifier les clients après nettoyage
SELECT 
    'Clients après nettoyage' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_with_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_with_tier_id
FROM clients;

-- 7. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Données créées pour tous les utilisateurs' as message;
SELECT '✅ Niveaux par défaut créés' as niveaux;
SELECT '✅ Configuration par défaut créée' as config;
SELECT '✅ Clients nettoyés (tier_id invalides supprimés)' as nettoyage;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les niveaux devraient maintenant s''afficher dans l''interface' as note;
