-- =====================================================
-- CORRECTION ISOLATION DEVICE_MODELS - SOLUTION FINALE
-- =====================================================
-- Problème: Les modèles créés sur le compte A apparaissent sur le compte B
-- Cause: Le service frontend ne filtre pas par utilisateur
-- Solution: Corriger l'isolation au niveau base de données ET frontend
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC INITIAL
SELECT '=== DIAGNOSTIC INITIAL ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email;

-- Vérifier les données actuelles par utilisateur
SELECT 
    'device_models par utilisateur' as info,
    created_by,
    COUNT(*) as nombre_modeles,
    MIN(created_at) as premier_modele,
    MAX(created_at) as dernier_modele
FROM device_models 
GROUP BY created_by
ORDER BY created_by;

-- 2. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT '=== VÉRIFICATION STRUCTURE ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. S'ASSURER QUE LES COLONNES D'ISOLATION EXISTENT
SELECT '=== AJOUT COLONNES ISOLATION ===' as section;

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

-- Ajouter user_id si elle n'existe pas (pour cohérence)
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

-- 4. NETTOYER LES DONNÉES EXISTANTES
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

-- 5. CRÉER UN TRIGGER ROBUSTE POUR L'ISOLATION
SELECT '=== CRÉATION TRIGGER ISOLATION ===' as section;

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS set_device_model_user_context_aggressive ON device_models;
DROP TRIGGER IF EXISTS set_device_model_context ON device_models;
DROP TRIGGER IF EXISTS set_device_models_created_by ON device_models;

-- Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS set_device_model_user_context_aggressive();
DROP FUNCTION IF EXISTS set_device_model_context();
DROP FUNCTION IF EXISTS set_device_models_created_by();
DROP FUNCTION IF EXISTS get_my_device_models();

-- Créer une fonction robuste pour l'isolation
CREATE OR REPLACE FUNCTION set_device_model_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté - impossible de créer un modèle';
    END IF;
    
    -- Forcer l'utilisateur actuel pour l'isolation
    NEW.created_by := v_user_id;
    NEW.user_id := v_user_id;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Device model créé par utilisateur: %', v_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
CREATE TRIGGER set_device_model_isolation
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_isolation();

-- 6. CRÉER DES POLITIQUES RLS STRICTES
SELECT '=== CRÉATION POLITIQUES RLS ===' as section;

-- Activer RLS
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS device_models_select_policy ON device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON device_models;
DROP POLICY IF EXISTS device_models_update_policy ON device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON device_models;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON device_models;

-- Politique SELECT : Seulement les modèles de l'utilisateur connecté
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        created_by = auth.uid()
        OR
        user_id = auth.uid()
    );

-- Politique INSERT : Permettre l'insertion (le trigger s'occupe de l'isolation)
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
    );

-- Politique UPDATE : Seulement les modèles de l'utilisateur connecté
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        created_by = auth.uid()
        OR
        user_id = auth.uid()
    );

-- Politique DELETE : Seulement les modèles de l'utilisateur connecté
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        created_by = auth.uid()
        OR
        user_id = auth.uid()
    );

-- 7. CRÉER UNE FONCTION POUR RÉCUPÉRER LES MODÈLES DE L'UTILISATEUR
SELECT '=== CRÉATION FONCTION UTILISATEUR ===' as section;

-- Supprimer la fonction existante si elle existe
DROP FUNCTION IF EXISTS get_my_device_models();

CREATE OR REPLACE FUNCTION get_my_device_models()
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
    user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
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
        dm.user_id,
        dm.created_at,
        dm.updated_at
    FROM public.device_models dm
    WHERE dm.created_by = auth.uid()
       OR dm.user_id = auth.uid()
    ORDER BY dm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. CRÉER UNE VUE FILTRÉE
SELECT '=== CRÉATION VUE FILTRÉE ===' as section;

DROP VIEW IF EXISTS device_models_filtered;
CREATE VIEW device_models_filtered AS
SELECT * FROM device_models 
WHERE created_by = auth.uid() 
   OR user_id = auth.uid();

-- 9. TEST D'ISOLATION
SELECT '=== TEST ISOLATION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    nombre_modeles_avant INTEGER;
    nombre_modeles_apres INTEGER;
    test_model_id UUID;
    nombre_via_fonction INTEGER;
    nombre_via_vue INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    RAISE NOTICE 'Test d''isolation pour utilisateur: %', current_user_id;
    
    -- Compter les modèles avant
    SELECT COUNT(*) INTO nombre_modeles_avant
    FROM device_models 
    WHERE created_by = current_user_id;
    
    RAISE NOTICE 'Nombre de modèles avant: %', nombre_modeles_avant;
    
    -- Test via fonction
    SELECT COUNT(*) INTO nombre_via_fonction
    FROM get_my_device_models();
    
    RAISE NOTICE 'Nombre de modèles via fonction: %', nombre_via_fonction;
    
    -- Test via vue
    SELECT COUNT(*) INTO nombre_via_vue
    FROM device_models_filtered;
    
    RAISE NOTICE 'Nombre de modèles via vue: %', nombre_via_vue;
    
    -- Créer un modèle de test
    INSERT INTO device_models (brand, model, type, year)
    VALUES ('Test Isolation', 'Final', 'other', 2024)
    RETURNING id INTO test_model_id;
    
    RAISE NOTICE 'Modèle créé avec ID: %', test_model_id;
    
    -- Vérifier que le modèle appartient à l'utilisateur actuel
    SELECT created_by INTO current_user_id
    FROM device_models 
    WHERE id = test_model_id;
    
    RAISE NOTICE 'Modèle créé par: %', current_user_id;
    
    -- Compter les modèles après
    SELECT COUNT(*) INTO nombre_modeles_apres
    FROM device_models 
    WHERE created_by = auth.uid();
    
    RAISE NOTICE 'Nombre de modèles après: %', nombre_modeles_apres;
    
    -- Test via fonction après création
    SELECT COUNT(*) INTO nombre_via_fonction
    FROM get_my_device_models();
    
    RAISE NOTICE 'Nombre de modèles via fonction après création: %', nombre_via_fonction;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = test_model_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les données par utilisateur
SELECT 
    'device_models par utilisateur' as info,
    created_by,
    COUNT(*) as nombre_enregistrements
FROM device_models 
GROUP BY created_by
ORDER BY created_by;

-- Vérifier les politiques créées
SELECT 
    'Politiques RLS créées' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'device_models';

-- Vérifier les fonctions créées
SELECT 
    'Fonctions créées' as info,
    proname,
    prosrc
FROM pg_proc 
WHERE proname IN ('get_my_device_models', 'set_device_model_isolation');

SELECT 'ISOLATION DEVICE_MODELS CORRIGÉE' as status;
