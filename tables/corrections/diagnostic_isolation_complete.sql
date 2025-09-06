-- =====================================================
-- DIAGNOSTIC COMPLET ISOLATION
-- =====================================================
-- Date: 2025-01-23
-- Problème: Les modèles créés sur le compte A apparaissent aussi sur le compte B
-- =====================================================

-- 1. DIAGNOSTIC DES WORKSHOP_ID
SELECT '=== DIAGNOSTIC WORKSHOP_ID ===' as section;

-- Vérifier les workshop_id dans system_settings
SELECT 
    key,
    value,
    CASE 
        WHEN key = 'workshop_id' THEN '✅ Workshop ID'
        WHEN key = 'workshop_type' THEN '✅ Type Workshop'
        ELSE 'ℹ️ Autre paramètre'
    END as type_parametre
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type', 'workshop_name');

-- 2. DIAGNOSTIC DES DONNÉES PAR WORKSHOP
SELECT '=== DONNÉES PAR WORKSHOP ===' as section;

-- Compter les données par workshop_id
SELECT 
    'clients' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM clients 
GROUP BY workshop_id
UNION ALL
SELECT 
    'devices' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM devices 
GROUP BY workshop_id
UNION ALL
SELECT 
    'repairs' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM repairs 
GROUP BY workshop_id
UNION ALL
SELECT 
    'device_models' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM device_models 
GROUP BY workshop_id
ORDER BY table_name, workshop_id;

-- 3. DIAGNOSTIC DES POLITIQUES RLS ACTUELLES
SELECT '=== POLITIQUES RLS ACTUELLES ===' as section;

SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual LIKE '%user_id%' THEN '❌ Isolation par user_id'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        WHEN qual IS NULL THEN '❌ Pas de condition'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'repairs', 'device_models')
ORDER BY tablename, policyname;

-- 4. DIAGNOSTIC DES TRIGGERS
SELECT '=== TRIGGERS ACTUELS ===' as section;

SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'repairs', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 5. TEST D'ISOLATION MANUEL
SELECT '=== TEST ISOLATION MANUEL ===' as section;

-- Simuler la requête que fait l'application
DO $$
DECLARE
    current_workshop_id UUID;
    nombre_modeles_visibles INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO current_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RAISE NOTICE 'Workshop ID actuel: %', current_workshop_id;
    
    -- Compter les modèles visibles avec la politique RLS
    SELECT COUNT(*) INTO nombre_modeles_visibles
    FROM device_models 
    WHERE workshop_id = current_workshop_id;
    
    RAISE NOTICE 'Nombre de modèles visibles pour ce workshop: %', nombre_modeles_visibles;
    
    -- Compter tous les modèles (sans RLS)
    SELECT COUNT(*) INTO nombre_modeles_visibles
    FROM device_models;
    
    RAISE NOTICE 'Nombre total de modèles (sans RLS): %', nombre_modeles_visibles;
    
END $$;

-- 6. VÉRIFIER LES COLONNES D'ISOLATION
SELECT '=== COLONNES D''ISOLATION ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'workshop_id' THEN '✅ Colonne isolation'
        WHEN column_name = 'user_id' THEN '✅ Colonne utilisateur'
        WHEN column_name = 'created_by' THEN '✅ Colonne créateur'
        ELSE 'ℹ️ Autre colonne'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('clients', 'devices', 'repairs', 'device_models')
AND column_name IN ('workshop_id', 'user_id', 'created_by')
ORDER BY table_name, column_name;

-- 7. VÉRIFIER LES DONNÉES RÉCENTES
SELECT '=== DONNÉES RÉCENTES DEVICE_MODELS ===' as section;

SELECT 
    id,
    brand,
    model,
    workshop_id,
    created_by,
    created_at,
    CASE 
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) 
        THEN '✅ Workshop actuel'
        ELSE '❌ Autre workshop'
    END as appartenance
FROM device_models 
ORDER BY created_at DESC 
LIMIT 10;

-- 8. VÉRIFIER LES UTILISATEURS
SELECT '=== UTILISATEURS ACTUELS ===' as section;

SELECT 
    id,
    email,
    raw_user_meta_data,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 9. TEST DE CRÉATION AVEC ISOLATION
SELECT '=== TEST CRÉATION AVEC ISOLATION ===' as section;

DO $$
DECLARE
    current_workshop_id UUID;
    current_user_id UUID;
    test_model_id UUID;
    nombre_avant INTEGER;
    nombre_apres INTEGER;
BEGIN
    -- Obtenir les IDs actuels
    SELECT value::UUID INTO current_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    current_user_id := auth.uid();
    
    RAISE NOTICE 'Workshop ID: %, User ID: %', current_workshop_id, current_user_id;
    
    -- Compter avant
    SELECT COUNT(*) INTO nombre_avant
    FROM device_models 
    WHERE workshop_id = current_workshop_id;
    
    RAISE NOTICE 'Nombre de modèles avant: %', nombre_avant;
    
    -- Créer un modèle de test
    INSERT INTO device_models (
        brand, model, type, year, workshop_id, created_by
    ) VALUES (
        'Test Isolation', 'Diagnostic', 'other', 2024, current_workshop_id, current_user_id
    ) RETURNING id INTO test_model_id;
    
    RAISE NOTICE 'Modèle créé avec ID: %', test_model_id;
    
    -- Compter après
    SELECT COUNT(*) INTO nombre_apres
    FROM device_models 
    WHERE workshop_id = current_workshop_id;
    
    RAISE NOTICE 'Nombre de modèles après: %', nombre_apres;
    
    -- Vérifier que le modèle a le bon workshop_id
    SELECT workshop_id, created_by INTO current_workshop_id, current_user_id
    FROM device_models 
    WHERE id = test_model_id;
    
    RAISE NOTICE 'Workshop ID du modèle créé: %, Created by: %', current_workshop_id, current_user_id;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = test_model_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT 'DIAGNOSTIC ISOLATION TERMINÉ' as status;
