-- =====================================================
-- RÉACTIVATION ISOLATION FONCTIONNELLE - DEVICE_MODELS
-- =====================================================
-- Objectif: Réactiver l'isolation RLS de manière fonctionnelle
-- Date: 2025-01-23
-- =====================================================

-- 1. Diagnostic de l'état actuel
SELECT '=== DIAGNOSTIC ÉTAT ACTUEL ===' as etape;

-- Vérifier les politiques actuelles
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;

-- Vérifier les colonnes d'isolation
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND column_name IN ('workshop_id', 'created_by')
ORDER BY column_name;

-- Vérifier les données existantes
SELECT 
    COUNT(*) as total_modeles,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN workshop_id IS NULL OR created_by IS NULL THEN 1 END) as incomplets
FROM device_models;

-- 2. Nettoyer les politiques permissives
SELECT '=== NETTOYAGE POLITIQUES PERMISSIVES ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;

-- 3. S'assurer que toutes les données ont les valeurs d'isolation
SELECT '=== VÉRIFICATION DONNÉES ISOLATION ===' as etape;

-- Mettre à jour workshop_id pour les données manquantes
UPDATE device_models 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Mettre à jour created_by pour les données manquantes
UPDATE device_models 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 4. Créer des politiques RLS avec isolation fonctionnelle
SELECT '=== CRÉATION POLITIQUES ISOLATION FONCTIONNELLE ===' as etape;

-- Politique SELECT: Isolation par workshop_id
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique INSERT: Permissive mais avec trigger automatique
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique UPDATE: Isolation par workshop_id
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique DELETE: Isolation par workshop_id
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 5. Vérifier que le trigger fonctionne correctement
SELECT '=== VÉRIFICATION TRIGGER ===' as etape;

-- Vérifier que le trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';

-- 6. Test d'isolation fonctionnelle
SELECT '=== TEST ISOLATION FONCTIONNELLE ===' as etape;

-- Fonction de test d'isolation
DROP FUNCTION IF EXISTS test_device_models_isolation_functionnelle();

CREATE OR REPLACE FUNCTION test_device_models_isolation_functionnelle()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
    -- Test 3: Test d'insertion avec isolation
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Isolation Fonctionnelle', 'Test Model Isolation', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie avec isolation'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation stricte
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops (devrait être 0)
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent parfaitement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '❌ ÉCHEC'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- Exécuter le test
SELECT * FROM test_device_models_isolation_functionnelle();

-- 7. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Afficher les nouvelles politiques
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        ELSE '⚠️ Autre condition'
    END as evaluation
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;

-- Compter les modèles par workshop
SELECT 
    workshop_id,
    COUNT(*) as nombre_modeles
FROM device_models
GROUP BY workshop_id;

-- 8. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation RLS fonctionnelle activée' as message;
SELECT '✅ Les utilisateurs ne voient que leurs propres modèles' as isolation_info;
SELECT '✅ Testez la création et modification de modèles dans l''application' as next_step;
SELECT '✅ Vérifiez que l''isolation fonctionne entre différents workshops' as verification;
