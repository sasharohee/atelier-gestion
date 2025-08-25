-- =====================================================
-- SOLUTION ALTERNATIVE ISOLATION DEVICE_MODELS
-- =====================================================
-- Approche: Utiliser une vue filtrée au lieu d'une fonction
-- Date: 2025-01-23
-- =====================================================

-- 1. NETTOYAGE COMPLET
SELECT '=== NETTOYAGE COMPLET ===' as section;

-- Désactiver RLS
ALTER TABLE device_models DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques
DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON device_models;

-- Supprimer tous les triggers
DROP TRIGGER IF EXISTS set_device_model_user_context_aggressive ON device_models;
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
DROP TRIGGER IF EXISTS set_device_models_created_by ON device_models;
DROP TRIGGER IF EXISTS set_device_model_isolation ON device_models;
DROP TRIGGER IF EXISTS force_device_model_isolation ON device_models;
DROP TRIGGER IF EXISTS set_device_model_user ON device_models;

-- Supprimer toutes les fonctions
DROP FUNCTION IF EXISTS set_device_model_user_context_aggressive();
DROP FUNCTION IF EXISTS set_device_model_context();
DROP FUNCTION IF EXISTS set_device_models_created_by();
DROP FUNCTION IF EXISTS set_device_model_isolation();
DROP FUNCTION IF EXISTS force_device_model_isolation();
DROP FUNCTION IF EXISTS get_my_device_models();
DROP FUNCTION IF EXISTS get_my_device_models_only();
DROP FUNCTION IF EXISTS set_device_model_user();

-- Supprimer toutes les vues
DROP VIEW IF EXISTS device_models_filtered;
DROP VIEW IF EXISTS device_models_my_models;

-- 2. S'ASSURER QUE LES COLONNES EXISTENT
SELECT '=== VÉRIFICATION COLONNES ===' as section;

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

-- Ajouter user_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE device_models ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà';
    END IF;
END $$;

-- 3. NETTOYER LES DONNÉES EXISTANTES
SELECT '=== NETTOYAGE DONNÉES ===' as section;

-- Mettre à jour created_by pour les modèles sans utilisateur
UPDATE device_models 
SET created_by = COALESCE(
    auth.uid(),
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- Mettre à jour user_id pour la cohérence
UPDATE device_models 
SET user_id = created_by
WHERE user_id IS NULL OR user_id != created_by;

-- 4. CRÉER UN TRIGGER SIMPLE
SELECT '=== CRÉATION TRIGGER SIMPLE ===' as section;

CREATE OR REPLACE FUNCTION set_device_model_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.created_by := auth.uid();
    NEW.user_id := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
CREATE TRIGGER set_device_model_user
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_user();

-- 5. CRÉER UNE VUE FILTRÉE
SELECT '=== CRÉATION VUE FILTRÉE ===' as section;

CREATE VIEW device_models_my_models AS
SELECT 
    id,
    brand,
    model,
    type,
    year,
    specifications,
    common_issues,
    repair_difficulty,
    parts_availability,
    is_active,
    created_by,
    user_id,
    created_at,
    updated_at
FROM device_models 
WHERE created_by = auth.uid() 
   OR user_id = auth.uid();

-- 6. TEST DE LA VUE
SELECT '=== TEST VUE ===' as section;

-- Test de la vue
SELECT 
    'Test vue filtrée' as info,
    COUNT(*) as nombre_modeles
FROM device_models_my_models;

-- 7. TEST D'INSERTION
SELECT '=== TEST INSERTION ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_test_id UUID;
    v_count_before INTEGER;
    v_count_after INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    RAISE NOTICE 'Test d''insertion pour utilisateur: %', v_user_id;
    
    -- Compter avant
    SELECT COUNT(*) INTO v_count_before FROM device_models_my_models;
    RAISE NOTICE 'Nombre de modèles avant: %', v_count_before;
    
    -- Insérer un modèle de test
    INSERT INTO device_models (brand, model, type, year)
    VALUES ('Test Vue', 'Alternative', 'other', 2024)
    RETURNING id INTO v_test_id;
    
    RAISE NOTICE 'Modèle créé avec ID: %', v_test_id;
    
    -- Compter après
    SELECT COUNT(*) INTO v_count_after FROM device_models_my_models;
    RAISE NOTICE 'Nombre de modèles après: %', v_count_after;
    
    -- Vérifier que le modèle appartient à l'utilisateur actuel
    SELECT created_by INTO v_user_id
    FROM device_models 
    WHERE id = v_test_id;
    
    RAISE NOTICE 'Modèle créé par: %', v_user_id;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = v_test_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les données par utilisateur
SELECT 
    'Données par utilisateur' as info,
    created_by,
    COUNT(*) as nombre_enregistrements
FROM device_models 
GROUP BY created_by
ORDER BY created_by;

-- Vérifier la vue
SELECT 
    'Vue créée' as info,
    schemaname,
    viewname
FROM pg_views 
WHERE viewname = 'device_models_my_models';

-- Vérifier le trigger
SELECT 
    'Trigger créé' as info,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';

SELECT 'SOLUTION ALTERNATIVE TERMINÉE' as status;
