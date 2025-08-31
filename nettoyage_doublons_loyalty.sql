-- NETTOYAGE DES DOUBLONS DANS LES TABLES DE FIDÉLITÉ
-- Script pour résoudre les problèmes de contraintes uniques

-- 1. VÉRIFIER LES DOUBLONS EXISTANTS
SELECT '🔍 VÉRIFICATION DES DOUBLONS' as diagnostic;

-- Vérifier les doublons dans loyalty_config
SELECT 
    key,
    COUNT(*) as count
FROM loyalty_config 
GROUP BY key
HAVING COUNT(*) > 1;

-- Vérifier les doublons dans loyalty_tiers_advanced
SELECT 
    name,
    COUNT(*) as count
FROM loyalty_tiers_advanced 
GROUP BY name
HAVING COUNT(*) > 1;

-- 2. NETTOYER LES DOUBLONS DANS LOYALTY_CONFIG
SELECT '🧹 NETTOYAGE LOYALTY_CONFIG' as diagnostic;

-- Supprimer les doublons en gardant le plus récent
DELETE FROM loyalty_config 
WHERE id NOT IN (
    SELECT MAX(id)
    FROM loyalty_config 
    GROUP BY key
);

-- 3. NETTOYER LES DOUBLONS DANS LOYALTY_TIERS_ADVANCED
SELECT '🧹 NETTOYAGE LOYALTY_TIERS_ADVANCED' as diagnostic;

-- Supprimer les doublons en gardant le plus récent
DELETE FROM loyalty_tiers_advanced 
WHERE id NOT IN (
    SELECT MAX(id)
    FROM loyalty_tiers_advanced 
    GROUP BY name
);

-- 4. VÉRIFIER APRÈS NETTOYAGE
SELECT '✅ VÉRIFICATION APRÈS NETTOYAGE' as diagnostic;

-- Vérifier qu'il n'y a plus de doublons
SELECT 
    'loyalty_config:' as table_name,
    COUNT(*) as total_records
FROM loyalty_config;

SELECT 
    'loyalty_tiers_advanced:' as table_name,
    COUNT(*) as total_records
FROM loyalty_tiers_advanced;

-- 5. ASSIGNER WORKSHOP_ID AUX ENREGISTREMENTS MANQUANTS
SELECT '🔧 ASSIGNATION WORKSHOP_ID' as diagnostic;

-- Assigner workshop_id aux enregistrements qui n'en ont pas
UPDATE loyalty_config 
SET workshop_id = (SELECT id FROM auth.users LIMIT 1)
WHERE workshop_id IS NULL;

UPDATE loyalty_tiers_advanced 
SET workshop_id = (SELECT id FROM auth.users LIMIT 1)
WHERE workshop_id IS NULL;

-- 6. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Afficher les données finales
SELECT 
    'Configuration finale:' as info,
    key,
    value,
    workshop_id
FROM loyalty_config 
ORDER BY key;

SELECT 
    'Niveaux finaux:' as info,
    name,
    points_required,
    discount_percentage,
    workshop_id
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 7. MESSAGE DE CONFIRMATION
SELECT '🎉 NETTOYAGE TERMINÉ !' as result;
SELECT '📋 Les doublons ont été supprimés.' as next_step;
SELECT '🔄 Vous pouvez maintenant exécuter le script de création des fonctions.' as instruction;


