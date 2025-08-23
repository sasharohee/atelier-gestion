-- =====================================================
-- DIAGNOSTIC ISOLATION DEVICE_MODELS
-- =====================================================
-- Diagnostic de l'isolation entre comptes
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel de la table
SELECT '=== ÉTAT DE LA TABLE DEVICE_MODELS ===' as diagnostic;

SELECT 
    key,
    value,
    category,
    created_at,
    updated_at
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type')
ORDER BY key;

-- 2. Vérifier les device_models existants
SELECT '=== DEVICE_MODELS EXISTANTS ===' as etape;

SELECT 
    id,
    brand,
    model,
    workshop_id,
    created_by,
    created_at,
    updated_at
FROM device_models 
ORDER BY created_at DESC
LIMIT 10;

-- 3. Vérifier les utilisateurs
SELECT '=== UTILISATEURS ===' as etape;

SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC
LIMIT 5;

-- 4. Vérifier les workshops_id utilisés
SELECT '=== WORKSHOP_IDS UTILISÉS ===' as etape;

SELECT 
    workshop_id,
    COUNT(*) as nombre_modeles,
    MIN(created_at) as premier_modele,
    MAX(created_at) as dernier_modele
FROM device_models 
WHERE workshop_id IS NOT NULL
GROUP BY workshop_id
ORDER BY nombre_modeles DESC;

-- 5. Vérifier les modèles sans workshop_id
SELECT '=== MODÈLES SANS WORKSHOP_ID ===' as etape;

SELECT 
    COUNT(*) as nombre_modeles_sans_workshop
FROM device_models 
WHERE workshop_id IS NULL;

-- 6. Vérifier le trigger
SELECT '=== VÉRIFICATION TRIGGER ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'device_models'
ORDER BY trigger_name;

-- 7. Test d'insertion pour voir le workshop_id assigné
SELECT '=== TEST D''INSERTION ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_workshop_id UUID;
    v_current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_current_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RAISE NOTICE 'Workshop_id actuel: %', v_current_workshop_id;
    
    -- Insérer un modèle de test
    INSERT INTO device_models (
        brand, model, type, year, specifications, 
        common_issues, repair_difficulty, parts_availability, is_active
    ) VALUES (
        'Test Isolation', 'Test Model Isolation', 'smartphone', 2024, 
        '{"screen": "6.1"}', 
        ARRAY['Test isolation issue'], 'medium', 'high', true
    ) RETURNING id, workshop_id INTO v_test_id, v_workshop_id;
    
    RAISE NOTICE 'Modèle de test créé - ID: %, Workshop_id assigné: %', v_test_id, v_workshop_id;
    
    -- Vérifier si le workshop_id correspond
    IF v_workshop_id = v_current_workshop_id THEN
        RAISE NOTICE '✅ Workshop_id correctement assigné';
    ELSE
        RAISE NOTICE '❌ Workshop_id incorrect - Attendu: %, Reçu: %', v_current_workshop_id, v_workshop_id;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM device_models WHERE id = v_test_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. Vérifier les politiques RLS actuelles
SELECT '=== POLITIQUES RLS ACTUELLES ===' as etape;

SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'device_models'
ORDER BY policyname;

-- 9. Vérifier le statut RLS
SELECT '=== STATUT RLS ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'device_models';

-- 10. Instructions
SELECT '=== INSTRUCTIONS ===' as etape;
SELECT '✅ Diagnostic complet effectué' as message;
SELECT '✅ Vérifiez les résultats ci-dessus' as verification;
SELECT '⚠️ Si l''isolation ne fonctionne pas, le problème est dans le trigger ou les paramètres' as next_step;
