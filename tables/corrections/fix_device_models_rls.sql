-- Script pour corriger les politiques RLS de device_models
-- Ce script doit être exécuté pour résoudre l'erreur 403 Forbidden

-- 1. Vérifier que la table device_models existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'device_models') THEN
        RAISE EXCEPTION 'La table device_models n''existe pas. Veuillez d''abord exécuter create_new_tables.sql';
    END IF;
END $$;

-- 2. Ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 3. Mettre à jour les données existantes
UPDATE device_models SET 
    workshop_id = COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ),
    created_by = COALESCE(
        (SELECT id FROM auth.users LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE workshop_id IS NULL OR created_by IS NULL;

-- 4. Activer RLS si ce n'est pas déjà fait
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 5. Supprimer les anciennes politiques
DROP POLICY IF EXISTS "device_models_select_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_insert_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_update_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_delete_policy" ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;

-- 6. Créer de nouvelles politiques plus permissives
CREATE POLICY "device_models_select_policy" ON device_models
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) OR
        workshop_id IS NULL
    );

CREATE POLICY "device_models_insert_policy" ON device_models
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        created_by = auth.uid()
    );

CREATE POLICY "device_models_update_policy" ON device_models
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) OR
        workshop_id IS NULL
    );

CREATE POLICY "device_models_delete_policy" ON device_models
    FOR DELETE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) OR
        workshop_id IS NULL
    );

-- 7. Ajouter des contraintes NOT NULL
ALTER TABLE device_models ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE device_models ALTER COLUMN created_by SET NOT NULL;

-- 8. Créer des index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_device_models_workshop ON device_models(workshop_id);
CREATE INDEX IF NOT EXISTS idx_device_models_created_by ON device_models(created_by);

-- 9. Créer un trigger pour automatiquement définir workshop_id et created_by
CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir workshop_id automatiquement
    NEW.workshop_id := COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    );
    
    -- Définir created_by automatiquement
    NEW.created_by := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Supprimer le trigger existant s'il existe
DROP TRIGGER IF EXISTS trigger_set_device_model_context ON device_models;

-- 11. Créer le trigger
CREATE TRIGGER trigger_set_device_model_context
    BEFORE INSERT OR UPDATE ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 12. Fonction de test pour vérifier l'installation
CREATE OR REPLACE FUNCTION test_device_models_rls()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'device_models' 
        AND row_security = true
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que les politiques existent
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND policyname = 'device_models_select_policy'
    ) THEN
        RETURN QUERY SELECT 'Politique SELECT'::TEXT, '✅ OK'::TEXT, 'Politique SELECT créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique SELECT'::TEXT, '❌ ERREUR'::TEXT, 'Politique SELECT manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les colonnes existent
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND column_name = 'workshop_id'
    ) THEN
        RETURN QUERY SELECT 'Colonne workshop_id'::TEXT, '✅ OK'::TEXT, 'Colonne workshop_id existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Colonne workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Colonne workshop_id manquante'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger existe
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Tester l'insertion d'un modèle de test
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test', 'Test Model', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        );
        
        DELETE FROM device_models WHERE brand = 'Test' AND model = 'Test Model';
        
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion et suppression réussies'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur: ' || SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- 13. Afficher le statut
SELECT 'Script fix_device_models_rls.sql exécuté avec succès' as status;
