-- =====================================================
-- DIAGNOSTIC COMPLET - TOUS LES TRIGGERS LOYALTY
-- =====================================================
-- Script pour identifier TOUS les triggers qui pourraient
-- causer l'erreur "record 'new' has no field 'updated_at'"
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC COMPLET DE TOUS LES TRIGGERS
SELECT '=== DIAGNOSTIC COMPLET TOUS LES TRIGGERS ===' as etape;

-- Tous les triggers sur les tables de fidélité
SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    action_timing,
    event_manipulation,
    action_orientation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN (
    'client_loyalty_points', 
    'loyalty_points_history', 
    'loyalty_tiers_advanced', 
    'referrals',
    'loyalty_tiers',
    'loyalty_config',
    'loyalty_rules'
)
ORDER BY event_object_table, trigger_name;

-- 2. DIAGNOSTIC DES FONCTIONS TRIGGER
SELECT '=== DIAGNOSTIC FONCTIONS TRIGGER ===' as etape;

-- Toutes les fonctions qui pourraient être utilisées par des triggers
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (
    routine_name LIKE '%workshop%' OR
    routine_name LIKE '%loyalty%' OR
    routine_name LIKE '%updated_at%' OR
    routine_name LIKE '%trigger%'
)
ORDER BY routine_name;

-- 3. DIAGNOSTIC DES TRIGGERS SUR TOUTES LES TABLES
SELECT '=== DIAGNOSTIC TRIGGERS TOUTES TABLES ===' as etape;

-- Tous les triggers qui pourraient affecter les tables de fidélité
SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND (
    action_statement LIKE '%updated_at%' OR
    action_statement LIKE '%loyalty%' OR
    action_statement LIKE '%workshop_id%'
)
ORDER BY event_object_table, trigger_name;

-- 4. DIAGNOSTIC DES TRIGGERS DE MISE À JOUR AUTOMATIQUE
SELECT '=== DIAGNOSTIC TRIGGERS MISE À JOUR ===' as etape;

-- Triggers qui mettent à jour automatiquement updated_at
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND action_statement LIKE '%updated_at%'
ORDER BY event_object_table, trigger_name;

-- 5. DIAGNOSTIC DES TRIGGERS GÉNÉRIQUES
SELECT '=== DIAGNOSTIC TRIGGERS GÉNÉRIQUES ===' as etape;

-- Triggers génériques qui pourraient affecter toutes les tables
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND (
    trigger_name LIKE '%update%' OR
    trigger_name LIKE '%timestamp%' OR
    trigger_name LIKE '%auto%'
)
ORDER BY event_object_table, trigger_name;

-- 6. DIAGNOSTIC DES TRIGGERS DE SYSTÈME
SELECT '=== DIAGNOSTIC TRIGGERS SYSTÈME ===' as etape;

-- Triggers système qui pourraient être problématiques
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND (
    trigger_name LIKE '%system%' OR
    trigger_name LIKE '%default%' OR
    trigger_name LIKE '%global%'
)
ORDER BY event_object_table, trigger_name;

-- 7. DIAGNOSTIC DES TRIGGERS RÉCENTS
SELECT '=== DIAGNOSTIC TRIGGERS RÉCENTS ===' as etape;

-- Triggers créés récemment (si possible de les identifier)
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND (
    trigger_name LIKE '%ultra%' OR
    trigger_name LIKE '%strict%' OR
    trigger_name LIKE '%safe%' OR
    trigger_name LIKE '%correction%'
)
ORDER BY event_object_table, trigger_name;

-- 8. DIAGNOSTIC DES TRIGGERS DE CORRECTION
SELECT '=== DIAGNOSTIC TRIGGERS DE CORRECTION ===' as etape;

-- Triggers créés par les scripts de correction
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND (
    trigger_name LIKE '%correction%' OR
    trigger_name LIKE '%fix%' OR
    trigger_name LIKE '%repair%'
)
ORDER BY event_object_table, trigger_name;

-- 9. DIAGNOSTIC DES TRIGGERS DE FIDÉLITÉ SPÉCIFIQUES
SELECT '=== DIAGNOSTIC TRIGGERS FIDÉLITÉ SPÉCIFIQUES ===' as etape;

-- Triggers spécifiques aux points de fidélité
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND (
    trigger_name LIKE '%loyalty%' OR
    trigger_name LIKE '%fidelite%' OR
    trigger_name LIKE '%points%'
)
ORDER BY event_object_table, trigger_name;

-- 10. RÉSUMÉ DU DIAGNOSTIC
SELECT '=== RÉSUMÉ DU DIAGNOSTIC ===' as etape;

SELECT 
    COUNT(*) as total_triggers_loyalty
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN (
    'client_loyalty_points', 
    'loyalty_points_history', 
    'loyalty_tiers_advanced', 
    'referrals'
);

SELECT 
    COUNT(*) as total_triggers_updated_at
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND action_statement LIKE '%updated_at%';

SELECT 
    COUNT(*) as total_fonctions_trigger
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (
    routine_name LIKE '%workshop%' OR
    routine_name LIKE '%loyalty%' OR
    routine_name LIKE '%updated_at%'
);

-- 11. INSTRUCTIONS
SELECT '=== INSTRUCTIONS ===' as etape;
SELECT '1. Exécutez ce diagnostic pour identifier tous les triggers problématiques' as instruction;
SELECT '2. Recherchez les triggers qui utilisent updated_at' as instruction;
SELECT '3. Supprimez ou corrigez les triggers problématiques' as instruction;
SELECT '4. Testez l''ajout de points de fidélité' as instruction;
