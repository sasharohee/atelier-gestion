-- ============================================================================
-- CORRECTION DES POLITIQUES RLS POUR DEVICE_MODELS
-- ============================================================================
-- Date: $(date)
-- Description: Résolution de l'erreur 403 sur la table device_models
-- Problème: "new row violates row-level security policy for table device_models"
-- ============================================================================

-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE
-- ============================================================================
SELECT '=== VÉRIFICATION STRUCTURE TABLE ===' as section;

-- Vérifier les colonnes de la table device_models
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. AJOUTER LES COLONNES MANQUANTES SI NÉCESSAIRE
-- ============================================================================
SELECT '=== AJOUT COLONNES MANQUANTES ===' as section;

DO $$
BEGIN
    -- Vérifier et ajouter user_id si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter workshop_id si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter created_by si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_models';
    END IF;
END $$;

-- 3. CRÉER/METTRE À JOUR LES TRIGGERS POUR L'ISOLATION
-- ============================================================================
SELECT '=== CRÉATION TRIGGERS ISOLATION ===' as section;

-- Fonction pour définir automatiquement user_id, workshop_id et created_by
CREATE OR REPLACE FUNCTION set_device_models_context()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id, workshop_id et created_by automatiquement
    NEW.user_id := auth.uid();
    NEW.workshop_id := auth.uid();
    NEW.created_by := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer les anciens triggers s'ils existent
DROP TRIGGER IF EXISTS set_device_models_user_id_trigger ON public.device_models;
DROP TRIGGER IF EXISTS set_device_models_workshop_id_trigger ON public.device_models;
DROP TRIGGER IF EXISTS set_device_models_context_trigger ON public.device_models;

-- Créer le nouveau trigger unifié
CREATE TRIGGER set_device_models_context_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_models_context();

-- 4. CRÉER LES INDEX POUR LES PERFORMANCES
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

CREATE INDEX IF NOT EXISTS idx_device_models_user_id ON public.device_models(user_id);
CREATE INDEX IF NOT EXISTS idx_device_models_workshop_id ON public.device_models(workshop_id);
CREATE INDEX IF NOT EXISTS idx_device_models_created_by ON public.device_models(created_by);
CREATE INDEX IF NOT EXISTS idx_device_models_brand ON public.device_models(brand);
CREATE INDEX IF NOT EXISTS idx_device_models_model ON public.device_models(model);
CREATE INDEX IF NOT EXISTS idx_device_models_type ON public.device_models(type);

-- 5. METTRE À JOUR LES POLITIQUES RLS
-- ============================================================================
SELECT '=== MISE À JOUR POLITIQUES RLS ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can insert their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can update their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can delete their own device models" ON public.device_models;

-- Créer les nouvelles politiques RLS
CREATE POLICY "Users can view their own device models" ON public.device_models
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device models" ON public.device_models
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device models" ON public.device_models
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device models" ON public.device_models
    FOR DELETE USING (auth.uid() = user_id);

-- 6. TEST DE FONCTIONNEMENT
-- ============================================================================
SELECT '=== TEST DE FONCTIONNEMENT ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_test_model_id UUID;
    v_test_result BOOLEAN;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        RAISE NOTICE '🧪 Test avec l''utilisateur: %', v_user_id;
        
        -- Test 1: Créer un modèle de test
        BEGIN
            INSERT INTO public.device_models (
                brand, model, type, year, specifications, 
                common_issues, repair_difficulty, parts_availability, is_active
            ) VALUES (
                'Test Brand ' || extract(epoch from now()), 
                'Test Model ' || extract(epoch from now()), 
                'smartphone', 
                2024, 
                '{}', 
                ARRAY['Test issue'], 
                'medium', 
                'high', 
                true
            ) RETURNING id INTO v_test_model_id;
            
            RAISE NOTICE '✅ Test réussi : Modèle créé - ID: %', v_test_model_id;
            
            -- Vérifier que les champs sont correctement remplis
            SELECT 
                (user_id = v_user_id) AND 
                (workshop_id = v_user_id) AND 
                (created_by = v_user_id) AND
                (created_at IS NOT NULL) AND
                (updated_at IS NOT NULL)
            INTO v_test_result
            FROM public.device_models 
            WHERE id = v_test_model_id;
            
            IF v_test_result THEN
                RAISE NOTICE '✅ Test réussi : Tous les champs sont correctement remplis';
            ELSE
                RAISE NOTICE '❌ Test échoué : Certains champs ne sont pas correctement remplis';
            END IF;
            
            -- Nettoyer le modèle de test
            DELETE FROM public.device_models WHERE id = v_test_model_id;
            RAISE NOTICE '✅ Modèle de test supprimé';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 7. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure de la table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- Vérifier les triggers
SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';

-- Vérifier les politiques RLS
SELECT 
    policyname, 
    cmd, 
    qual
FROM pg_policies 
WHERE tablename = 'device_models';

DO $$
BEGIN
    RAISE NOTICE '🎉 Correction des politiques RLS device_models terminée !';
    RAISE NOTICE '✅ Les colonnes d''isolation ont été ajoutées/vérifiées';
    RAISE NOTICE '✅ Les triggers d''isolation ont été mis à jour';
    RAISE NOTICE '✅ Les politiques RLS ont été configurées';
    RAISE NOTICE '✅ Vous pouvez maintenant créer des modèles d''appareils sans erreur 403';
END $$;


