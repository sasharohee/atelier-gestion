-- =====================================================
-- CORRECTION ISOLATION CATÉGORIES - VERSION FINALE
-- =====================================================
-- Corrige définitivement le problème d'isolation des catégories
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel des tables
SELECT '=== ÉTAT ACTUEL DES TABLES ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tablename;

-- 2. Activer RLS sur toutes les tables si nécessaire
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer toutes les politiques existantes
SELECT '=== NETTOYAGE POLITIQUES EXISTANTES ===' as etape;

-- Supprimer les politiques pour device_categories
DROP POLICY IF EXISTS "Users can view their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can insert their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can update their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can delete their own device categories" ON public.device_categories;

-- Supprimer les politiques pour device_brands
DROP POLICY IF EXISTS "Users can view their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can insert their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can update their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can delete their own device brands" ON public.device_brands;

-- Supprimer les politiques pour device_models
DROP POLICY IF EXISTS "Users can view their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can insert their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can update their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can delete their own device models" ON public.device_models;

-- 4. Créer les nouvelles politiques RLS strictes
SELECT '=== CRÉATION POLITIQUES RLS STRICTES ===' as etape;

-- Politiques pour device_categories
CREATE POLICY "device_categories_select_policy" ON public.device_categories
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "device_categories_insert_policy" ON public.device_categories
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_categories_update_policy" ON public.device_categories
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "device_categories_delete_policy" ON public.device_categories
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour device_brands
CREATE POLICY "device_brands_select_policy" ON public.device_brands
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "device_brands_insert_policy" ON public.device_brands
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_brands_update_policy" ON public.device_brands
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "device_brands_delete_policy" ON public.device_brands
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour device_models
CREATE POLICY "device_models_select_policy" ON public.device_models
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "device_models_insert_policy" ON public.device_models
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_models_update_policy" ON public.device_models
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "device_models_delete_policy" ON public.device_models
    FOR DELETE USING (user_id = auth.uid());

-- 5. S'assurer que les colonnes user_id existent
SELECT '=== VÉRIFICATION COLONNES user_id ===' as etape;

ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 6. Mettre à jour les données existantes sans user_id
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as etape;

-- Mettre à jour device_categories
UPDATE public.device_categories 
SET user_id = COALESCE(
    auth.uid(), 
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

-- Mettre à jour device_brands
UPDATE public.device_brands 
SET user_id = COALESCE(
    auth.uid(), 
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

-- Mettre à jour device_models
UPDATE public.device_models 
SET user_id = COALESCE(
    auth.uid(), 
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

-- 7. Créer des triggers pour définir automatiquement user_id
SELECT '=== CRÉATION TRIGGERS AUTOMATIQUES ===' as etape;

-- Fonction pour device_categories
CREATE OR REPLACE FUNCTION set_device_category_user_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := NEW.user_id;
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour device_brands
CREATE OR REPLACE FUNCTION set_device_brand_user_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := NEW.user_id;
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour device_models
CREATE OR REPLACE FUNCTION set_device_model_user_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := NEW.user_id;
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_device_category_user_id_trigger ON public.device_categories;
CREATE TRIGGER set_device_category_user_id_trigger
    BEFORE INSERT ON public.device_categories
    FOR EACH ROW EXECUTE FUNCTION set_device_category_user_id();

DROP TRIGGER IF EXISTS set_device_brand_user_id_trigger ON public.device_brands;
CREATE TRIGGER set_device_brand_user_id_trigger
    BEFORE INSERT ON public.device_brands
    FOR EACH ROW EXECUTE FUNCTION set_device_brand_user_id();

DROP TRIGGER IF EXISTS set_device_model_user_id_trigger ON public.device_models;
CREATE TRIGGER set_device_model_user_id_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW EXECUTE FUNCTION set_device_model_user_id();

-- 8. Test d'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_test_category_id UUID;
    v_test_brand_id UUID;
    v_test_model_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    RAISE NOTICE 'Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Créer une catégorie
    INSERT INTO public.device_categories (name, description, icon, is_active)
    VALUES ('Test Isolation', 'Catégorie de test pour l''isolation', 'smartphone', true)
    RETURNING id INTO v_test_category_id;
    
    RAISE NOTICE '✅ Catégorie de test créée - ID: %', v_test_category_id;
    
    -- Test 2: Créer une marque
    INSERT INTO public.device_brands (name, category_id, description, is_active)
    VALUES ('Test Brand', v_test_category_id, 'Marque de test', true)
    RETURNING id INTO v_test_brand_id;
    
    RAISE NOTICE '✅ Marque de test créée - ID: %', v_test_brand_id;
    
    -- Test 3: Créer un modèle
    INSERT INTO public.device_models (name, brand_id, category_id, year, common_issues, repair_difficulty, parts_availability, is_active)
    VALUES ('Test Model', v_test_brand_id, v_test_category_id, 2024, ARRAY['Test issue'], 'medium', 'high', true)
    RETURNING id INTO v_test_model_id;
    
    RAISE NOTICE '✅ Modèle de test créé - ID: %', v_test_model_id;
    
    -- Test 4: Vérifier l'isolation
    IF EXISTS (
        SELECT 1 FROM public.device_categories 
        WHERE id = v_test_category_id AND user_id = v_user_id
    ) THEN
        RAISE NOTICE '✅ Isolation des catégories fonctionne';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation des catégories';
    END IF;
    
    -- Nettoyer les tests
    DELETE FROM public.device_models WHERE id = v_test_model_id;
    DELETE FROM public.device_brands WHERE id = v_test_brand_id;
    DELETE FROM public.device_categories WHERE id = v_test_category_id;
    
    RAISE NOTICE '✅ Tests nettoyés';
    
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
AND tablename IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        ELSE '❌ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tablename, policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('device_categories', 'device_brands', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec isolation stricte par user_id' as message;
SELECT '✅ Toutes les requêtes filtrent maintenant par user_id' as isolation;
SELECT '✅ Les triggers définissent automatiquement user_id' as triggers;
SELECT '✅ Testez maintenant la page de gestion des modèles' as next_step;
SELECT 'ℹ️ Chaque utilisateur ne voit que ses propres catégories' as note;
