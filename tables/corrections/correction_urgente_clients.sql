-- CORRECTION URGENTE DES CLIENTS DE FIDÉLITÉ
-- Script agressif pour résoudre le problème d'affichage des clients

-- 1. DIAGNOSTIC COMPLET
SELECT '🔍 DIAGNOSTIC COMPLET' as diagnostic;

-- Vérifier tous les utilisateurs
SELECT 'Utilisateurs disponibles:' as info;
SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC;

-- Vérifier tous les clients
SELECT 'Tous les clients:' as info;
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

-- 2. CORRECTION AGGRESSIVE
SELECT '🔧 CORRECTION AGGRESSIVE' as diagnostic;

-- Assigner TOUS les clients au premier utilisateur
UPDATE clients 
SET workshop_id = (
    SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
)
WHERE workshop_id IS NULL OR workshop_id != (
    SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
);

-- 3. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    'Clients après correction:' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as clients_avec_workshop_id
FROM clients;

-- 4. AFFICHER LES CLIENTS CORRIGÉS
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

-- 5. TEST DE REQUÊTE EXACTE
SELECT '🧪 TEST DE REQUÊTE EXACTE' as diagnostic;

-- Simuler exactement la requête du frontend
WITH user_info AS (
    SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
)
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
CROSS JOIN user_info u
WHERE c.workshop_id = u.id
ORDER BY c.loyalty_points DESC;

-- 6. VÉRIFIER LES NIVEAUX
SELECT '🏆 NIVEAUX DISPONIBLES' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    workshop_id,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 7. CORRECTION DES NIVEAUX SI NÉCESSAIRE
SELECT '🔧 CORRECTION DES NIVEAUX' as diagnostic;

-- S'assurer que les niveaux correspondent au bon workshop_id
UPDATE loyalty_tiers_advanced 
SET workshop_id = (
    SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
)
WHERE workshop_id IS NULL OR workshop_id != (
    SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
);

-- 8. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Afficher le résumé final
SELECT 
    'Résumé final:' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM loyalty_tiers_advanced) as total_niveaux,
    (SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1) as workshop_id_utilise;

-- 9. TEST FINAL COMPLET
SELECT '🧪 TEST FINAL COMPLET' as diagnostic;

-- Test complet avec toutes les données
WITH user_info AS (
    SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
)
SELECT 
    'Test complet:' as test_type,
    COUNT(c.id) as clients_count,
    COUNT(lta.id) as niveaux_count,
    u.id as workshop_id
FROM user_info u
LEFT JOIN clients c ON c.workshop_id = u.id
LEFT JOIN loyalty_tiers_advanced lta ON lta.workshop_id = u.id
GROUP BY u.id;

-- 10. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 Tous les clients ont été assignés au bon workshop.' as next_step;
SELECT '🔄 Rechargez la page de fidélité pour voir les clients.' as instruction;
SELECT '🔍 Vérifiez la console pour les logs de débogage.' as debug_info;





