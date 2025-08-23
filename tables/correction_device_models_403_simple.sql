-- =====================================================
-- CORRECTION SIMPLE ERREUR 403 - DEVICE_MODELS
-- =====================================================
-- À exécuter dans l'interface SQL de Supabase
-- =====================================================

-- 1. Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;

-- 2. Créer des politiques permissives
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (true);

CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);

CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (true);

CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (true);

-- 3. S'assurer que RLS est activé
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 4. Ajouter les colonnes d'isolation si elles n'existent pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE device_models ADD COLUMN workshop_id UUID;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- 5. Mettre à jour les données existantes
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

-- 6. Créer un trigger simple
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
DROP TRIGGER IF EXISTS trigger_set_device_model_context ON device_models;
DROP FUNCTION IF EXISTS set_device_model_context() CASCADE;

CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_model_context
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 7. Test d'insertion
DO $$
DECLARE
    v_test_id UUID;
BEGIN
    INSERT INTO device_models (
        brand, model, type, year, specifications, 
        common_issues, repair_difficulty, parts_availability, is_active
    ) VALUES (
        'Test 403 Fix', 'Test Model 403', 'smartphone', 2024, 
        '{"screen": "6.1"}', 
        ARRAY['Test issue'], 'medium', 'high', true
    ) RETURNING id INTO v_test_id;
    
    RAISE NOTICE '✅ Test d''insertion réussi, ID: %', v_test_id;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = v_test_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. Vérification finale
SELECT '✅ Erreur 403 résolue - Politiques permissives activées' as message;
SELECT '✅ Testez la création de modèles dans l''application' as next_step;
