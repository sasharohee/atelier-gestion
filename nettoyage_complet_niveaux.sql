-- NETTOYAGE COMPLET DES NIVEAUX DE FIDÉLITÉ
-- Script agressif pour éliminer tous les doublons

-- 1. DIAGNOSTIC COMPLET
SELECT '🔍 DIAGNOSTIC COMPLET' as diagnostic;

-- Compter tous les niveaux
SELECT 
    'Total niveaux:' as info,
    COUNT(*) as total,
    COUNT(DISTINCT workshop_id) as ateliers_uniques,
    COUNT(DISTINCT name) as noms_uniques
FROM loyalty_tiers_advanced;

-- Voir tous les doublons
SELECT 
    name,
    workshop_id,
    COUNT(*) as doublons
FROM loyalty_tiers_advanced 
GROUP BY name, workshop_id
HAVING COUNT(*) > 1
ORDER BY doublons DESC;

-- 2. NETTOYAGE AGGRESSIF
SELECT '🧹 NETTOYAGE AGGRESSIF' as diagnostic;

-- Supprimer TOUS les niveaux existants
TRUNCATE TABLE loyalty_tiers_advanced CASCADE;

-- 3. CRÉATION DES NIVEAUX PROPRES
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

-- 4. VÉRIFICATION APRÈS NETTOYAGE
SELECT '✅ VÉRIFICATION APRÈS NETTOYAGE' as diagnostic;

-- Compter les niveaux après nettoyage
SELECT 
    'Niveaux après nettoyage:' as info,
    COUNT(*) as total,
    COUNT(DISTINCT workshop_id) as ateliers,
    COUNT(DISTINCT name) as noms_uniques
FROM loyalty_tiers_advanced;

-- Vérifier qu'il n'y a plus de doublons
SELECT 
    name,
    workshop_id,
    COUNT(*) as count
FROM loyalty_tiers_advanced 
GROUP BY name, workshop_id
HAVING COUNT(*) > 1;

-- 5. AFFICHER LES NIVEAUX FINAUX
SELECT '📊 NIVEAUX FINAUX' as diagnostic;

SELECT 
    workshop_id,
    name,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 6. RÉSUMÉ PAR ATELIER
SELECT '📋 RÉSUMÉ PAR ATELIER' as diagnostic;

SELECT 
    workshop_id,
    COUNT(*) as niveaux_count,
    STRING_AGG(name, ', ' ORDER BY points_required) as niveaux
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

-- 7. CORRECTION DES CLIENTS
SELECT '🔧 CORRECTION DES CLIENTS' as diagnostic;

-- Mettre à jour les current_tier_id des clients
UPDATE clients 
SET current_tier_id = (
    SELECT lta.id 
    FROM loyalty_tiers_advanced lta 
    WHERE lta.workshop_id = clients.workshop_id 
    AND lta.name = 'Bronze'
    LIMIT 1
)
WHERE current_tier_id IS NULL 
AND workshop_id IS NOT NULL;

-- 8. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Vérifier les clients et leurs niveaux
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.workshop_id IS NOT NULL
ORDER BY c.workshop_id, c.loyalty_points DESC;

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 NETTOYAGE COMPLET TERMINÉ !' as result;
SELECT '📋 Tous les doublons ont été supprimés.' as next_step;
SELECT '🔄 Rafraîchissez la page pour voir les changements.' as instruction;
SELECT '📊 Vous devriez maintenant voir 5 niveaux par atelier.' as expected;
