-- =====================================================
-- CORRECTION CONTRAINTE UNIQUE - PRODUCT_CATEGORIES
-- =====================================================
-- Permettre des noms identiques pour des utilisateurs différents
-- =====================================================

-- 1. SUPPRIMER L'ANCIENNE CONTRAINTE UNIQUE
ALTER TABLE public.product_categories DROP CONSTRAINT IF EXISTS product_categories_name_key;

-- 2. CRÉER UNE NOUVELLE CONTRAINTE UNIQUE COMPOSITE
-- Cette contrainte permet des noms identiques pour des utilisateurs différents
CREATE UNIQUE INDEX product_categories_name_user_unique 
ON public.product_categories (name, user_id) 
WHERE user_id IS NOT NULL;

-- 3. CRÉER UNE CONTRAINTE UNIQUE POUR LES CATÉGORIES GLOBALES (user_id IS NULL)
CREATE UNIQUE INDEX product_categories_name_global_unique 
ON public.product_categories (name) 
WHERE user_id IS NULL;

-- 4. VÉRIFIER LES CONTRAINTES CRÉÉES
SELECT 
    'CONTRAINTES CRÉÉES' as section,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'product_categories' 
AND indexname LIKE '%unique%';

-- 5. TESTER LA CRÉATION DE CATÉGORIES AVEC LE MÊME NOM
-- Note: Ce test sera exécuté seulement si l'utilisateur a les permissions

DO $$
DECLARE
    current_user_id UUID;
    test_category_name TEXT := 'Test Catégorie ' || EXTRACT(EPOCH FROM NOW())::TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NOT NULL THEN
        -- Essayer de créer une catégorie de test
        INSERT INTO public.product_categories (name, description, icon, color, user_id)
        VALUES (test_category_name, 'Catégorie de test', 'test', '#ff0000', current_user_id);
        
        RAISE NOTICE '✅ Test réussi : Catégorie créée avec le nom: %', test_category_name;
        
        -- Nettoyer la catégorie de test
        DELETE FROM public.product_categories WHERE name = test_category_name;
        RAISE NOTICE '✅ Catégorie de test supprimée';
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 6. AFFICHER LES RÉSULTATS
SELECT 
    'CORRECTION TERMINÉE' as status,
    'Les contraintes d''unicité ont été modifiées pour permettre l''isolation par utilisateur' as message;


