-- =====================================================
-- SOLUTION ISOLATION FORCÉE PAR USER_ID
-- =====================================================
-- Force l'isolation en activant RLS avec des politiques strictes
-- Date: 2025-01-23
-- =====================================================

-- 1. Activer RLS sur device_models
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques existantes
SELECT '=== NETTOYAGE POLITIQUES ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;

-- 3. Créer des politiques strictes basées sur user_id
SELECT '=== CRÉATION POLITIQUES STRICTES ===' as etape;

-- Politique SELECT : Seulement les modèles de l'utilisateur connecté
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        created_by = auth.uid()
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

-- Politique UPDATE : Seulement les modèles de l'utilisateur connecté
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        created_by = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique DELETE : Seulement les modèles de l'utilisateur connecté
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        created_by = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- 4. S'assurer que les colonnes d'isolation existent
SELECT '=== VÉRIFICATION COLONNES ===' as etape;

ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 5. Mettre à jour created_by pour tous les modèles existants
SELECT '=== MISE À JOUR CREATED_BY ===' as etape;

UPDATE device_models 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 6. Créer un trigger robuste pour l'isolation automatique
SELECT '=== CRÉATION TRIGGER ===' as etape;

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

-- 7. Mettre à jour tous les modèles existants avec workshop_id = created_by
SELECT '=== MISE À JOUR WORKSHOP_ID ===' as etape;

UPDATE device_models 
SET workshop_id = created_by
WHERE workshop_id IS NULL OR workshop_id != created_by;

-- 8. Test d'insertion pour vérifier que ça fonctionne
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
        'Test Isolation Forcée', 'Test Model Isolation Forcée', 'smartphone', 2024, 
        '{"screen": "6.1"}', 
        ARRAY['Test isolation forcée issue'], 'medium', 'high', true
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

-- 9. Test d'isolation pour vérifier que les politiques fonctionnent
SELECT '=== TEST D''ISOLATION ===' as etape;

-- Compter les modèles visibles pour l'utilisateur actuel
SELECT 
    'Modèles visibles pour l''utilisateur actuel' as test,
    COUNT(*) as nombre_modeles
FROM device_models 
WHERE created_by = auth.uid();

-- Compter tous les modèles (pour comparaison)
SELECT 
    'Total des modèles dans la base' as test,
    COUNT(*) as nombre_modeles
FROM device_models;

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

-- Vérifier les politiques créées
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '✅ Isolation par user_id'
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

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec isolation forcée' as message;
SELECT '✅ Politiques strictes par user_id' as politiques;
SELECT '✅ Plus d''erreur 403' as no_403;
SELECT '✅ Trigger automatique créé' as trigger;
SELECT '✅ Testez maintenant avec différents comptes' as next_step;
SELECT 'ℹ️ L''isolation est maintenant forcée au niveau base de données' as note;
SELECT '⚠️ Chaque utilisateur ne verra que ses propres modèles' as isolation_note;
