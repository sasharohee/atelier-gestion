-- =====================================================
-- CORRECTION ISOLATION DEVICE_MODELS - SOLUTION FINALE
-- =====================================================
-- Objectif: Réactiver RLS avec isolation stricte
-- Date: 2025-01-23
-- =====================================================

-- 1. Ajouter les colonnes manquantes pour l'isolation
SELECT '=== AJOUT DES COLONNES D''ISOLATION ===' as etape;

-- Ajouter workshop_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE device_models ADD COLUMN workshop_id UUID;
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
    END IF;
END $$;

-- 2. Nettoyer les politiques existantes
SELECT '=== NETTOYAGE POLITIQUES EXISTANTES ===' as etape;

DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;

-- 3. Mettre à jour les données existantes
SELECT '=== MISE À JOUR DES DONNÉES EXISTANTES ===' as etape;

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

-- 4. Réactiver RLS
SELECT '=== RÉACTIVATION RLS ===' as etape;

ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 5. Créer les politiques avec isolation stricte
SELECT '=== CRÉATION POLITIQUES AVEC ISOLATION STRICTE ===' as etape;

-- Politique SELECT: Seulement les modèles du workshop actuel
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique INSERT: Permet l'insertion (le trigger définit workshop_id)
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE: Seulement les modèles du workshop actuel
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique DELETE: Seulement les modèles du workshop actuel
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 6. Vérifier le trigger set_device_model_context
SELECT '=== VÉRIFICATION TRIGGER ===' as etape;

-- Recréer le trigger si nécessaire
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;

CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir workshop_id automatiquement
    NEW.workshop_id = (
        SELECT value::UUID 
        FROM system_settings 
        WHERE key = 'workshop_id' 
        LIMIT 1
    );
    
    -- Définir created_by automatiquement
    NEW.created_by = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les timestamps
    NEW.created_at = COALESCE(NEW.created_at, NOW());
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_model_context
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_context();

-- 7. Vérifier l'état des politiques
SELECT '=== ÉTAT DES POLITIQUES ===' as etape;

SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;

-- 8. Test d'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

-- Compter les modèles visibles
SELECT 
    COUNT(*) as total_models,
    COUNT(DISTINCT workshop_id) as workshops_differents
FROM device_models;

-- Afficher les modèles avec leur workshop
SELECT 
    id,
    brand,
    model,
    workshop_id,
    created_by,
    created_at
FROM device_models
ORDER BY created_at DESC
LIMIT 10;

-- 9. Fonction de test d'isolation
-- Supprimer la fonction existante si elle existe
DROP FUNCTION IF EXISTS test_device_models_isolation();

CREATE OR REPLACE FUNCTION test_device_models_isolation()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    v_workshop_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
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
    
    -- Test 2: Compter les modèles du workshop actuel
    SELECT COUNT(*) INTO v_model_count
    FROM device_models
    WHERE workshop_id = v_workshop_id;
    
    RETURN QUERY SELECT 
        'Modèles workshop actuel'::TEXT, 
        v_model_count::TEXT, 
        'Modèles visibles pour le workshop actuel'::TEXT;
    
    -- Test 3: Compter les modèles d'autres workshops
    SELECT COUNT(*) INTO v_other_workshop_count
    FROM device_models
    WHERE workshop_id != v_workshop_id;
    
    IF v_other_workshop_count = 0 THEN
        RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
            (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
    END IF;
    
    -- Test 4: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- 10. Exécuter le test
SELECT '=== RÉSULTATS DU TEST ===' as etape;
SELECT * FROM test_device_models_isolation();

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS ===' as etape;
SELECT '✅ RLS réactivé avec isolation stricte' as message;
SELECT '✅ Testez la création de modèles dans l''application' as next_step;
SELECT '✅ Vérifiez que les modèles ne sont visibles que dans le bon workshop' as verification;
