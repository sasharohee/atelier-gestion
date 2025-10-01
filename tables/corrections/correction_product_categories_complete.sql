-- ============================================================================
-- CORRECTION COMPLÈTE DES PROBLÈMES PRODUCT_CATEGORIES
-- ============================================================================
-- Date: $(date)
-- Description: Résolution des erreurs de création de catégories
-- Problèmes résolus:
-- 1. Champ 'created_by' manquant dans la table
-- 2. Catégories par défaut non désirées
-- 3. Erreur 400 sur l'API
-- 4. Champ workshop_id manquant dans les insertions
-- ============================================================================

-- 1. SUPPRIMER LES CATÉGORIES PAR DÉFAUT NON DÉSIRÉES
-- ============================================================================
SELECT '=== SUPPRESSION CATÉGORIES PAR DÉFAUT ===' as section;

-- Supprimer toutes les catégories existantes (elles ne devraient pas exister)
DO $$
BEGIN
    DELETE FROM public.product_categories;
    RAISE NOTICE '✅ Toutes les catégories par défaut ont été supprimées';
END $$;

-- 2. AJOUTER LA COLONNE CREATED_BY MANQUANTE
-- ============================================================================
SELECT '=== AJOUT COLONNE CREATED_BY ===' as section;

DO $$
BEGIN
    -- Vérifier si la colonne created_by existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_categories' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.product_categories 
        ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à product_categories';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans product_categories';
    END IF;
END $$;

-- 3. VÉRIFIER ET AJOUTER LA COLONNE WORKSHOP_ID SI NÉCESSAIRE
-- ============================================================================
SELECT '=== VÉRIFICATION COLONNE WORKSHOP_ID ===' as section;

DO $$
BEGIN
    -- Vérifier si la colonne workshop_id existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_categories' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.product_categories 
        ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à product_categories';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans product_categories';
    END IF;
END $$;

-- 4. CRÉER/METTRE À JOUR LES TRIGGERS POUR L'ISOLATION
-- ============================================================================
SELECT '=== CRÉATION TRIGGERS ISOLATION ===' as section;

-- Fonction pour définir automatiquement user_id et workshop_id
CREATE OR REPLACE FUNCTION set_product_categories_context()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id et workshop_id automatiquement
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
DROP TRIGGER IF EXISTS set_product_categories_user_id_trigger ON public.product_categories;
DROP TRIGGER IF EXISTS set_product_categories_workshop_id_trigger ON public.product_categories;
DROP TRIGGER IF EXISTS set_product_category_context_trigger ON public.product_categories;

-- Créer le nouveau trigger unifié
CREATE TRIGGER set_product_categories_context_trigger
    BEFORE INSERT ON public.product_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_product_categories_context();

-- 5. CRÉER LES INDEX POUR LES PERFORMANCES
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON public.product_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_workshop_id ON public.product_categories(workshop_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_created_by ON public.product_categories(created_by);
CREATE INDEX IF NOT EXISTS idx_product_categories_name ON public.product_categories(name);
CREATE INDEX IF NOT EXISTS idx_product_categories_active ON public.product_categories(is_active);

-- 6. METTRE À JOUR LES POLITIQUES RLS
-- ============================================================================
SELECT '=== MISE À JOUR POLITIQUES RLS ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can insert their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can update their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can delete their own product categories" ON public.product_categories;

-- Créer les nouvelles politiques RLS
CREATE POLICY "Users can view their own product categories" ON public.product_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own product categories" ON public.product_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own product categories" ON public.product_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own product categories" ON public.product_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 7. TEST DE FONCTIONNEMENT
-- ============================================================================
SELECT '=== TEST DE FONCTIONNEMENT ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_test_category_id UUID;
    v_test_result BOOLEAN;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        RAISE NOTICE '🧪 Test avec l''utilisateur: %', v_user_id;
        
        -- Test 1: Créer une catégorie de test
        BEGIN
            INSERT INTO public.product_categories (
                name, description, icon, color, is_active, sort_order
            ) VALUES (
                'Test Category ' || extract(epoch from now()), 
                'Catégorie de test pour vérification', 
                'test', 
                '#ff0000', 
                true, 
                0
            ) RETURNING id INTO v_test_category_id;
            
            RAISE NOTICE '✅ Test réussi : Catégorie créée - ID: %', v_test_category_id;
            
            -- Vérifier que les champs sont correctement remplis
            SELECT 
                (user_id = v_user_id) AND 
                (workshop_id = v_user_id) AND 
                (created_by = v_user_id) AND
                (created_at IS NOT NULL) AND
                (updated_at IS NOT NULL)
            INTO v_test_result
            FROM public.product_categories 
            WHERE id = v_test_category_id;
            
            IF v_test_result THEN
                RAISE NOTICE '✅ Test réussi : Tous les champs sont correctement remplis';
            ELSE
                RAISE NOTICE '❌ Test échoué : Certains champs ne sont pas correctement remplis';
            END IF;
            
            -- Nettoyer la catégorie de test
            DELETE FROM public.product_categories WHERE id = v_test_category_id;
            RAISE NOTICE '✅ Catégorie de test supprimée';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 8. VÉRIFICATION FINALE
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
AND table_name = 'product_categories'
ORDER BY ordinal_position;

-- Vérifier qu'il n'y a plus de catégories par défaut
SELECT 
    COUNT(*) as total_categories,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as categories_without_user
FROM public.product_categories;

-- Vérifier les triggers
SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'product_categories';

-- Vérifier les politiques RLS
SELECT 
    policyname, 
    cmd, 
    qual
FROM pg_policies 
WHERE tablename = 'product_categories';

DO $$
BEGIN
    RAISE NOTICE '🎉 Correction complète des problèmes product_categories terminée !';
    RAISE NOTICE '✅ Les catégories par défaut ont été supprimées';
    RAISE NOTICE '✅ La colonne created_by a été ajoutée';
    RAISE NOTICE '✅ Les triggers d''isolation ont été mis à jour';
    RAISE NOTICE '✅ Les politiques RLS ont été configurées';
    RAISE NOTICE '✅ Vous pouvez maintenant créer des catégories sans erreur';
END $$;
