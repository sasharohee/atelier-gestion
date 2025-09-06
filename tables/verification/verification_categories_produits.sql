-- VÉRIFICATION DE L'INSTALLATION DES NOUVELLES CATÉGORIES
-- Script à exécuter après ajout_categories_produits.sql

-- ============================================================================
-- 1. VÉRIFICATION DES TABLES
-- ============================================================================

-- Vérifier que toutes les tables existent
SELECT 
    'VÉRIFICATION DES TABLES' as section,
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ EXISTE'
        ELSE '❌ MANQUANTE'
    END as status
FROM (
    SELECT 'product_categories' as table_name
    UNION SELECT 'sale_items'
    UNION SELECT 'products'
    UNION SELECT 'sales'
) t
WHERE EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = t.table_name
);

-- ============================================================================
-- 2. VÉRIFICATION DES CATÉGORIES
-- ============================================================================

-- Vérifier que toutes les catégories ont été créées
SELECT 
    'CATÉGORIES CRÉÉES' as section,
    name,
    description,
    sort_order,
    CASE 
        WHEN name IS NOT NULL THEN '✅ AJOUTÉE'
        ELSE '❌ MANQUANTE'
    END as status
FROM public.product_categories
ORDER BY sort_order;

-- ============================================================================
-- 3. VÉRIFICATION DES CONTRAINTES
-- ============================================================================

-- Vérifier la contrainte sur la table products
SELECT 
    'CONTRAINTE PRODUCTS' as section,
    constraint_name,
    constraint_type,
    CASE 
        WHEN constraint_name IS NOT NULL THEN '✅ ACTIVE'
        ELSE '❌ MANQUANTE'
    END as status
FROM information_schema.table_constraints 
WHERE table_name = 'products' 
    AND table_schema = 'public'
    AND constraint_name = 'products_category_check';

-- ============================================================================
-- 4. VÉRIFICATION DES TRIGGERS
-- ============================================================================

-- Vérifier que le trigger a été créé
SELECT 
    'TRIGGER SALE_ITEMS' as section,
    trigger_name,
    event_manipulation,
    CASE 
        WHEN trigger_name IS NOT NULL THEN '✅ ACTIF'
        ELSE '❌ MANQUANT'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'sale_items'
    AND trigger_schema = 'public'
    AND trigger_name = 'trigger_update_sale_item_category';

-- ============================================================================
-- 5. VÉRIFICATION DES VUES
-- ============================================================================

-- Vérifier que la vue a été créée
SELECT 
    'VUE STATISTIQUES' as section,
    table_name as vue_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ CRÉÉE'
        ELSE '❌ MANQUANTE'
    END as status
FROM information_schema.views 
WHERE table_schema = 'public'
    AND table_name = 'sales_by_category';

-- ============================================================================
-- 6. VÉRIFICATION DES INDEX
-- ============================================================================

-- Vérifier que les index ont été créés
SELECT 
    'INDEX CRÉÉS' as section,
    indexname,
    CASE 
        WHEN indexname IS NOT NULL THEN '✅ ACTIF'
        ELSE '❌ MANQUANT'
    END as status
FROM pg_indexes 
WHERE tablename IN ('products', 'sale_items', 'sales')
    AND schemaname = 'public'
    AND indexname LIKE '%category%';

-- ============================================================================
-- 7. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

-- Vérifier les politiques RLS sur sale_items
SELECT 
    'POLITIQUES RLS' as section,
    policyname,
    cmd,
    CASE 
        WHEN policyname IS NOT NULL THEN '✅ ACTIVE'
        ELSE '❌ MANQUANTE'
    END as status
FROM pg_policies 
WHERE tablename = 'sale_items'
    AND schemaname = 'public';

-- ============================================================================
-- 8. TEST DE VALIDATION DES CATÉGORIES
-- ============================================================================

-- Tester l'insertion d'un produit avec une nouvelle catégorie
DO $$
DECLARE
    test_product_id UUID;
BEGIN
    -- Insérer un produit de test
    INSERT INTO public.products (name, description, category, price, stock_quantity, is_active)
    VALUES ('Test Smartphone', 'Produit de test pour validation', 'smartphone', 299.99, 5, true)
    RETURNING id INTO test_product_id;
    
    -- Vérifier que l'insertion a réussi
    IF test_product_id IS NOT NULL THEN
        RAISE NOTICE '✅ TEST RÉUSSI: Produit avec catégorie smartphone créé (ID: %)', test_product_id;
        
        -- Nettoyer le produit de test
        DELETE FROM public.products WHERE id = test_product_id;
        RAISE NOTICE '✅ NETTOYAGE: Produit de test supprimé';
    ELSE
        RAISE NOTICE '❌ TEST ÉCHOUÉ: Impossible de créer un produit avec la catégorie smartphone';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ ERREUR LORS DU TEST: %', SQLERRM;
END $$;

-- ============================================================================
-- 9. RÉSUMÉ FINAL
-- ============================================================================

SELECT 
    '🎉 RÉSUMÉ FINAL' as section,
    'Installation des nouvelles catégories terminée' as message,
    'Vérifiez les résultats ci-dessus pour confirmer le succès' as instruction;
