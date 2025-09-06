-- CORRECTION RAPIDE DE LA TABLE PRODUCTS
-- Script simple pour ajouter les colonnes manquantes

-- ============================================================================
-- 1. AJOUT DES COLONNES MANQUANTES
-- ============================================================================

-- Ajouter stock_quantity si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'stock_quantity'
    ) THEN
        ALTER TABLE public.products ADD COLUMN stock_quantity INTEGER DEFAULT 10;
        RAISE NOTICE '✅ Colonne stock_quantity ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne stock_quantity existe déjà';
    END IF;
END $$;

-- Ajouter min_stock_level si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'min_stock_level'
    ) THEN
        ALTER TABLE public.products ADD COLUMN min_stock_level INTEGER DEFAULT 1;
        RAISE NOTICE '✅ Colonne min_stock_level ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne min_stock_level existe déjà';
    END IF;
END $$;

-- Ajouter is_active si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE '✅ Colonne is_active ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne is_active existe déjà';
    END IF;
END $$;

-- ============================================================================
-- 2. MISE À JOUR DES DONNÉES EXISTANTES
-- ============================================================================

-- Mettre à jour les valeurs NULL
UPDATE public.products 
SET 
    stock_quantity = COALESCE(stock_quantity, 10),
    min_stock_level = COALESCE(min_stock_level, 5),
    is_active = COALESCE(is_active, TRUE)
WHERE stock_quantity IS NULL OR min_stock_level IS NULL OR is_active IS NULL;

-- ============================================================================
-- 3. VÉRIFICATION
-- ============================================================================

-- Vérifier la structure finale
SELECT 
    'STRUCTURE FINALE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;

-- Vérifier les données
SELECT 
    'DONNÉES FINALES' as section,
    COUNT(*) as nombre_produits,
    COUNT(CASE WHEN stock_quantity IS NULL THEN 1 END) as produits_sans_stock,
    COUNT(CASE WHEN min_stock_level IS NULL THEN 1 END) as produits_sans_seuil,
    COUNT(CASE WHEN is_active IS NULL THEN 1 END) as produits_sans_statut
FROM public.products;

-- ============================================================================
-- 4. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 CORRECTION TERMINÉE' as status,
    'La table products a été corrigée avec succès' as message,
    'Vous pouvez maintenant créer des ventes sans erreur' as action;
