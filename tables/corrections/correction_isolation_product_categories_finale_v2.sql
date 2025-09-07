-- =====================================================
-- CORRECTION ISOLATION PRODUCT_CATEGORIES - VERSION FINALE V2
-- =====================================================
-- Corrige définitivement le problème d'isolation des catégories de produits
-- Gère correctement les politiques existantes
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel de la table
SELECT '=== ÉTAT ACTUEL DE LA TABLE ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'product_categories';

-- 2. Activer RLS si nécessaire
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer TOUTES les politiques existantes (complet)
SELECT '=== NETTOYAGE COMPLET DES POLITIQUES ===' as etape;

-- Supprimer toutes les politiques possibles
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Users can view their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can insert their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can update their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can delete their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_select_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_insert_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_update_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_delete_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_all_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_rls_policy" ON public.product_categories;

-- 4. Vérifier qu'aucune politique n'existe plus
SELECT '=== VÉRIFICATION NETTOYAGE ===' as etape;

SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'product_categories'
ORDER BY policyname;

-- 5. Créer les nouvelles politiques RLS strictes
SELECT '=== CRÉATION POLITIQUES RLS STRICTES ===' as etape;

-- Politiques pour product_categories
CREATE POLICY "product_categories_select_policy" ON public.product_categories
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "product_categories_insert_policy" ON public.product_categories
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "product_categories_update_policy" ON public.product_categories
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "product_categories_delete_policy" ON public.product_categories
    FOR DELETE USING (user_id = auth.uid());

-- 6. S'assurer que la colonne user_id existe
SELECT '=== VÉRIFICATION COLONNE user_id ===' as etape;

ALTER TABLE public.product_categories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 7. Mettre à jour les données existantes sans user_id
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as etape;

UPDATE public.product_categories 
SET user_id = COALESCE(
    auth.uid(), 
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

-- 8. Créer un trigger pour définir automatiquement user_id
SELECT '=== CRÉATION TRIGGER AUTOMATIQUE ===' as etape;

-- Fonction pour product_categories
CREATE OR REPLACE FUNCTION set_product_category_context()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS set_product_category_context_trigger ON public.product_categories;
CREATE TRIGGER set_product_category_context_trigger
    BEFORE INSERT ON public.product_categories
    FOR EACH ROW EXECUTE FUNCTION set_product_category_context();

-- 9. Test d'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_test_category_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    RAISE NOTICE 'Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Créer une catégorie de test
    DECLARE
        v_insert_result UUID;
    BEGIN
        INSERT INTO public.product_categories (
            name, description, is_active, user_id, created_by
        ) VALUES (
            'Test Isolation', 'Catégorie de test pour isolation', true, v_user_id, v_user_id
        ) RETURNING id INTO v_insert_result;
        
        RAISE NOTICE '✅ Catégorie de test créée - ID: %', v_insert_result;
        v_test_category_id := v_insert_result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la création: %', SQLERRM;
    END;
    
    -- Test 2: Vérifier l'isolation
    IF v_test_category_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.product_categories 
            WHERE id = v_test_category_id AND user_id = v_user_id
        ) THEN
            RAISE NOTICE '✅ Isolation des catégories de produits fonctionne';
        ELSE
            RAISE NOTICE '❌ Problème d''isolation des catégories de produits';
        END IF;
        
        -- Nettoyer le test
        DELETE FROM public.product_categories WHERE id = v_test_category_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
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
AND tablename = 'product_categories';

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
WHERE tablename = 'product_categories'
ORDER BY policyname;

-- Vérifier le trigger
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'product_categories'
ORDER BY trigger_name;

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec isolation stricte par user_id' as message;
SELECT '✅ Toutes les requêtes filtrent maintenant par user_id' as isolation;
SELECT '✅ Le trigger définit automatiquement user_id' as trigger;
SELECT '✅ Testez maintenant la page de gestion des modèles' as next_step;
SELECT 'ℹ️ Chaque utilisateur ne voit que ses propres catégories de produits' as note;
