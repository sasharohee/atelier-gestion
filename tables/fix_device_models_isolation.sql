-- Script pour corriger l'isolation des données de device_models
-- Ce script doit être exécuté pour résoudre le problème d'isolation entre ateliers

-- 1. Vérifier que la table device_models existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'device_models') THEN
        RAISE EXCEPTION 'La table device_models n''existe pas. Veuillez d''abord exécuter create_new_tables.sql';
    END IF;
END $$;

-- 2. Supprimer les anciennes politiques trop permissives
DROP POLICY IF EXISTS "device_models_select_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_insert_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_update_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_delete_policy" ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;

-- 3. Créer des politiques RLS strictes pour l'isolation
CREATE POLICY "device_models_select_policy" ON device_models
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
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
        ) AND
        created_by = auth.uid()
    );

CREATE POLICY "device_models_delete_policy" ON device_models
    FOR DELETE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        created_by = auth.uid()
    );

-- 4. S'assurer que toutes les données existantes ont un workshop_id valide
UPDATE device_models SET 
    workshop_id = COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE workshop_id IS NULL;

-- 5. S'assurer que toutes les données existantes ont un created_by valide
UPDATE device_models SET 
    created_by = COALESCE(
        (SELECT id FROM auth.users LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE created_by IS NULL;

-- 6. Améliorer le trigger pour une meilleure isolation
CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id de manière plus robuste
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Si aucun workshop_id n'est trouvé, utiliser un UUID par défaut
    IF v_workshop_id IS NULL THEN
        v_workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Définir workshop_id automatiquement
    NEW.workshop_id := v_workshop_id;
    
    -- Définir created_by automatiquement
    NEW.created_by := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Recréer le trigger
DROP TRIGGER IF EXISTS trigger_set_device_model_context ON device_models;
CREATE TRIGGER trigger_set_device_model_context
    BEFORE INSERT OR UPDATE ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 8. Fonction pour tester l'isolation
CREATE OR REPLACE FUNCTION test_device_models_isolation()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_workshop_id UUID;
    v_model_count INTEGER;
    v_total_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    IF v_workshop_id IS NULL THEN
        v_workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Test 1: Vérifier que les politiques sont strictes
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND policyname = 'device_models_select_policy'
        AND pg_get_expr(polqual, polrelid) LIKE '%workshop_id%'
        AND pg_get_expr(polqual, polrelid) NOT LIKE '%IS NULL%'
    ) THEN
        RETURN QUERY SELECT 'Politiques strictes'::TEXT, '✅ OK'::TEXT, 'Politiques sans condition IS NULL'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques strictes'::TEXT, '❌ ERREUR'::TEXT, 'Politiques trop permissives'::TEXT;
    END IF;
    
    -- Test 2: Vérifier l'isolation des données
    SELECT COUNT(*) INTO v_model_count
    FROM device_models 
    WHERE workshop_id = v_workshop_id;
    
    SELECT COUNT(*) INTO v_total_count
    FROM device_models;
    
    IF v_model_count = v_total_count THEN
        RETURN QUERY SELECT 'Isolation des données'::TEXT, '✅ OK'::TEXT, 
            'Tous les modèles appartiennent à l''atelier actuel (' || v_model_count || ' modèles)'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Isolation des données'::TEXT, '❌ ERREUR'::TEXT, 
            'Isolation violée: ' || v_model_count || '/' || v_total_count || ' modèles isolés'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que tous les modèles ont un workshop_id
    SELECT COUNT(*) INTO v_model_count
    FROM device_models 
    WHERE workshop_id IS NULL;
    
    IF v_model_count = 0 THEN
        RETURN QUERY SELECT 'Workshop_id défini'::TEXT, '✅ OK'::TEXT, 'Tous les modèles ont un workshop_id'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id défini'::TEXT, '❌ ERREUR'::TEXT, 
            v_model_count || ' modèles sans workshop_id'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que tous les modèles ont un created_by
    SELECT COUNT(*) INTO v_model_count
    FROM device_models 
    WHERE created_by IS NULL;
    
    IF v_model_count = 0 THEN
        RETURN QUERY SELECT 'Created_by défini'::TEXT, '✅ OK'::TEXT, 'Tous les modèles ont un created_by'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Created_by défini'::TEXT, '❌ ERREUR'::TEXT, 
            v_model_count || ' modèles sans created_by'::TEXT;
    END IF;
    
    -- Test 5: Tester l'insertion avec isolation
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Isolation', 'Test Model Isolation', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        );
        
        -- Vérifier que le modèle inséré appartient au bon atelier
        SELECT COUNT(*) INTO v_model_count
        FROM device_models 
        WHERE brand = 'Test Isolation' 
        AND model = 'Test Model Isolation'
        AND workshop_id = v_workshop_id;
        
        IF v_model_count = 1 THEN
            RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '✅ OK'::TEXT, 'Insertion avec isolation réussie'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '❌ ERREUR'::TEXT, 'Insertion sans isolation'::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE brand = 'Test Isolation' AND model = 'Test Model Isolation';
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '❌ ERREUR'::TEXT, 'Erreur: ' || SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- 9. Fonction pour nettoyer les données orphelines (optionnel)
CREATE OR REPLACE FUNCTION cleanup_orphaned_device_models()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    IF v_workshop_id IS NULL THEN
        v_workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Supprimer les modèles qui n'appartiennent pas à l'atelier actuel
    DELETE FROM device_models 
    WHERE workshop_id != v_workshop_id;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 10. Afficher le statut
SELECT 'Script fix_device_models_isolation.sql exécuté avec succès' as status;
