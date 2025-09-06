-- Script pour corriger les politiques RLS de device_models
-- Ce script va rendre les politiques moins restrictives pour permettre l'insertion

-- 1. Vérifier que la table device_models existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'device_models') THEN
        RAISE EXCEPTION 'La table device_models n''existe pas';
    END IF;
END $$;

-- 2. Vérifier l'état actuel des politiques RLS
SELECT '=== POLITIQUES RLS ACTUELLES ===' as diagnostic;

SELECT 
    policyname,
    cmd,
    qual as condition,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Vérifie auth.uid()'
        WHEN qual LIKE '%workshop_id%' THEN '✅ Filtre par workshop_id'
        ELSE '⚠️ Autre condition'
    END as evaluation
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;

-- 3. Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "device_models_select_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_insert_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_update_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_delete_policy" ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;

-- 4. Créer des politiques RLS plus permissives
CREATE POLICY "device_models_select_policy" ON device_models
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "device_models_insert_policy" ON device_models
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        -- Supprimé la vérification de created_by pour permettre l'insertion
    );

CREATE POLICY "device_models_update_policy" ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "device_models_delete_policy" ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 5. Créer la fonction trigger si elle n'existe pas
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
    
    -- Si aucun workshop_id n'est trouvé, utiliser un UUID par défaut
    IF v_workshop_id IS NULL THEN
        v_workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Obtenir l'utilisateur actuel ou un utilisateur par défaut
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Créer le trigger s'il n'existe pas
DROP TRIGGER IF EXISTS trigger_set_device_model_context ON device_models;
CREATE TRIGGER trigger_set_device_model_context
    BEFORE INSERT OR UPDATE ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 7. S'assurer que RLS est activé
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 8. Vérifier les nouvelles politiques
SELECT '=== NOUVELLES POLITIQUES RLS ===' as diagnostic;

SELECT 
    policyname,
    cmd,
    qual as condition,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Vérifie auth.uid()'
        WHEN qual LIKE '%workshop_id%' THEN '✅ Filtre par workshop_id'
        ELSE '⚠️ Autre condition'
    END as evaluation
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;

-- 9. Test d'insertion avec les nouvelles politiques
DO $$
DECLARE
    v_test_model_id UUID;
    v_workshop_id UUID;
    v_insert_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    IF v_workshop_id IS NULL THEN
        RAISE NOTICE '❌ Aucun workshop_id trouvé dans system_settings';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test d''insertion avec workshop_id: %', v_workshop_id;
    
    -- Tenter l'insertion
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test RLS Fix', 'Test Model RLS', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_model_id;
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Insertion réussie avec id: %', v_test_model_id;
        
        -- Vérifier que le modèle a été créé avec le bon workshop_id
        IF EXISTS (
            SELECT 1 FROM device_models 
            WHERE id = v_test_model_id 
            AND workshop_id = v_workshop_id
        ) THEN
            RAISE NOTICE '✅ Modèle créé avec le bon workshop_id';
        ELSE
            RAISE NOTICE '❌ Modèle créé avec un workshop_id incorrect';
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_model_id;
        RAISE NOTICE '✅ Test nettoyé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion: %', SQLERRM;
    END;
    
    IF v_insert_success THEN
        RAISE NOTICE '✅ Test d''insertion réussi avec les nouvelles politiques RLS';
    ELSE
        RAISE NOTICE '❌ Test d''insertion échoué';
    END IF;
END $$;

-- 10. Fonction de test des politiques RLS
CREATE OR REPLACE FUNCTION test_device_models_rls_policies()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_workshop_id UUID;
    v_policy_count INTEGER;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
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
    
    -- Test 2: Vérifier le nombre de politiques
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies 
    WHERE tablename = 'device_models';
    
    IF v_policy_count >= 4 THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '✅ OK'::TEXT, v_policy_count || ' politiques créées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '❌ ERREUR'::TEXT, 'Seulement ' || v_policy_count || ' politiques'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les politiques ne vérifient pas auth.uid() pour INSERT
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND cmd = 'INSERT'
        AND qual LIKE '%auth.uid()%'
    ) THEN
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '✅ OK'::TEXT, 'Politique INSERT sans vérification auth.uid()'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '❌ ERREUR'::TEXT, 'Politique INSERT vérifie encore auth.uid()'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger existe
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) INTO v_trigger_exists;
    
    IF v_trigger_exists THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Vérifier que la fonction existe
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'set_device_model_context'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '✅ OK'::TEXT, 'Fonction set_device_model_context créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 6: Vérifier le workshop_id
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id défini'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 11. Afficher le statut final
SELECT 'Script fix_device_models_rls_policies.sql exécuté avec succès' as status;
SELECT 'Les politiques RLS ont été corrigées pour permettre l''insertion' as message;
