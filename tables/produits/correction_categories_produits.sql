-- Correction des catégories manquantes dans la table products
-- Ce script met à jour tous les produits qui ont une catégorie NULL ou vide

-- 1. Voir les produits avec des catégories manquantes
SELECT 
    id,
    name,
    category,
    CASE 
        WHEN category IS NULL OR category = '' THEN 'CATÉGORIE MANQUANTE'
        ELSE category
    END as status
FROM products 
WHERE category IS NULL OR category = '';

-- 2. Mettre à jour les produits avec une catégorie par défaut
UPDATE products 
SET 
    category = 'accessoire',
    updated_at = NOW()
WHERE category IS NULL OR category = '';

-- 3. Vérifier que la correction a été appliquée
SELECT 
    id,
    name,
    category,
    'CORRIGÉ' as status
FROM products 
WHERE category = 'accessoire' 
AND updated_at >= NOW() - INTERVAL '1 minute';

-- 4. Vérifier qu'il n'y a plus de catégories manquantes
SELECT 
    COUNT(*) as produits_sans_categorie
FROM products 
WHERE category IS NULL OR category = '';

-- 5. Statistiques des catégories
SELECT 
    category,
    COUNT(*) as nombre_produits
FROM products 
GROUP BY category 
ORDER BY nombre_produits DESC;
