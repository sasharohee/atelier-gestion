-- =====================================================
-- CORRECTION STOCK MINIMUM À 1
-- =====================================================
-- Problème : Le stock minimum par défaut est 5, doit être 1
-- Solution : Mettre à jour tous les produits existants
-- =====================================================

-- 1. VÉRIFICATION ACTUELLE
SELECT '=== VÉRIFICATION ACTUELLE ===' as etape;

-- Vérifier les produits avec stock minimum = 5
SELECT 
    'PRODUITS AVEC STOCK MIN = 5' as info,
    id,
    name,
    min_stock_level,
    stock_quantity
FROM products 
WHERE min_stock_level = 5;

-- Compter les produits par niveau de stock minimum
SELECT 
    'RÉPARTITION STOCK MINIMUM' as info,
    min_stock_level,
    COUNT(*) as nombre_produits
FROM products 
GROUP BY min_stock_level
ORDER BY min_stock_level;

-- 2. CORRECTION DES PRODUITS EXISTANTS
SELECT '=== CORRECTION PRODUITS ===' as etape;

-- Mettre à jour tous les produits qui ont un stock minimum de 5
UPDATE products 
SET min_stock_level = 1 
WHERE min_stock_level = 5;

-- Mettre à jour les produits qui ont un stock minimum NULL
UPDATE products 
SET min_stock_level = 1 
WHERE min_stock_level IS NULL;

-- 3. MODIFICATION DE LA VALEUR PAR DÉFAUT
SELECT '=== MODIFICATION VALEUR PAR DÉFAUT ===' as etape;

-- Modifier la valeur par défaut de la colonne
ALTER TABLE products ALTER COLUMN min_stock_level SET DEFAULT 1;

-- 4. VÉRIFICATION APRÈS CORRECTION
SELECT '=== VÉRIFICATION APRÈS CORRECTION ===' as etape;

-- Vérifier que tous les produits ont maintenant un stock minimum de 1
SELECT 
    'PRODUITS CORRIGÉS' as info,
    id,
    name,
    min_stock_level,
    stock_quantity
FROM products 
ORDER BY name;

-- Compter les produits par niveau de stock minimum (après correction)
SELECT 
    'RÉPARTITION FINALE' as info,
    min_stock_level,
    COUNT(*) as nombre_produits
FROM products 
GROUP BY min_stock_level
ORDER BY min_stock_level;

-- 5. VÉRIFICATION DE LA VALEUR PAR DÉFAUT
SELECT 
    'VALEUR PAR DÉFAUT' as info,
    column_name,
    column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
    AND column_name = 'min_stock_level'
    AND table_schema = 'public';

SELECT '✅ CORRECTION STOCK MINIMUM TERMINÉE' as status;
