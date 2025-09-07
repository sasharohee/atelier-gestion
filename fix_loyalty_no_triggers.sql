-- =====================================================
-- CORRECTION LOYALTY SANS TRIGGERS
-- =====================================================
-- Script pour corriger les données en désactivant temporairement les triggers
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

-- 2. DÉSACTIVER temporairement les triggers
SELECT '=== DÉSACTIVATION TRIGGERS ===' as etape;

-- Désactiver les triggers sur loyalty_tiers_advanced
ALTER TABLE loyalty_tiers_advanced DISABLE TRIGGER ALL;

-- Désactiver les triggers sur loyalty_config
ALTER TABLE loyalty_config DISABLE TRIGGER ALL;

-- 3. NETTOYER les données existantes
SELECT '=== NETTOYAGE DONNÉES EXISTANTES ===' as etape;

-- Supprimer toutes les données existantes
DELETE FROM loyalty_tiers_advanced;
DELETE FROM loyalty_config;

-- Vérifier que les tables sont vides
SELECT 'loyalty_tiers_advanced' as table_name, COUNT(*) as count FROM loyalty_tiers_advanced
UNION ALL
SELECT 'loyalty_config' as table_name, COUNT(*) as count FROM loyalty_config;

-- 4. CRÉER des données pour tous les utilisateurs
SELECT '=== CRÉATION DONNÉES POUR TOUS LES UTILISATEURS ===' as etape;

-- Créer des niveaux par défaut pour tous les utilisateurs
INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active, created_at, updated_at)
SELECT 
    au.id,
    'Bronze',
    0,
    0.00,
    '#CD7F32',
    'Niveau de base',
    true,
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active, created_at, updated_at)
SELECT 
    au.id,
    'Argent',
    100,
    5.00,
    '#C0C0C0',
    '5% de réduction',
    true,
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active, created_at, updated_at)
SELECT 
    au.id,
    'Or',
    500,
    10.00,
    '#FFD700',
    '10% de réduction',
    true,
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active, created_at, updated_at)
SELECT 
    au.id,
    'Platine',
    1000,
    15.00,
    '#E5E4E2',
    '15% de réduction',
    true,
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active, created_at, updated_at)
SELECT 
    au.id,
    'Diamant',
    2000,
    20.00,
    '#B9F2FF',
    '20% de réduction',
    true,
    NOW(),
    NOW()
FROM auth.users au;

-- Créer des configurations par défaut pour tous les utilisateurs
INSERT INTO loyalty_config (workshop_id, key, value, description, created_at, updated_at)
SELECT 
    au.id,
    'points_per_euro',
    '1',
    'Points gagnés par euro dépensé',
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_config (workshop_id, key, value, description, created_at, updated_at)
SELECT 
    au.id,
    'minimum_purchase',
    '10',
    'Montant minimum pour gagner des points',
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_config (workshop_id, key, value, description, created_at, updated_at)
SELECT 
    au.id,
    'bonus_threshold',
    '100',
    'Seuil pour bonus de points',
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_config (workshop_id, key, value, description, created_at, updated_at)
SELECT 
    au.id,
    'bonus_multiplier',
    '1.5',
    'Multiplicateur de bonus',
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_config (workshop_id, key, value, description, created_at, updated_at)
SELECT 
    au.id,
    'points_expiry_days',
    '365',
    'Durée de validité des points en jours',
    NOW(),
    NOW()
FROM auth.users au;

INSERT INTO loyalty_config (workshop_id, key, value, description, created_at, updated_at)
SELECT 
    au.id,
    'auto_tier_upgrade',
    'true',
    'Mise à jour automatique des niveaux de fidélité',
    NOW(),
    NOW()
FROM auth.users au;

-- 5. NETTOYER les clients avec des tier_id invalides
SELECT '=== NETTOYAGE CLIENTS ===' as etape;

-- Supprimer les current_tier_id qui ne correspondent à aucun tier existant
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL 
AND current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

-- 6. RÉACTIVER les triggers
SELECT '=== RÉACTIVATION TRIGGERS ===' as etape;

-- Réactiver les triggers sur loyalty_tiers_advanced
ALTER TABLE loyalty_tiers_advanced ENABLE TRIGGER ALL;

-- Réactiver les triggers sur loyalty_config
ALTER TABLE loyalty_config ENABLE TRIGGER ALL;

-- 7. VÉRIFICATION FINALE
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

-- 8. TEST des politiques RLS
SELECT '=== TEST POLITIQUES RLS ===' as etape;

-- Vérifier les politiques
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict OK'
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '⚠️ Strict OK'
        ELSE '❌ Isolation manquante'
    END as isolation_status
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename, policyname;

-- 9. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Triggers désactivés temporairement' as message;
SELECT '✅ Données créées pour tous les utilisateurs' as creation;
SELECT '✅ Niveaux par défaut créés' as niveaux;
SELECT '✅ Configuration par défaut créée' as config;
SELECT '✅ Clients nettoyés (tier_id invalides supprimés)' as nettoyage;
SELECT '✅ Triggers réactivés' as triggers;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les niveaux devraient maintenant s''afficher dans l''interface' as note;
