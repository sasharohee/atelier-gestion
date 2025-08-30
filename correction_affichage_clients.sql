-- CORRECTION DE L'AFFICHAGE DES CLIENTS DANS LA FIDÉLITÉ
-- Diagnostique et corrige le problème d'affichage des clients

-- 1. DIAGNOSTIC DES CLIENTS
SELECT '🔍 DIAGNOSTIC DES CLIENTS' as diagnostic;

-- Vérifier tous les clients
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as clients_avec_workshop_id
FROM clients;

-- 2. VÉRIFIER LES CLIENTS AVEC POINTS
SELECT '👤 CLIENTS AVEC POINTS' as diagnostic;

SELECT 
    id,
    first_name,
    last_name,
    email,
    loyalty_points,
    workshop_id,
    current_tier_id
FROM clients 
WHERE loyalty_points > 0
ORDER BY loyalty_points DESC;

-- 3. VÉRIFIER L'UTILISATEUR ACTUEL
SELECT '👤 UTILISATEUR ACTUEL' as diagnostic;

SELECT 
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 4. ASSIGNER WORKSHOP_ID AUX CLIENTS MANQUANTS
SELECT '🔧 ASSIGNATION DES WORKSHOP_ID' as diagnostic;

-- Assigner workshop_id aux clients qui n'en ont pas
UPDATE clients 
SET workshop_id = (SELECT id FROM auth.users LIMIT 1)
WHERE workshop_id IS NULL;

-- 5. VÉRIFIER APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as clients_avec_workshop_id
FROM clients;

-- 6. AFFICHER LES CLIENTS QUI DEVRAIENT APPARAÎTRE
SELECT '📊 CLIENTS QUI DEVRAIENT APPARAÎTRE' as diagnostic;

SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.workshop_id,
    c.current_tier_id,
    lt.name as niveau_nom
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 7. VÉRIFIER LES NIVEAUX DISPONIBLES
SELECT '🏆 NIVEAUX DISPONIBLES' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    is_active,
    workshop_id
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 8. CORRIGER LES NIVEAUX DES CLIENTS
SELECT '🔧 CORRECTION DES NIVEAUX' as diagnostic;

-- Mettre à jour les niveaux des clients
UPDATE clients 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers_advanced 
    WHERE points_required <= clients.loyalty_points 
    AND is_active = true
    ORDER BY points_required DESC 
    LIMIT 1
)
WHERE loyalty_points > 0;

-- 9. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    lt.name as niveau_actuel,
    lt.points_required,
    lt.discount_percentage
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 10. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 Les clients devraient maintenant apparaître dans la page de fidélité.' as next_step;
SELECT '🔄 Rafraîchissez la page pour voir les changements.' as instruction;
