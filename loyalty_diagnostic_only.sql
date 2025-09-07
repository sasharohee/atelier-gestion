-- =====================================================
-- DIAGNOSTIC LOYALTY SEULEMENT
-- =====================================================
-- Script pour diagnostiquer les problèmes sans faire de mises à jour
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC COMPLET DES DONNÉES
SELECT '=== DIAGNOSTIC COMPLET DES DONNÉES ===' as etape;

-- Vérifier les points des clients
SELECT 
    'Points des clients' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    updated_at
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

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

-- 2. VÉRIFICATION DES INCOHÉRENCES
SELECT '=== VÉRIFICATION DES INCOHÉRENCES ===' as etape;

-- Vérifier les clients avec des tier_id invalides
SELECT 
    'Clients avec tier_id invalides' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id
FROM clients c
WHERE c.current_tier_id IS NOT NULL 
AND c.current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

-- Vérifier les clients avec des points mais pas de tier
SELECT 
    'Clients avec points mais pas de tier' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id
FROM clients c
WHERE c.loyalty_points > 0 
AND c.current_tier_id IS NULL;

-- Vérifier les clients avec des tiers mais pas de points
SELECT 
    'Clients avec tiers mais pas de points' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id
FROM clients c
WHERE c.loyalty_points = 0 
AND c.current_tier_id IS NOT NULL;

-- 3. RAPPORT DE SYNCHRONISATION
SELECT '=== RAPPORT DE SYNCHRONISATION ===' as etape;

-- Rapport détaillé des clients et leurs tiers
SELECT 
    'Rapport de synchronisation' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required as tier_points_required,
    c.updated_at as client_updated_at,
    lta.updated_at as tier_updated_at
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 4. VÉRIFICATION DES POLITIQUES RLS
SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as etape;

-- Vérifier les politiques sur loyalty_tiers_advanced
SELECT 
    'Politiques loyalty_tiers_advanced' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'loyalty_tiers_advanced'
ORDER BY policyname;

-- Vérifier les politiques sur loyalty_config
SELECT 
    'Politiques loyalty_config' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'loyalty_config'
ORDER BY policyname;

-- Vérifier les politiques sur clients
SELECT 
    'Politiques clients' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- 5. VÉRIFICATION DES TRIGGERS
SELECT '=== VÉRIFICATION DES TRIGGERS ===' as etape;

-- Vérifier les triggers sur loyalty_tiers_advanced
SELECT 
    'Triggers loyalty_tiers_advanced' as info,
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'loyalty_tiers_advanced'
ORDER BY trigger_name;

-- Vérifier les triggers sur loyalty_config
SELECT 
    'Triggers loyalty_config' as info,
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'loyalty_config'
ORDER BY trigger_name;

-- Vérifier les triggers sur clients
SELECT 
    'Triggers clients' as info,
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'clients'
ORDER BY trigger_name;

-- 6. VÉRIFICATION DES FONCTIONS
SELECT '=== VÉRIFICATION DES FONCTIONS ===' as etape;

-- Vérifier les fonctions liées à la fidélité
SELECT 
    'Fonctions loyalty' as info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%loyalty%'
ORDER BY routine_name;

-- 7. COMPTAGE DES DONNÉES
SELECT '=== COMPTAGE DES DONNÉES ===' as etape;

-- Compter les données
SELECT 
    'Comptage des données' as info,
    (SELECT COUNT(*) FROM auth.users) as nombre_utilisateurs,
    (SELECT COUNT(*) FROM loyalty_tiers_advanced) as nombre_niveaux,
    (SELECT COUNT(*) FROM loyalty_config) as nombre_configurations,
    (SELECT COUNT(*) FROM clients) as nombre_clients,
    (SELECT COUNT(*) FROM clients WHERE loyalty_points > 0) as clients_avec_points,
    (SELECT COUNT(*) FROM clients WHERE current_tier_id IS NOT NULL) as clients_avec_tier;

-- 8. CRÉER un événement de notification pour forcer le refresh
SELECT '=== CRÉATION ÉVÉNEMENT NOTIFICATION ===' as etape;

-- Créer un événement pour notifier le frontend du changement
NOTIFY loyalty_data_updated, 'Diagnostic effectué - Points de fidélité à vérifier';

-- 9. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Diagnostic complet effectué' as message;
SELECT '✅ Données analysées' as analyse;
SELECT '✅ Incohérences identifiées' as incohérences;
SELECT '✅ Politiques RLS vérifiées' as politiques;
SELECT '✅ Triggers vérifiés' as triggers;
SELECT '✅ Fonctions vérifiées' as fonctions;
SELECT '✅ Événement de notification créé' as notification;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT '💡 VIDEZ LE CACHE DU NAVIGATEUR' as cache;
SELECT '🔄 ACTUALISEZ LA PAGE' as refresh;
SELECT 'ℹ️ Vérifiez les résultats pour identifier les problèmes' as note;
