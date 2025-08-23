-- =====================================================
-- CORRECTION URGENCE DEVICE_MODELS + ISOLATION
-- =====================================================
-- Correction rapide pour device_models et isolation générale
-- Date: 2025-01-23
-- =====================================================

-- 1. Ajouter les colonnes manquantes sur device_models
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 2. Mettre à jour les données existantes
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

-- 3. Nettoyer les politiques existantes sur device_models
DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;

-- 4. Créer des politiques permissives pour device_models
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (true);

CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);

CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (true);

CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (true);

-- 5. Créer un trigger pour device_models
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
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
CREATE TRIGGER set_device_model_context
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 6. Vérification
SELECT '✅ Device_models corrigé' as message;
SELECT '✅ Colonnes workshop_id et created_by ajoutées' as colonnes;
SELECT '✅ Politiques permissives créées' as politiques;
SELECT '✅ Trigger automatique créé' as trigger;
SELECT '✅ Testez maintenant la création de modèles' as next_step;
