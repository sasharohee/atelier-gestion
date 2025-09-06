-- DIAGNOSTIC DES CLIENTS DE FIDÉLITÉ
-- Script pour identifier pourquoi les clients ne s'affichent pas

-- 1. VÉRIFIER L'UTILISATEUR ACTUEL
SELECT '🔍 UTILISATEUR ACTUEL' as diagnostic;

SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 2. VÉRIFIER LES CLIENTS ET LEUR WORKSHOP_ID
SELECT '📊 CLIENTS ET WORKSHOP_ID' as diagnostic;

SELECT 
    id,
    first_name,
    last_name,
    email,
    loyalty_points,
    current_tier_id,
    workshop_id,
    created_at
FROM clients 
ORDER BY created_at DESC;

-- 3. VÉRIFIER LES CLIENTS SANS WORKSHOP_ID
SELECT '⚠️ CLIENTS SANS WORKSHOP_ID' as diagnostic;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as clients_sans_workshop_id,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as clients_avec_workshop_id
FROM clients;

-- 4. AFFICHER LES CLIENTS SANS WORKSHOP_ID
SELECT '📋 CLIENTS SANS WORKSHOP_ID' as diagnostic;

SELECT 
    id,
    first_name,
    last_name,
    email,
    loyalty_points,
    current_tier_id,
    workshop_id
FROM clients 
WHERE workshop_id IS NULL
ORDER BY created_at DESC;

-- 5. VÉRIFIER LES NIVEAUX DE FIDÉLITÉ
SELECT '🏆 NIVEAUX DE FIDÉLITÉ' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    workshop_id,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 6. CORRECTION : ASSIGNER WORKSHOP_ID AUX CLIENTS
SELECT '🔧 CORRECTION DES CLIENTS' as diagnostic;

-- Assigner workshop_id aux clients qui n'en ont pas
UPDATE clients 
SET workshop_id = (
    SELECT u.id 
    FROM auth.users u 
    ORDER BY u.created_at DESC 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- 7. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as clients_sans_workshop_id,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as clients_avec_workshop_id
FROM clients;

-- 8. AFFICHER LES CLIENTS CORRIGÉS
SELECT '📊 CLIENTS CORRIGÉS' as diagnostic;

SELECT 
    id,
    first_name,
    last_name,
    email,
    loyalty_points,
    current_tier_id,
    workshop_id
FROM clients 
ORDER BY loyalty_points DESC, created_at DESC;

-- 9. TEST DE REQUÊTE SIMULÉE
SELECT '🧪 TEST DE REQUÊTE' as diagnostic;

-- Simuler la requête du frontend
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id,
    lta.name as tier_name
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.workshop_id = (
    SELECT u.id 
    FROM auth.users u 
    ORDER BY u.created_at DESC 
    LIMIT 1
)
ORDER BY c.loyalty_points DESC;

-- 10. MESSAGE DE CONFIRMATION
SELECT '🎉 DIAGNOSTIC TERMINÉ !' as result;
SELECT '📋 Les clients ont été corrigés.' as next_step;
SELECT '🔄 Rechargez la page de fidélité pour voir les clients.' as instruction;





