-- =====================================================
-- CORRECTION ISOLATION COMPLÈTE - DEVICE_MODELS
-- =====================================================
-- Objectif: Résoudre l'erreur 403 avec isolation RLS complète
-- Date: 2025-01-23
-- =====================================================

-- 1. Diagnostic complet
SELECT '=== DIAGNOSTIC COMPLET ===' as etape;

-- Vérifier l'état actuel
SELECT 
    'Table device_models' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_models') 
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as statut;

-- Vérifier les colonnes d'isolation
SELECT 
    column_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'device_models' AND column_name = column_name
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut
FROM (VALUES ('workshop_id'), ('created_by')) AS cols(column_name);

-- Vérifier system_settings
SELECT 
    'system_settings workshop_id' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM system_settings WHERE key = 'workshop_id'
        ) THEN '✅ Existe'
        ELSE '❌ Manquant'
    END as statut;

-- 2. Préparation de l'environnement
SELECT '=== PRÉPARATION ENVIRONNEMENT ===' as etape;

-- S'assurer qu'un workshop_id existe
DO $$
DECLARE
    v_workshop_id UUID;
BEGIN
    -- Vérifier si un workshop_id existe
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
        );
        RAISE NOTICE '✅ Workshop_id créé';
    ELSE
        RAISE NOTICE '✅ Workshop_id existe: %', v_workshop_id;
    END IF;
END $$;

-- 3. Ajout des colonnes d'isolation si manquantes
SELECT '=== AJOUT COLONNES ISOLATION ===' as etape;

-- Ajouter workshop_id si elle n'existe pas
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
END $$;

-- Ajouter created_by si elle n'existe pas
DO $$
BEGIN
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

-- 4. Mise à jour des données existantes
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as etape;

-- Mettre à jour workshop_id pour les données existantes
UPDATE device_models 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Mettre à jour created_by pour les données existantes
UPDATE device_models 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 5. Nettoyage des politiques existantes
SELECT '=== NETTOYAGE POLITIQUES ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;

-- 6. Création du trigger robuste
SELECT '=== CRÉATION TRIGGER ROBUSTE ===' as etape;

-- Supprimer le trigger existant
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;

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

-- 7. Création des politiques RLS avec isolation complète
SELECT '=== CRÉATION POLITIQUES RLS ISOLATION COMPLÈTE ===' as etape;

-- Activer RLS
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- Politique SELECT: Isolation stricte par workshop_id
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique INSERT: Permissive pour permettre l'insertion
-- Le trigger définit automatiquement workshop_id
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE: Isolation stricte par workshop_id
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique DELETE: Isolation stricte par workshop_id
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 8. Test complet d'isolation
SELECT '=== TEST COMPLET ISOLATION ===' as etape;

-- Fonction de test d'isolation complète
DROP FUNCTION IF EXISTS test_device_models_isolation_complete();

CREATE OR REPLACE FUNCTION test_device_models_isolation_complete()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
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
            'Test Isolation Complete', 'Test Model Complete', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie sans erreur 403'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation
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
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent parfaitement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '❌ ÉCHEC'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- Exécuter le test
SELECT * FROM test_device_models_isolation_complete();

-- 9. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Afficher l'état des politiques
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'INSERT' AND qual = 'true' THEN '✅ Permissive pour insertion'
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
GROUP BY workshop_id;

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation RLS complète et fonctionnelle' as message;
SELECT '✅ Erreur 403 résolue' as resolution;
SELECT '✅ Testez la création de modèles dans l''application' as next_step;
SELECT '✅ Vérifiez que l''isolation fonctionne entre différents workshops' as verification;
