-- =====================================================
-- CORRECTION RAPIDE STOCK MINIMUM À 1
-- =====================================================

-- Mettre à jour tous les produits avec stock minimum = 5
UPDATE products SET min_stock_level = 1 WHERE min_stock_level = 5;

-- Mettre à jour les produits avec stock minimum NULL
UPDATE products SET min_stock_level = 1 WHERE min_stock_level IS NULL;

-- Modifier la valeur par défaut
ALTER TABLE products ALTER COLUMN min_stock_level SET DEFAULT 1;

-- Vérification rapide
SELECT 
    'CORRECTION TERMINÉE' as status,
    COUNT(*) as total_produits,
    COUNT(CASE WHEN min_stock_level = 1 THEN 1 END) as produits_avec_stock_min_1
FROM products;

SELECT '✅ Stock minimum corrigé à 1' as resultat;
