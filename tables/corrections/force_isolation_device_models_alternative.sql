-- Script alternatif pour forcer l'isolation des device_models
-- Ce script gère mieux l'authentification et les contraintes

-- 1. Vérifier que la table device_models existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'device_models') THEN
        RAISE EXCEPTION 'La table device_models n''existe pas. Veuillez d''abord exécuter create_new_tables.sql';
    END IF;
END $$;

-- 2. Obtenir ou créer un workshop_id de manière sécurisée
DO $$
DECLARE
    v_workshop_id UUID;
    v_workshop_count INTEGER;
    v_user_id UUID;
    v_default_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel ou un utilisateur par défaut
    v_user_id := auth.uid();
    
    -- Si aucun utilisateur authentifié, utiliser le premier utilisateur disponible
    IF v_user_id IS NULL THEN
        SELECT id INTO v_default_user_id FROM auth.users LIMIT 1;
        IF v_default_user_id IS NULL THEN
            RAISE EXCEPTION 'Aucun utilisateur trouvé dans auth.users';
        END IF;
        v_user_id := v_default_user_id;
        RAISE NOTICE 'Utilisation de l''utilisateur par défaut: %', v_user_id;
    ELSE
        RAISE NOTICE 'Utilisation de l''utilisateur authentifié: %', v_user_id;
    END IF;
    
    -- Vérifier s'il y a un workshop_id défini
    SELECT COUNT(*) INTO v_workshop_count
    FROM system_settings 
    WHERE key = 'workshop_id' 
    AND value IS NOT NULL;
    
    IF v_workshop_count = 0 THEN
        -- Créer un nouveau workshop_id unique
        INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
        VALUES (
            'workshop_id', 
            gen_random_uuid()::text, 
            v_user_id,
            'workshop',
            NOW(), 
            NOW()
        );
        
        RAISE NOTICE 'Nouveau workshop_id créé dans system_settings';
    ELSE
        -- Mettre à jour le workshop_id existant avec un nouveau
        UPDATE system_settings 
        SET 
            value = gen_random_uuid()::text,
            updated_at = NOW()
        WHERE key = 'workshop_id';
        
        RAISE NOTICE 'Workshop_id mis à jour dans system_settings';
    END IF;
    
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RAISE NOTICE 'Workshop_id actuel: %', v_workshop_id;
END $$;

-- 3. Supprimer TOUTES les politiques RLS existantes
DROP POLICY IF EXISTS "device_models_select_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_insert_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_update_policy" ON device_models;
DROP POLICY IF EXISTS "device_models_delete_policy" ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;

-- 4. Supprimer TOUS les triggers existants
DROP TRIGGER IF EXISTS trigger_set_device_model_context ON device_models;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_device_models ON device_models;

-- 5. Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS set_device_model_context();
DROP FUNCTION IF EXISTS set_workshop_context_device_models();

-- 6. Supprimer TOUTES les données existantes (nettoyage complet)
DELETE FROM device_models;

-- 7. S'assurer que les colonnes existent et sont correctes
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 8. Définir les contraintes NOT NULL
ALTER TABLE device_models ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE device_models ALTER COLUMN created_by SET NOT NULL;

-- 9. Créer des index pour les performances
CREATE INDEX IF NOT EXISTS idx_device_models_workshop ON device_models(workshop_id);
CREATE INDEX IF NOT EXISTS idx_device_models_created_by ON device_models(created_by);
CREATE INDEX IF NOT EXISTS idx_device_models_created_at ON device_models(created_at);

-- 10. Activer RLS
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 11. Créer une fonction de contexte ultra-stricte
CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
    v_default_user_id UUID;
BEGIN
    -- Obtenir le workshop_id de manière stricte
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Si aucun workshop_id n'est trouvé, ERREUR
    IF v_workshop_id IS NULL THEN
        RAISE EXCEPTION 'Aucun workshop_id défini dans system_settings';
    END IF;
    
    -- Obtenir l'utilisateur actuel ou un utilisateur par défaut
    v_user_id := auth.uid();
    
    -- Si aucun utilisateur authentifié, utiliser le premier utilisateur disponible
    IF v_user_id IS NULL THEN
        SELECT id INTO v_default_user_id FROM auth.users LIMIT 1;
        IF v_default_user_id IS NULL THEN
            RAISE EXCEPTION 'Aucun utilisateur trouvé dans auth.users';
        END IF;
        v_user_id := v_default_user_id;
    END IF;
    
    -- Définir les valeurs de manière stricte
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Créer le trigger
CREATE TRIGGER trigger_set_device_model_context
    BEFORE INSERT OR UPDATE ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 13. Créer des politiques RLS ultra-strictes
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
        ) AND
        created_by = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1))
    );

CREATE POLICY "device_models_update_policy" ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        ) AND
        created_by = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1))
    );

CREATE POLICY "device_models_delete_policy" ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        ) AND
        created_by = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1))
    );

-- 14. Fonction de test d'isolation stricte
CREATE OR REPLACE FUNCTION test_force_isolation_alternative()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_workshop_id UUID;
    v_model_count INTEGER;
    v_total_count INTEGER;
    v_test_model_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Test 1: Vérifier que le workshop_id est défini
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id défini'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id défini'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id trouvé'::TEXT;
        RETURN;
    END IF;
    
    -- Test 2: Vérifier que la table est vide (après nettoyage)
    SELECT COUNT(*) INTO v_total_count FROM device_models;
    IF v_total_count = 0 THEN
        RETURN QUERY SELECT 'Table nettoyée'::TEXT, '✅ OK'::TEXT, 'Aucun modèle existant'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table nettoyée'::TEXT, '❌ ERREUR'::TEXT, v_total_count || ' modèles restants'::TEXT;
    END IF;
    
    -- Test 3: Vérifier les politiques strictes
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND policyname = 'device_models_select_policy'
        AND qual NOT LIKE '%IS NULL%'
    ) THEN
        RETURN QUERY SELECT 'Politiques strictes'::TEXT, '✅ OK'::TEXT, 'Politiques sans condition IS NULL'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques strictes'::TEXT, '❌ ERREUR'::TEXT, 'Politiques trop permissives'::TEXT;
    END IF;
    
    -- Test 4: Tester l'insertion avec isolation stricte
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Force Isolation Alt', 'Test Model Force Alt', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_model_id;
        
        -- Vérifier que le modèle inséré appartient au bon atelier
        SELECT COUNT(*) INTO v_model_count
        FROM device_models 
        WHERE id = v_test_model_id
        AND workshop_id = v_workshop_id;
        
        IF v_model_count = 1 THEN
            RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '✅ OK'::TEXT, 'Insertion avec isolation réussie'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '❌ ERREUR'::TEXT, 'Insertion sans isolation'::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_model_id;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '❌ ERREUR'::TEXT, 'Erreur: ' || SQLERRM::TEXT;
    END;
    
    -- Test 5: Vérifier l'isolation complète
    SELECT COUNT(*) INTO v_model_count
    FROM device_models 
    WHERE workshop_id = v_workshop_id;
    
    SELECT COUNT(*) INTO v_total_count
    FROM device_models;
    
    IF v_model_count = v_total_count THEN
        RETURN QUERY SELECT 'Isolation complète'::TEXT, '✅ OK'::TEXT, 
            'Tous les modèles appartiennent à l''atelier actuel (' || v_model_count || ' modèles)'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Isolation complète'::TEXT, '❌ ERREUR'::TEXT, 
            'Isolation violée: ' || v_model_count || '/' || v_total_count || ' modèles isolés'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 15. Afficher le statut final
SELECT 'Script force_isolation_device_models_alternative.sql exécuté avec succès' as status;
SELECT 'Version alternative avec gestion d''authentification améliorée' as message;
