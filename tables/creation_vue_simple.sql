-- =====================================================
-- CRÉATION VUE SIMPLE DEVICE_MODELS_MY_MODELS
-- =====================================================
-- Objectif: Créer la vue filtrée pour l'isolation
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE
SELECT '=== VÉRIFICATION STRUCTURE ===' as section;

-- Vérifier que la table existe
SELECT 
    'Table device_models' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'device_models' 
AND table_schema = 'public';

-- Vérifier les colonnes
SELECT 
    'Colonnes device_models' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. CRÉER LA VUE
SELECT '=== CRÉATION VUE ===' as section;

-- Supprimer la vue si elle existe
DROP VIEW IF EXISTS device_models_my_models;

-- Créer la vue filtrée
CREATE VIEW device_models_my_models AS
SELECT 
    id,
    brand,
    model,
    type,
    year,
    specifications,
    common_issues,
    repair_difficulty,
    parts_availability,
    is_active,
    created_by,
    user_id,
    created_at,
    updated_at
FROM device_models 
WHERE created_by = auth.uid() 
   OR user_id = auth.uid();

-- 3. VÉRIFIER LA VUE
SELECT '=== VÉRIFICATION VUE ===' as section;

-- Vérifier que la vue existe
SELECT 
    'Vue créée' as info,
    schemaname,
    viewname
FROM pg_views 
WHERE viewname = 'device_models_my_models';

-- 4. TEST DE LA VUE
SELECT '=== TEST VUE ===' as section;

-- Test de la vue
SELECT 
    'Test vue filtrée' as info,
    COUNT(*) as nombre_modeles
FROM device_models_my_models;

-- 5. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les données par utilisateur
SELECT 
    'Données par utilisateur' as info,
    created_by,
    COUNT(*) as nombre_enregistrements
FROM device_models 
GROUP BY created_by
ORDER BY created_by;

-- Vérifier les données dans la vue
SELECT 
    'Données dans la vue' as info,
    COUNT(*) as nombre_enregistrements
FROM device_models_my_models;

SELECT 'VUE CRÉÉE AVEC SUCCÈS' as status;
