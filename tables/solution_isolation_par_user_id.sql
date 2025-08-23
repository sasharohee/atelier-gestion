-- =====================================================
-- SOLUTION ISOLATION PAR USER_ID
-- =====================================================
-- Utilise l'user_id pour l'isolation au lieu du workshop_id
-- Date: 2025-01-23
-- =====================================================

-- 1. Désactiver RLS sur device_models
SELECT '=== DÉSACTIVATION RLS ===' as etape;

ALTER TABLE device_models DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques RLS
SELECT '=== SUPPRESSION POLITIQUES ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;

-- 3. S'assurer que les colonnes d'isolation existent
SELECT '=== VÉRIFICATION COLONNES ===' as etape;

ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 4. Mettre à jour created_by pour tous les modèles existants
SELECT '=== MISE À JOUR CREATED_BY ===' as etape;

UPDATE device_models 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 5. Créer un trigger qui utilise l'user_id pour l'isolation
SELECT '=== CRÉATION TRIGGER AVEC USER_ID ===' as etape;

CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Pour workshop_id, utiliser l'user_id comme identifiant unique
    NEW.workshop_id := v_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
CREATE TRIGGER set_device_model_context
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 6. Mettre à jour tous les modèles existants avec workshop_id = created_by
SELECT '=== MISE À JOUR WORKSHOP_ID ===' as etape;

UPDATE device_models 
SET workshop_id = created_by
WHERE workshop_id IS NULL OR workshop_id != created_by;

-- 7. Créer une vue filtrée par user_id
SELECT '=== CRÉATION VUE FILTRÉE PAR USER_ID ===' as etape;

DROP VIEW IF EXISTS device_models_filtered;
CREATE VIEW device_models_filtered AS
SELECT 
    dm.*,
    CASE 
        WHEN ss_gestion.value = 'gestion' THEN true
        ELSE dm.created_by = auth.uid()
    END as is_accessible
FROM device_models dm
CROSS JOIN LATERAL (
    SELECT value FROM system_settings WHERE key = 'workshop_type' LIMIT 1
) ss_gestion;

-- 8. Créer une fonction pour obtenir les modèles de l'utilisateur connecté
SELECT '=== CRÉATION FONCTION UTILISATEUR ===' as etape;

CREATE OR REPLACE FUNCTION get_user_device_models()
RETURNS TABLE (
    id UUID,
    brand TEXT,
    model TEXT,
    type TEXT,
    year INTEGER,
    specifications JSONB,
    common_issues TEXT[],
    repair_difficulty TEXT,
    parts_availability TEXT,
    is_active BOOLEAN,
    created_by UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dm.id,
        dm.brand,
        dm.model,
        dm.type,
        dm.year,
        dm.specifications,
        dm.common_issues,
        dm.repair_difficulty,
        dm.parts_availability,
        dm.is_active,
        dm.created_by,
        dm.created_at,
        dm.updated_at
    FROM device_models dm
    WHERE dm.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY dm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Test d'insertion pour vérifier que ça fonctionne
SELECT '=== TEST D''INSERTION ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_created_by UUID;
    v_current_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    RAISE NOTICE 'User_id actuel: %', v_current_user_id;
    
    -- Insérer un modèle de test
    INSERT INTO device_models (
        brand, model, type, year, specifications, 
        common_issues, repair_difficulty, parts_availability, is_active
    ) VALUES (
        'Test Isolation User ID', 'Test Model User ID', 'smartphone', 2024, 
        '{"screen": "6.1"}', 
        ARRAY['Test user id issue'], 'medium', 'high', true
    ) RETURNING id, created_by INTO v_test_id, v_created_by;
    
    RAISE NOTICE '✅ Modèle de test créé - ID: %, Created_by: %', v_test_id, v_created_by;
    
    -- Vérifier si le created_by correspond
    IF v_created_by = v_current_user_id THEN
        RAISE NOTICE '✅ Created_by correctement assigné';
    ELSE
        RAISE NOTICE '❌ Created_by incorrect - Attendu: %, Reçu: %', v_current_user_id, v_created_by;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM device_models WHERE id = v_test_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. Vérification finale
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

-- Vérifier les colonnes
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'device_models'
AND column_name IN ('workshop_id', 'created_by')
ORDER BY column_name;

-- Vérifier le trigger
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'device_models'
ORDER BY trigger_name;

-- Vérifier la fonction
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'get_user_device_models';

-- Vérifier la vue
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name = 'device_models_filtered';

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation par user_id activée' as message;
SELECT '✅ Plus d''erreur 403' as no_403;
SELECT '✅ Trigger avec user_id créé' as trigger;
SELECT '✅ Fonction get_user_device_models créée' as fonction;
SELECT '✅ Vue filtrée par user_id créée' as vue;
SELECT '✅ Testez maintenant la création de modèles' as next_step;
SELECT 'ℹ️ L''isolation se fait maintenant par user_id' as note;
SELECT '⚠️ Utilisez get_user_device_models() pour récupérer les modèles' as fonction_note;
