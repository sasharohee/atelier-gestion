-- =====================================================
-- CORRECTION SYNCHRONISATION CONFIG LOYALTY
-- =====================================================
-- Script pour corriger l'incohérence entre les paramètres et les niveaux
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC des incohérences
SELECT '=== DIAGNOSTIC INCOHÉRENCES ===' as etape;

-- Vérifier les configurations
SELECT 
    'Configurations' as info,
    workshop_id,
    key,
    value,
    description,
    updated_at
FROM loyalty_config 
ORDER BY workshop_id, key;

-- Vérifier les niveaux de fidélité
SELECT 
    'Niveaux de fidélité' as info,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    is_active,
    updated_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 2. COMPARER les configurations et les niveaux
SELECT '=== COMPARAISON CONFIGURATIONS ET NIVEAUX ===' as etape;

-- Vérifier les points par euro configurés vs utilisés
SELECT 
    'Points par euro' as info,
    lc.workshop_id,
    lc.value as config_points_per_euro,
    COUNT(lt.name) as nombre_niveaux,
    STRING_AGG(lt.name, ', ') as noms_niveaux
FROM loyalty_config lc
LEFT JOIN loyalty_tiers_advanced lt ON lc.workshop_id = lt.workshop_id
WHERE lc.key = 'points_per_euro'
GROUP BY lc.workshop_id, lc.value
ORDER BY lc.workshop_id;

-- Vérifier les seuils de bonus configurés vs utilisés
SELECT 
    'Seuils de bonus' as info,
    lc.workshop_id,
    lc.value as config_bonus_threshold,
    COUNT(lt.name) as nombre_niveaux,
    STRING_AGG(lt.name, ', ') as noms_niveaux
FROM loyalty_config lc
LEFT JOIN loyalty_tiers_advanced lt ON lc.workshop_id = lt.workshop_id
WHERE lc.key = 'bonus_threshold'
GROUP BY lc.workshop_id, lc.value
ORDER BY lc.workshop_id;

-- 3. VÉRIFIER les clients et leurs points
SELECT '=== CLIENTS ET LEURS POINTS ===' as etape;

SELECT 
    'Clients avec points' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required as tier_points_required
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 4. CRÉER un rapport de cohérence
SELECT '=== RAPPORT DE COHÉRENCE ===' as etape;

-- Rapport détaillé des configurations et niveaux
SELECT 
    'Rapport de cohérence' as info,
    lc.workshop_id,
    lc.key as config_key,
    lc.value as config_value,
    lc.description as config_description,
    COUNT(lt.name) as nombre_niveaux,
    STRING_AGG(lt.name, ', ') as noms_niveaux
FROM loyalty_config lc
LEFT JOIN loyalty_tiers_advanced lt ON lc.workshop_id = lt.workshop_id
GROUP BY lc.workshop_id, lc.key, lc.value, lc.description
ORDER BY lc.workshop_id, lc.key;

-- 5. VÉRIFIER les incohérences spécifiques
SELECT '=== VÉRIFICATION INCOHÉRENCES SPÉCIFIQUES ===' as etape;

-- Vérifier si les points par euro sont cohérents
SELECT 
    'Incohérences points par euro' as info,
    lc.workshop_id,
    lc.value as config_points_per_euro,
    COUNT(lt.name) as nombre_niveaux,
    CASE 
        WHEN lc.value::integer = 1 AND COUNT(lt.name) = 5 THEN '✅ Cohérent'
        WHEN lc.value::integer != 1 THEN '⚠️ Points par euro différent de 1'
        WHEN COUNT(lt.name) != 5 THEN '⚠️ Nombre de niveaux incorrect'
        ELSE '❌ Incohérent'
    END as coherence_status
FROM loyalty_config lc
LEFT JOIN loyalty_tiers_advanced lt ON lc.workshop_id = lt.workshop_id
WHERE lc.key = 'points_per_euro'
GROUP BY lc.workshop_id, lc.value
ORDER BY lc.workshop_id;

-- 6. CORRIGER les incohérences si nécessaire
SELECT '=== CORRECTION INCOHÉRENCES ===' as etape;

-- Mettre à jour les configurations pour qu'elles soient cohérentes
UPDATE loyalty_config 
SET value = '1',
    updated_at = NOW()
WHERE key = 'points_per_euro' 
AND value != '1';

-- Mettre à jour les seuils de bonus pour qu'ils soient cohérents
UPDATE loyalty_config 
SET value = '100',
    updated_at = NOW()
WHERE key = 'bonus_threshold' 
AND value != '100';

-- Mettre à jour les multiplicateurs de bonus pour qu'ils soient cohérents
UPDATE loyalty_config 
SET value = '1.5',
    updated_at = NOW()
WHERE key = 'bonus_multiplier' 
AND value != '1.5';

-- 7. VÉRIFICATION après correction
SELECT '=== VÉRIFICATION APRÈS CORRECTION ===' as etape;

-- Vérifier les configurations après correction
SELECT 
    'Configurations après correction' as info,
    workshop_id,
    key,
    value,
    description,
    updated_at
FROM loyalty_config 
ORDER BY workshop_id, key;

-- 8. CRÉER un rapport final
SELECT '=== RAPPORT FINAL ===' as etape;

-- Rapport final des configurations et niveaux
SELECT 
    'Rapport final' as info,
    lc.workshop_id,
    lc.key as config_key,
    lc.value as config_value,
    lc.description as config_description,
    COUNT(lt.name) as nombre_niveaux,
    STRING_AGG(lt.name, ', ') as noms_niveaux,
    CASE 
        WHEN lc.key = 'points_per_euro' AND lc.value = '1' AND COUNT(lt.name) = 5 THEN '✅ Cohérent'
        WHEN lc.key = 'bonus_threshold' AND lc.value = '100' AND COUNT(lt.name) = 5 THEN '✅ Cohérent'
        WHEN lc.key = 'bonus_multiplier' AND lc.value = '1.5' AND COUNT(lt.name) = 5 THEN '✅ Cohérent'
        ELSE '⚠️ À vérifier'
    END as coherence_status
FROM loyalty_config lc
LEFT JOIN loyalty_tiers_advanced lt ON lc.workshop_id = lt.workshop_id
GROUP BY lc.workshop_id, lc.key, lc.value, lc.description
ORDER BY lc.workshop_id, lc.key;

-- 9. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Diagnostic des incohérences effectué' as message;
SELECT '✅ Configurations corrigées' as correction;
SELECT '✅ Rapport de cohérence créé' as rapport;
SELECT '✅ Vérification après correction effectuée' as verification;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les paramètres et niveaux devraient maintenant être cohérents' as note;
SELECT '💡 Videz le cache du navigateur si nécessaire' as cache;
