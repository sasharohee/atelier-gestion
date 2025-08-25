-- =====================================================
-- CORRECTION COLONNE IS_ACTIVE - TABLE PRODUCTS
-- =====================================================
-- Objectif: Ajouter la colonne is_active manquante à la table products
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION STRUCTURE ACTUELLE
SELECT '=== 1. VÉRIFICATION STRUCTURE ACTUELLE ===' as section;

-- Vérifier la structure actuelle de la table products
SELECT 
    'Structure actuelle products' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'products'
ORDER BY ordinal_position;

-- 2. AJOUT DE LA COLONNE IS_ACTIVE
SELECT '=== 2. AJOUT COLONNE IS_ACTIVE ===' as section;

-- Ajouter la colonne is_active si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE '✅ Colonne is_active ajoutée à products avec valeur par défaut TRUE';
    ELSE
        RAISE NOTICE '✅ Colonne is_active existe déjà dans products';
    END IF;
END $$;

-- 3. VÉRIFICATION STRUCTURE APRÈS MODIFICATION
SELECT '=== 3. VÉRIFICATION STRUCTURE APRÈS MODIFICATION ===' as section;

-- Vérifier la nouvelle structure de la table products
SELECT 
    'Nouvelle structure products' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'products'
ORDER BY ordinal_position;

-- 4. MISE À JOUR DES DONNÉES EXISTANTES
SELECT '=== 4. MISE À JOUR DONNÉES EXISTANTES ===' as section;

-- Mettre à jour les enregistrements existants pour avoir is_active = TRUE
UPDATE public.products 
SET is_active = TRUE 
WHERE is_active IS NULL;

-- Vérifier le nombre d'enregistrements mis à jour
SELECT 
    'Données mises à jour' as info,
    COUNT(*) as nombre_produits,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) as produits_actifs,
    COUNT(CASE WHEN is_active = FALSE THEN 1 END) as produits_inactifs,
    COUNT(CASE WHEN is_active IS NULL THEN 1 END) as produits_sans_statut
FROM public.products;

-- 5. TEST D'INSERTION
SELECT '=== 5. TEST D''INSERTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_id UUID;
    test_is_active BOOLEAN;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion avec is_active pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans products avec is_active
    INSERT INTO public.products (name, description, category, price, stock_quantity, is_active)
    VALUES ('Test Produit', 'Description test', 'Test', 99.99, 10, TRUE)
    RETURNING id, is_active INTO test_id, test_is_active;
    
    RAISE NOTICE '✅ Produit créé avec ID: % et is_active: %', test_id, test_is_active;
    
    -- Vérifier que le produit appartient à l'utilisateur actuel
    SELECT user_id INTO current_user_id
    FROM public.products 
    WHERE id = test_id;
    
    RAISE NOTICE '✅ Produit créé par: %', current_user_id;
    
    -- Nettoyer
    DELETE FROM public.products WHERE id = test_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 6. VÉRIFICATION CACHE POSTGREST
SELECT '=== 6. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 7. VÉRIFICATION FINALE
SELECT '=== 7. VÉRIFICATION FINALE ===' as section;

-- Vérifier que la colonne is_active est bien présente
SELECT 
    'Vérification finale' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'is_active'
        ) THEN '✅ Colonne is_active présente'
        ELSE '❌ Colonne is_active manquante'
    END as status_colonne;

-- Vérifier les données
SELECT 
    'Données finales' as info,
    COUNT(*) as nombre_produits,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) as produits_actifs,
    COUNT(CASE WHEN is_active = FALSE THEN 1 END) as produits_inactifs
FROM public.products;

SELECT 'CORRECTION COLONNE IS_ACTIVE TERMINÉE' as status;
