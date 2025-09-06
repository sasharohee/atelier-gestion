-- NETTOYAGE DES DOUBLONS DANS LES NIVEAUX DE FIDÉLITÉ
-- Script pour corriger l'affichage des niveaux en double

-- 1. DIAGNOSTIC DES DOUBLONS
SELECT '🔍 DIAGNOSTIC DES DOUBLONS' as diagnostic;

-- Vérifier les doublons dans loyalty_tiers_advanced
SELECT 
    name,
    points_required,
    workshop_id,
    COUNT(*) as count
FROM loyalty_tiers_advanced 
GROUP BY name, points_required, workshop_id
HAVING COUNT(*) > 1
ORDER BY name, points_required;

-- 2. AFFICHER TOUS LES NIVEAUX ACTUELS
SELECT '📊 NIVEAUX ACTUELS' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    workshop_id,
    created_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 3. NETTOYER LES DOUBLONS
SELECT '🧹 NETTOYAGE DES DOUBLONS' as diagnostic;

-- Supprimer les doublons en gardant le plus récent par (workshop_id, name)
DELETE FROM loyalty_tiers_advanced 
WHERE id NOT IN (
    SELECT DISTINCT ON (workshop_id, name) id
    FROM loyalty_tiers_advanced 
    ORDER BY workshop_id, name, created_at DESC
);

-- 4. VÉRIFIER APRÈS NETTOYAGE
SELECT '✅ VÉRIFICATION APRÈS NETTOYAGE' as diagnostic;

-- Vérifier qu'il n'y a plus de doublons
SELECT 
    name,
    points_required,
    workshop_id,
    COUNT(*) as count
FROM loyalty_tiers_advanced 
GROUP BY name, points_required, workshop_id
HAVING COUNT(*) > 1;

-- 5. AFFICHER LES NIVEAUX FINAUX
SELECT '📊 NIVEAUX FINAUX' as diagnostic;

SELECT 
    name,
    points_required,
    discount_percentage,
    color,
    workshop_id
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 6. CRÉER DES NIVEAUX PAR DÉFAUT SI NÉCESSAIRE
SELECT '🏗️ CRÉATION DES NIVEAUX PAR DÉFAUT' as diagnostic;

-- Vérifier quels utilisateurs n'ont pas de niveaux
SELECT 
    u.id as user_id,
    u.email,
    COUNT(lta.id) as tiers_count
FROM auth.users u
LEFT JOIN loyalty_tiers_advanced lta ON u.id = lta.workshop_id
GROUP BY u.id, u.email
HAVING COUNT(lta.id) = 0;

-- Créer les niveaux par défaut pour les utilisateurs qui n'en ont pas
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
) AS tier(name, points_required, discount_percentage, color, description, is_active)
WHERE NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta WHERE lta.workshop_id = u.id
);

-- 7. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Afficher le résumé final
SELECT 
    'Résumé final:' as info,
    COUNT(*) as total_niveaux,
    COUNT(DISTINCT workshop_id) as ateliers_avec_niveaux
FROM loyalty_tiers_advanced;

-- Afficher les niveaux par atelier
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
SELECT '📋 Les doublons ont été supprimés.' as next_step;
SELECT '🔄 Rafraîchissez la page pour voir les changements.' as instruction;





