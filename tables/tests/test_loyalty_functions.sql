-- =====================================================
-- TEST DES FONCTIONS LOYALTY
-- =====================================================
-- Script pour tester directement les fonctions RPC
-- Date: 2025-01-23
-- =====================================================

-- 1. TEST des fonctions RPC
SELECT '=== TEST FONCTIONS RPC ===' as etape;

-- Test de la fonction get_workshop_loyalty_tiers
SELECT 'Test get_workshop_loyalty_tiers' as test_name;
SELECT * FROM get_workshop_loyalty_tiers();

-- Test de la fonction get_workshop_loyalty_config
SELECT 'Test get_workshop_loyalty_config' as test_name;
SELECT * FROM get_workshop_loyalty_config();

-- 2. VÉRIFICATION des données directes
SELECT '=== VÉRIFICATION DONNÉES DIRECTES ===' as etape;

-- Vérifier les niveaux directement
SELECT 
    'Niveaux directs' as info,
    id,
    name,
    points_required,
    discount_percentage,
    color,
    description,
    is_active,
    workshop_id
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- Vérifier les configurations directement
SELECT 
    'Configurations directes' as info,
    id,
    key,
    value,
    description,
    workshop_id
FROM loyalty_config 
ORDER BY key;

-- 3. CRÉER des données de test si nécessaire
SELECT '=== CRÉATION DONNÉES DE TEST ===' as etape;

-- Créer des niveaux de test pour l'utilisateur actuel
INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    auth.uid(),
    'Bronze',
    0,
    0.00,
    '#CD7F32',
    'Niveau de base',
    true
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced 
    WHERE workshop_id = auth.uid() 
    AND name = 'Bronze'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    auth.uid(),
    'Argent',
    100,
    5.00,
    '#C0C0C0',
    '5% de réduction',
    true
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced 
    WHERE workshop_id = auth.uid() 
    AND name = 'Argent'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    auth.uid(),
    'Or',
    500,
    10.00,
    '#FFD700',
    '10% de réduction',
    true
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced 
    WHERE workshop_id = auth.uid() 
    AND name = 'Or'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    auth.uid(),
    'Platine',
    1000,
    15.00,
    '#E5E4E2',
    '15% de réduction',
    true
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced 
    WHERE workshop_id = auth.uid() 
    AND name = 'Platine'
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    auth.uid(),
    'Diamant',
    2000,
    20.00,
    '#B9F2FF',
    '20% de réduction',
    true
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced 
    WHERE workshop_id = auth.uid() 
    AND name = 'Diamant'
);

-- Créer des configurations de test pour l'utilisateur actuel
INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    auth.uid(),
    'points_per_euro',
    '1',
    'Points gagnés par euro dépensé'
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config 
    WHERE workshop_id = auth.uid() 
    AND key = 'points_per_euro'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    auth.uid(),
    'minimum_purchase',
    '10',
    'Montant minimum pour gagner des points'
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config 
    WHERE workshop_id = auth.uid() 
    AND key = 'minimum_purchase'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    auth.uid(),
    'bonus_threshold',
    '100',
    'Seuil pour bonus de points'
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config 
    WHERE workshop_id = auth.uid() 
    AND key = 'bonus_threshold'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    auth.uid(),
    'bonus_multiplier',
    '1.5',
    'Multiplicateur de bonus'
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config 
    WHERE workshop_id = auth.uid() 
    AND key = 'bonus_multiplier'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    auth.uid(),
    'points_expiry_days',
    '365',
    'Durée de validité des points en jours'
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config 
    WHERE workshop_id = auth.uid() 
    AND key = 'points_expiry_days'
);

INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    auth.uid(),
    'auto_tier_upgrade',
    'true',
    'Mise à jour automatique des niveaux de fidélité'
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM loyalty_config 
    WHERE workshop_id = auth.uid() 
    AND key = 'auto_tier_upgrade'
);

-- 4. TEST FINAL des fonctions
SELECT '=== TEST FINAL ===' as etape;

-- Test final de la fonction get_workshop_loyalty_tiers
SELECT 'Test final get_workshop_loyalty_tiers' as test_name;
SELECT * FROM get_workshop_loyalty_tiers();

-- Test final de la fonction get_workshop_loyalty_config
SELECT 'Test final get_workshop_loyalty_config' as test_name;
SELECT * FROM get_workshop_loyalty_config();

-- 5. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les niveaux après création
SELECT 
    'Niveaux après création' as info,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as names
FROM loyalty_tiers_advanced 
WHERE workshop_id = auth.uid();

-- Vérifier les configurations après création
SELECT 
    'Configurations après création' as info,
    COUNT(*) as count,
    STRING_AGG(key, ', ') as keys
FROM loyalty_config 
WHERE workshop_id = auth.uid();

-- 6. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Fonctions RPC testées' as message;
SELECT '✅ Données de test créées' as creation;
SELECT '✅ Niveaux et configurations disponibles' as disponibilite;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les niveaux devraient maintenant s''afficher dans l''interface' as note;
