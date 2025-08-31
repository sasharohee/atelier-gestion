-- =====================================================
-- CORRECTION ISOLATION DÉFINITIVE - PRODUCT_CATEGORIES
-- =====================================================
-- Solution utilisant l'ID utilisateur pour l'isolation
-- =====================================================

-- 1. AJOUTER LA COLONNE USER_ID SI ELLE N'EXISTE PAS
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_categories' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.product_categories ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà';
    END IF;
END $$;

-- 2. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES
DROP POLICY IF EXISTS "product_categories_select_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_insert_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_update_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_delete_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_isolation" ON public.product_categories;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.product_categories;

-- 3. CRÉER DES POLITIQUES RLS BASÉES SUR L'UTILISATEUR CONNECTÉ

-- Politique de lecture - Seules les catégories de l'utilisateur connecté
CREATE POLICY "product_categories_select_policy" ON public.product_categories
    FOR SELECT USING (
        user_id = auth.uid() OR 
        user_id IS NULL  -- Permettre l'accès aux catégories par défaut
    );

-- Politique d'insertion - L'utilisateur connecté peut créer ses catégories
CREATE POLICY "product_categories_insert_policy" ON public.product_categories
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
    );

-- Politique de mise à jour - L'utilisateur connecté peut modifier ses catégories
CREATE POLICY "product_categories_update_policy" ON public.product_categories
    FOR UPDATE USING (
        user_id = auth.uid()
    );

-- Politique de suppression - L'utilisateur connecté peut supprimer ses catégories
CREATE POLICY "product_categories_delete_policy" ON public.product_categories
    FOR DELETE USING (
        user_id = auth.uid()
    );

-- 4. CRÉER UN TRIGGER POUR ASSIGNER AUTOMATIQUEMENT L'USER_ID
CREATE OR REPLACE FUNCTION set_product_categories_user_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Assigner automatiquement l'ID de l'utilisateur connecté
    NEW.user_id := auth.uid();
    
    -- Si pas d'utilisateur connecté, utiliser un ID par défaut
    IF NEW.user_id IS NULL THEN
        NEW.user_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS set_product_categories_user_id_trigger ON public.product_categories;
CREATE TRIGGER set_product_categories_user_id_trigger
    BEFORE INSERT ON public.product_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_product_categories_user_id();

-- 5. METTRE À JOUR LES CATÉGORIES EXISTANTES AVEC L'USER_ID ACTUEL
-- Note: Cette mise à jour assignera toutes les catégories existantes à l'utilisateur actuel
-- ou à un utilisateur par défaut si aucun utilisateur n'est connecté

DO $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    -- Si pas d'utilisateur connecté, utiliser un ID par défaut
    IF current_user_id IS NULL THEN
        current_user_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Mettre à jour les catégories existantes
    UPDATE public.product_categories 
    SET user_id = current_user_id
    WHERE user_id IS NULL;
    
    RAISE NOTICE '✅ Catégories existantes mises à jour avec user_id: %', current_user_id;
END $$;

-- 6. CRÉER DES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON public.product_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_name ON public.product_categories(name);
CREATE INDEX IF NOT EXISTS idx_product_categories_active ON public.product_categories(is_active);

-- 7. VÉRIFICATION FINALE
DO $$
DECLARE
    current_user_id UUID;
    total_categories INTEGER;
    user_categories INTEGER;
    null_user_categories INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    -- Compter les catégories
    SELECT COUNT(*) INTO total_categories FROM public.product_categories;
    
    -- Compter les catégories de l'utilisateur actuel
    SELECT COUNT(*) INTO user_categories 
    FROM public.product_categories 
    WHERE user_id = current_user_id;
    
    -- Compter les catégories sans user_id
    SELECT COUNT(*) INTO null_user_categories 
    FROM public.product_categories 
    WHERE user_id IS NULL;
    
    RAISE NOTICE '=== VÉRIFICATION FINALE ===';
    RAISE NOTICE 'Utilisateur actuel: %', current_user_id;
    RAISE NOTICE 'Total catégories: %', total_categories;
    RAISE NOTICE 'Catégories de l''utilisateur: %', user_categories;
    RAISE NOTICE 'Catégories sans user_id: %', null_user_categories;
    
    IF user_categories > 0 THEN
        RAISE NOTICE '✅ Isolation par utilisateur activée';
    ELSE
        RAISE NOTICE '⚠️ Aucune catégorie trouvée pour l''utilisateur actuel';
    END IF;
END $$;

-- 8. AFFICHER LES RÉSULTATS
SELECT 
    'RÉSULTATS FINAUX' as section,
    COUNT(*) as total_categories,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as categories_avec_user_id,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as categories_sans_user_id
FROM public.product_categories;

SELECT 
    'CATÉGORIES PAR UTILISATEUR' as section,
    COALESCE(user_id::text, 'NULL') as user_id,
    COUNT(*) as nombre_categories
FROM public.product_categories
GROUP BY user_id
ORDER BY user_id;


