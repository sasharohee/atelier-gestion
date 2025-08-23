-- AJOUT DE LA GESTION DU STOCK AUX PRODUITS
-- Script pour ajouter les colonnes de stock à la table products

-- ============================================================================
-- 1. VÉRIFICATION DE LA STRUCTURE ACTUELLE
-- ============================================================================

-- Vérifier la structure actuelle de la table products
SELECT 
    'STRUCTURE ACTUELLE PRODUCTS' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. AJOUT DES COLONNES DE STOCK
-- ============================================================================

-- Ajouter la colonne stockQuantity si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'stock_quantity'
    ) THEN
        ALTER TABLE public.products ADD COLUMN stock_quantity INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Colonne stock_quantity ajoutée à la table products';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne stock_quantity existe déjà';
    END IF;
END $$;

-- Ajouter la colonne minStockLevel si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'min_stock_level'
    ) THEN
        ALTER TABLE public.products ADD COLUMN min_stock_level INTEGER DEFAULT 5;
        RAISE NOTICE '✅ Colonne min_stock_level ajoutée à la table products';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne min_stock_level existe déjà';
    END IF;
END $$;

-- Ajouter la colonne isActive si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE '✅ Colonne is_active ajoutée à la table products';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne is_active existe déjà';
    END IF;
END $$;

-- ============================================================================
-- 3. CRÉATION DES INDEX
-- ============================================================================

-- Index pour les performances sur le stock
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON public.products(stock_quantity);
CREATE INDEX IF NOT EXISTS idx_products_min_stock_level ON public.products(min_stock_level);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(is_active);

-- ============================================================================
-- 4. MISE À JOUR DES DONNÉES EXISTANTES
-- ============================================================================

-- Mettre à jour les produits existants avec des valeurs par défaut
UPDATE public.products 
SET 
    stock_quantity = COALESCE(stock_quantity, 10),
    min_stock_level = COALESCE(min_stock_level, 5),
    is_active = COALESCE(is_active, TRUE)
WHERE stock_quantity IS NULL OR min_stock_level IS NULL OR is_active IS NULL;

-- ============================================================================
-- 5. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier la nouvelle structure
SELECT 
    'NOUVELLE STRUCTURE PRODUCTS' as section,
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
    'DONNÉES PRODUCTS' as section,
    COUNT(*) as nombre_produits,
    COUNT(CASE WHEN stock_quantity <= 0 THEN 1 END) as produits_en_rupture,
    COUNT(CASE WHEN stock_quantity <= min_stock_level THEN 1 END) as produits_stock_faible,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) as produits_actifs
FROM public.products;

-- ============================================================================
-- 6. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 GESTION DU STOCK AJOUTÉE' as status,
    'La table products a été mise à jour avec la gestion du stock' as message,
    'Les produits peuvent maintenant être gérés avec des alertes de stock' as action;
