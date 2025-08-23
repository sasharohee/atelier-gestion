-- =====================================================
-- CORRECTION RLS PERMISSIF POUR DEVICE_MODELS
-- =====================================================
-- Garde RLS activé mais avec des politiques permissives pour l'insertion
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel
SELECT '=== ÉTAT ACTUEL ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'device_models';

-- 2. S'assurer que RLS est activé
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer toutes les politiques existantes
SELECT '=== NETTOYAGE POLITIQUES ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;

-- 4. Créer des politiques hybrides (permissives pour INSERT, strictes pour SELECT/UPDATE/DELETE)
SELECT '=== CRÉATION POLITIQUES HYBRIDES ===' as etape;

-- Politique SELECT : Isolation par workshop_id + accès gestion
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique INSERT : Permissive (le trigger gère l'isolation)
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE : Isolation par workshop_id + accès gestion
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique DELETE : Isolation par workshop_id + accès gestion
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- 5. S'assurer que les colonnes d'isolation existent
SELECT '=== VÉRIFICATION COLONNES ===' as etape;

ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 6. Mettre à jour les données existantes
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
    auth.uid(), 
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 7. Créer un trigger robuste pour l'isolation automatique
SELECT '=== CRÉATION TRIGGER ===' as etape;

CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Si pas de workshop_id, en créer un nouveau
    IF v_workshop_id IS NULL THEN
        v_workshop_id := gen_random_uuid();
        
        -- Vérifier si workshop_id existe déjà
        IF EXISTS (SELECT 1 FROM system_settings WHERE key = 'workshop_id') THEN
            UPDATE system_settings
            SET value = v_workshop_id::text,
                user_id = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)),
                updated_at = NOW()
            WHERE key = 'workshop_id';
        ELSE
            INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
            VALUES (
                'workshop_id',
                v_workshop_id::text,
                COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)),
                'general',
                NOW(),
                NOW()
            );
        END IF;
    END IF;
    
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

-- 8. Test d'insertion pour vérifier que ça fonctionne
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
        'Test RLS Permissif', 'Test Model RLS Permissif', 'smartphone', 2024, 
        '{"screen": "6.1"}', 
        ARRAY['Test RLS permissif issue'], 'medium', 'high', true
    ) RETURNING id, workshop_id INTO v_test_id, v_workshop_id;
    
    RAISE NOTICE '✅ Modèle de test créé - ID: %, Workshop_id assigné: %', v_test_id, v_workshop_id;
    
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

-- 9. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier le statut RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'device_models';

-- Vérifier les politiques créées
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual = 'true' THEN '✅ Permissive'
        ELSE '❌ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;

-- Vérifier le trigger
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'device_models'
ORDER BY trigger_name;

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec politiques hybrides' as message;
SELECT '✅ INSERT permissif (plus d''erreur 403)' as insert_policy;
SELECT '✅ SELECT/UPDATE/DELETE avec isolation' as isolation_policy;
SELECT '✅ Trigger automatique pour workshop_id' as trigger;
SELECT '✅ Testez maintenant la création de modèles' as next_step;
SELECT 'ℹ️ L''isolation fonctionne via le trigger automatique' as note;
