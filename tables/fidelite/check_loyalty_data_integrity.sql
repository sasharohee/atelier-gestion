-- =====================================================
-- VÉRIFICATION INTÉGRITÉ DONNÉES LOYALTY
-- =====================================================
-- Script pour vérifier et corriger l'intégrité des données
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION COMPLÈTE DES DONNÉES
SELECT '=== VÉRIFICATION COMPLÈTE DES DONNÉES ===' as etape;

-- Vérifier tous les utilisateurs
SELECT 
    'Utilisateurs' as info,
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at;

-- Vérifier tous les niveaux de fidélité
SELECT 
    'Tous les niveaux' as info,
    id,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    color,
    description,
    is_active,
    created_at,
    updated_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- Vérifier toutes les configurations
SELECT 
    'Toutes les configurations' as info,
    id,
    workshop_id,
    key,
    value,
    description,
    created_at,
    updated_at
FROM loyalty_config 
ORDER BY workshop_id, key;

-- Vérifier tous les clients
SELECT 
    'Tous les clients' as info,
    id,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    workshop_id,
    created_at,
    updated_at
FROM clients 
ORDER BY loyalty_points DESC;

-- 2. VÉRIFICATION DES INCOHÉRENCES
SELECT '=== VÉRIFICATION DES INCOHÉRENCES ===' as etape;

-- Vérifier les clients avec des tier_id invalides
SELECT 
    'Clients avec tier_id invalides' as info,
    c.id,
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
    c.id,
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
    c.id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id
FROM clients c
WHERE c.loyalty_points = 0 
AND c.current_tier_id IS NOT NULL;

-- 3. VÉRIFICATION DES POLITIQUES RLS
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

-- 4. VÉRIFICATION DES TRIGGERS
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

-- 5. VÉRIFICATION DES FONCTIONS
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

-- 6. RAPPORT FINAL
SELECT '=== RAPPORT FINAL ===' as etape;

-- Compter les données
SELECT 
    'Comptage des données' as info,
    (SELECT COUNT(*) FROM auth.users) as nombre_utilisateurs,
    (SELECT COUNT(*) FROM loyalty_tiers_advanced) as nombre_niveaux,
    (SELECT COUNT(*) FROM loyalty_config) as nombre_configurations,
    (SELECT COUNT(*) FROM clients) as nombre_clients,
    (SELECT COUNT(*) FROM clients WHERE loyalty_points > 0) as clients_avec_points,
    (SELECT COUNT(*) FROM clients WHERE current_tier_id IS NOT NULL) as clients_avec_tier;

-- 7. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Vérification complète effectuée' as message;
SELECT '✅ Données analysées' as analyse;
SELECT '✅ Incohérences identifiées' as incohérences;
SELECT '✅ Politiques RLS vérifiées' as politiques;
SELECT '✅ Triggers vérifiés' as triggers;
SELECT '✅ Fonctions vérifiées' as fonctions;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Vérifiez les résultats pour identifier les problèmes' as note;
