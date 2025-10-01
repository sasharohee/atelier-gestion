-- ============================================================================
-- MODIFICATION POUR SUPPORTER PLUSIEURS CATÉGORIES PAR MARQUE
-- ============================================================================
-- Date: $(date)
-- Description: Permettre à une marque d'être associée à plusieurs catégories
-- ============================================================================

-- 1. CRÉER LA TABLE DE LIAISON MANY-TO-MANY
-- ============================================================================
SELECT '=== CRÉATION TABLE DE LIAISON ===' as section;

CREATE TABLE IF NOT EXISTS public.brand_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand_id UUID REFERENCES public.device_brands(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contrainte d'unicité pour éviter les doublons
    UNIQUE(brand_id, category_id)
);

-- 2. ACTIVER RLS SUR LA NOUVELLE TABLE
-- ============================================================================
SELECT '=== ACTIVATION RLS brand_categories ===' as section;

ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;

-- 3. CRÉER LES POLITIQUES RLS POUR brand_categories
-- ============================================================================
SELECT '=== POLITIQUES RLS brand_categories ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own brand categories" ON public.brand_categories;
DROP POLICY IF EXISTS "Users can insert their own brand categories" ON public.brand_categories;
DROP POLICY IF EXISTS "Users can update their own brand categories" ON public.brand_categories;
DROP POLICY IF EXISTS "Users can delete their own brand categories" ON public.brand_categories;

-- Créer les nouvelles politiques
CREATE POLICY "Users can view their own brand categories" ON public.brand_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own brand categories" ON public.brand_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own brand categories" ON public.brand_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own brand categories" ON public.brand_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 4. CRÉER LE TRIGGER POUR L'ISOLATION
-- ============================================================================
SELECT '=== CRÉATION TRIGGER brand_categories ===' as section;

-- Fonction pour définir automatiquement user_id et created_by
CREATE OR REPLACE FUNCTION set_brand_categories_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS set_brand_categories_context_trigger ON public.brand_categories;

-- Créer le nouveau trigger
CREATE TRIGGER set_brand_categories_context_trigger
    BEFORE INSERT ON public.brand_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_brand_categories_context();

-- 5. MIGRER LES DONNÉES EXISTANTES
-- ============================================================================
SELECT '=== MIGRATION DES DONNÉES EXISTANTES ===' as section;

-- Insérer les relations existantes dans la nouvelle table
INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
SELECT 
    db.id as brand_id,
    db.category_id,
    db.user_id,
    db.created_by
FROM public.device_brands db
WHERE db.category_id IS NOT NULL
ON CONFLICT (brand_id, category_id) DO NOTHING;

-- 6. CRÉER LES INDEX POUR LES PERFORMANCES
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

CREATE INDEX IF NOT EXISTS idx_brand_categories_brand_id ON public.brand_categories(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_categories_category_id ON public.brand_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_brand_categories_user_id ON public.brand_categories(user_id);

-- 7. CRÉER UNE VUE POUR FACILITER LES REQUÊTES
-- ============================================================================
SELECT '=== CRÉATION VUE brand_with_categories ===' as section;

-- Supprimer la vue si elle existe
DROP VIEW IF EXISTS public.brand_with_categories;

-- Créer la vue
CREATE VIEW public.brand_with_categories AS
SELECT 
    db.id,
    db.name,
    db.description,
    db.logo,
    db.is_active,
    db.user_id,
    db.created_by,
    db.created_at,
    db.updated_at,
    -- Agréger les catégories en JSON
    COALESCE(
        json_agg(
            json_build_object(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description,
                'icon', dc.icon
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands db
LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.created_at, db.updated_at;

-- Activer RLS sur la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- 8. CRÉER LES FONCTIONS UTILITAIRES
-- ============================================================================
SELECT '=== CRÉATION FONCTIONS UTILITAIRES ===' as section;

-- Fonction pour ajouter une catégorie à une marque
CREATE OR REPLACE FUNCTION add_category_to_brand(
    p_brand_id UUID,
    p_category_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Vérifier que la marque appartient à l'utilisateur
    IF NOT EXISTS (
        SELECT 1 FROM public.device_brands 
        WHERE id = p_brand_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;
    
    -- Vérifier que la catégorie appartient à l'utilisateur
    IF NOT EXISTS (
        SELECT 1 FROM public.device_categories 
        WHERE id = p_category_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Catégorie non trouvée ou non autorisée';
    END IF;
    
    -- Ajouter la relation
    INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
    VALUES (p_brand_id, p_category_id, v_user_id, v_user_id)
    ON CONFLICT (brand_id, category_id) DO NOTHING;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour supprimer une catégorie d'une marque
CREATE OR REPLACE FUNCTION remove_category_from_brand(
    p_brand_id UUID,
    p_category_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Supprimer la relation
    DELETE FROM public.brand_categories 
    WHERE brand_id = p_brand_id 
    AND category_id = p_category_id 
    AND user_id = v_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour toutes les catégories d'une marque
CREATE OR REPLACE FUNCTION update_brand_categories(
    p_brand_id UUID,
    p_category_ids UUID[]
) RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Vérifier que la marque appartient à l'utilisateur
    IF NOT EXISTS (
        SELECT 1 FROM public.device_brands 
        WHERE id = p_brand_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;
    
    -- Supprimer toutes les relations existantes
    DELETE FROM public.brand_categories 
    WHERE brand_id = p_brand_id AND user_id = v_user_id;
    
    -- Ajouter les nouvelles relations
    FOREACH v_category_id IN ARRAY p_category_ids
    LOOP
        -- Vérifier que la catégorie appartient à l'utilisateur
        IF EXISTS (
            SELECT 1 FROM public.device_categories 
            WHERE id = v_category_id AND user_id = v_user_id
        ) THEN
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            VALUES (p_brand_id, v_category_id, v_user_id, v_user_id);
        END IF;
    END LOOP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. TEST DE FONCTIONNEMENT
-- ============================================================================
SELECT '=== TEST DE FONCTIONNEMENT ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_brand_id UUID;
    v_category_id UUID;
    v_test_result BOOLEAN;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        RAISE NOTICE '🧪 Test avec l''utilisateur: %', v_user_id;
        
        -- Test 1: Vérifier que la vue fonctionne
        BEGIN
            SELECT COUNT(*) INTO v_test_result FROM public.brand_with_categories;
            RAISE NOTICE '✅ Test réussi : Vue brand_with_categories accessible - % enregistrements', v_test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors du test de la vue: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 10. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure des nouvelles tables
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('brand_categories', 'brand_with_categories')
ORDER BY table_name, ordinal_position;

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'brand_categories'
ORDER BY policyname;

-- Vérifier les fonctions créées
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%brand%category%'
ORDER BY routine_name;

DO $$
BEGIN
    RAISE NOTICE '🎉 Modification terminée !';
    RAISE NOTICE '✅ Table brand_categories créée avec relation many-to-many';
    RAISE NOTICE '✅ Vue brand_with_categories créée pour faciliter les requêtes';
    RAISE NOTICE '✅ Fonctions utilitaires créées pour gérer les catégories';
    RAISE NOTICE '✅ Les données existantes ont été migrées';
    RAISE NOTICE '✅ Vous pouvez maintenant associer plusieurs catégories à une marque';
END $$;
