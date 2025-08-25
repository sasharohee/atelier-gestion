-- =====================================================
-- NETTOYAGE RAPIDE TRIGGERS ET FONCTIONS
-- =====================================================
-- Objectif: Supprimer tous les triggers et fonctions existants
-- Date: 2025-01-23
-- =====================================================

-- 1. SUPPRIMER TOUS LES TRIGGERS
SELECT '=== SUPPRESSION TRIGGERS ===' as section;

DROP TRIGGER IF EXISTS set_device_model_user_context_aggressive ON device_models;
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
DROP TRIGGER IF EXISTS set_device_models_created_by ON device_models;
DROP TRIGGER IF EXISTS set_device_model_isolation ON device_models;
DROP TRIGGER IF EXISTS force_device_model_isolation ON device_models;
DROP TRIGGER IF EXISTS set_device_model_user ON device_models;

-- 2. SUPPRIMER TOUTES LES FONCTIONS
SELECT '=== SUPPRESSION FONCTIONS ===' as section;

DROP FUNCTION IF EXISTS set_device_model_user_context_aggressive();
DROP FUNCTION IF EXISTS set_device_model_context();
DROP FUNCTION IF EXISTS set_device_models_created_by();
DROP FUNCTION IF EXISTS set_device_model_isolation();
DROP FUNCTION IF EXISTS force_device_model_isolation();
DROP FUNCTION IF EXISTS get_my_device_models();
DROP FUNCTION IF EXISTS get_my_device_models_only();
DROP FUNCTION IF EXISTS set_device_model_user();

-- 3. SUPPRIMER TOUTES LES VUES
SELECT '=== SUPPRESSION VUES ===' as section;

DROP VIEW IF EXISTS device_models_filtered;
DROP VIEW IF EXISTS device_models_my_models;

-- 4. VÉRIFIER LE NETTOYAGE
SELECT '=== VÉRIFICATION NETTOYAGE ===' as section;

-- Vérifier qu'il n'y a plus de triggers
SELECT 
    'Triggers restants' as info,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';

-- Vérifier qu'il n'y a plus de fonctions
SELECT 
    'Fonctions restantes' as info,
    proname
FROM pg_proc 
WHERE proname LIKE '%device_model%' OR proname LIKE '%get_my%';

-- Vérifier qu'il n'y a plus de vues
SELECT 
    'Vues restantes' as info,
    viewname
FROM pg_views 
WHERE viewname LIKE '%device_model%';

SELECT 'NETTOYAGE TERMINÉ' as status;
