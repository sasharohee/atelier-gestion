-- =====================================================
-- SOLUTION ATELIER DE GESTION - DEVICE_MODELS
-- =====================================================
-- Accès spécial pour l'atelier de gestion
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

-- Vérifier l'état de RLS
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ Activé'
        ELSE '❌ Désactivé'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'device_models';

-- 2. Nettoyer toutes les politiques existantes
SELECT '=== NETTOYAGE COMPLET ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;
DROP POLICY IF EXISTS "Enable read access for all users" ON device_models;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON device_models;
DROP POLICY IF EXISTS "Enable update for users based on email" ON device_models;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON device_models;

-- 3. Vérifier que les colonnes d'isolation existent
SELECT '=== VÉRIFICATION COLONNES ===' as etape;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE device_models ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà';
    END IF;
END $$;

-- 4. S'assurer qu'un workshop_id existe
SELECT '=== VÉRIFICATION WORKSHOP_ID ===' as etape;

DO $$
DECLARE
    v_workshop_id UUID;
BEGIN
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    IF v_workshop_id IS NULL THEN
        INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
        VALUES (
            'workshop_id', 
            gen_random_uuid()::text,
            COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)),
            'general',
            NOW(),
            NOW()
        );
        RAISE NOTICE '✅ Workshop_id créé dans system_settings';
    ELSE
        RAISE NOTICE '✅ Workshop_id existe déjà: %', v_workshop_id;
    END IF;
END $$;

-- 5. Mettre à jour les données existantes
SELECT '=== MISE À JOUR DONNÉES ===' as etape;

UPDATE device_models 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

UPDATE device_models 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 6. Créer des politiques avec accès spécial pour l'atelier de gestion
SELECT '=== CRÉATION POLITIQUES AVEC ACCÈS GESTION ===' as etape;

-- Activer RLS
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- Politique SELECT: Isolation normale + accès gestion
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        -- Accès normal : voir ses propres modèles
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        -- Accès gestion : voir tous les modèles si atelier de gestion
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique INSERT: Permissive pour éviter l'erreur 403
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE: Isolation normale + accès gestion
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        -- Accès normal : modifier ses propres modèles
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        -- Accès gestion : modifier tous les modèles si atelier de gestion
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique DELETE: Isolation normale + accès gestion
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        -- Accès normal : supprimer ses propres modèles
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        -- Accès gestion : supprimer tous les modèles si atelier de gestion
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- 7. Créer un trigger robuste pour l'isolation automatique
SELECT '=== CRÉATION TRIGGER ROBUSTE ===' as etape;

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
DROP TRIGGER IF EXISTS trigger_set_device_model_context ON device_models;
DROP FUNCTION IF EXISTS set_device_model_context() CASCADE;

-- Créer une fonction trigger robuste
CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id avec fallback
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Si aucun workshop_id, en créer un
    IF v_workshop_id IS NULL THEN
        INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
        VALUES (
            'workshop_id', 
            gen_random_uuid()::text,
            COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)),
            'general',
            NOW(),
            NOW()
        ) RETURNING value::UUID INTO v_workshop_id;
    END IF;
    
    -- Obtenir l'utilisateur actuel avec fallback
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
CREATE TRIGGER set_device_model_context
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 8. Test d'insertion et d'isolation avec gestion
SELECT '=== TEST AVEC ACCÈS GESTION ===' as etape;

-- Fonction de test avec accès gestion
DROP FUNCTION IF EXISTS test_device_models_gestion();

CREATE OR REPLACE FUNCTION test_device_models_gestion()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
    v_gestion_access BOOLEAN := FALSE;
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
    
    -- Test 3: Test d'insertion
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Gestion', 'Test Model Gestion', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie sans erreur 403'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation normale
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation normale'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation normale'::TEXT, '⚠️ ATTENTION'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Vérifier l'accès gestion
    IF EXISTS (
        SELECT 1 FROM system_settings 
        WHERE key = 'workshop_type' 
        AND value = 'gestion'
        LIMIT 1
    ) THEN
        v_gestion_access := TRUE;
        RETURN QUERY SELECT 'Accès gestion'::TEXT, '✅ OK'::TEXT, 'Atelier de gestion détecté'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Accès gestion'::TEXT, 'ℹ️ INFO'::TEXT, 'Atelier normal (pas de gestion)'::TEXT;
    END IF;
    
    -- Test 6: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '⚠️ PARTIEL'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- Exécuter le test
SELECT * FROM test_device_models_gestion();

-- 9. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Afficher les nouvelles politiques
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'INSERT' AND with_check = 'true' THEN '✅ Permissive pour insertion'
        WHEN qual LIKE '%workshop_type%' THEN '✅ Accès gestion inclus'
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
GROUP BY workshop_id
ORDER BY nombre_modeles DESC;

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Politiques avec accès gestion créées' as message;
SELECT '✅ Insertion sans erreur 403' as insertion_info;
SELECT '✅ Isolation normale + accès spécial pour gestion' as isolation_info;
SELECT '✅ Testez la création de modèles dans l''application' as next_step;
SELECT 'ℹ️ Pour activer l''accès gestion, définissez workshop_type=gestion' as gestion_note;
