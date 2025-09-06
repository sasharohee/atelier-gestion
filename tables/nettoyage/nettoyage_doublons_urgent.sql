-- NETTOYAGE URGENT DES DOUBLONS
-- Script pour nettoyer les doublons avant correction des clients

-- 1. DIAGNOSTIC DES DOUBLONS
SELECT '🔍 DIAGNOSTIC DES DOUBLONS' as diagnostic;

-- Vérifier les doublons dans loyalty_tiers_advanced
SELECT 
    workshop_id,
    name,
    COUNT(*) as doublons
FROM loyalty_tiers_advanced 
GROUP BY workshop_id, name
HAVING COUNT(*) > 1
ORDER BY doublons DESC;

-- 2. AFFICHER TOUS LES NIVEAUX
SELECT '📊 TOUS LES NIVEAUX' as diagnostic;

SELECT 
    id,
    workshop_id,
    name,
    points_required,
    created_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, name, created_at;

-- 3. NETTOYAGE AGGRESSIF
SELECT '🧹 NETTOYAGE AGGRESSIF' as diagnostic;

-- Supprimer TOUS les niveaux existants
TRUNCATE TABLE loyalty_tiers_advanced CASCADE;

-- 4. CRÉATION DES NIVEAUX PROPRES
SELECT '🏗️ CRÉATION DES NIVEAUX PROPRES' as diagnostic;

-- Créer les niveaux par défaut pour chaque utilisateur
INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    u.id,
    tier.name,
    tier.points_required,
    tier.discount_percentage,
    tier.color,
    tier.description,
    tier.is_active
FROM auth.users u
CROSS JOIN (VALUES 
    ('Bronze', 0, 0, '#CD7F32', 'Niveau de base', true),
    ('Argent', 100, 5, '#C0C0C0', '5% de réduction', true),
    ('Or', 500, 10, '#FFD700', '10% de réduction', true),
    ('Platine', 1000, 15, '#E5E4E2', '15% de réduction', true),
    ('Diamant', 2000, 20, '#B9F2FF', '20% de réduction', true)
) AS tier(name, points_required, discount_percentage, color, description, is_active);

-- 5. VÉRIFICATION APRÈS NETTOYAGE
SELECT '✅ VÉRIFICATION APRÈS NETTOYAGE' as diagnostic;

-- Vérifier qu'il n'y a plus de doublons
SELECT 
    workshop_id,
    name,
    COUNT(*) as count
FROM loyalty_tiers_advanced 
GROUP BY workshop_id, name
HAVING COUNT(*) > 1;

-- 6. AFFICHER LES NIVEAUX FINAUX
SELECT '📊 NIVEAUX FINAUX' as diagnostic;

SELECT 
    workshop_id,
    name,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 7. RÉSUMÉ FINAL
SELECT '📋 RÉSUMÉ FINAL' as diagnostic;

SELECT 
    'Niveaux par atelier:' as info,
    workshop_id,
    COUNT(*) as niveaux_count,
    STRING_AGG(name, ', ' ORDER BY points_required) as niveaux
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

-- 8. MESSAGE DE CONFIRMATION
SELECT '🎉 NETTOYAGE TERMINÉ !' as result;
SELECT '📋 Tous les doublons ont été supprimés.' as next_step;
SELECT '🔄 Vous pouvez maintenant exécuter le script de correction des clients.' as instruction;





