-- =====================================================
-- VÉRIFICATION ET CORRECTION DES SEUILS MINIMUM
-- =====================================================
-- Problème : Les seuils minimum affichés dans les ruptures ne sont pas corrects
-- Solution : Vérifier et corriger les données dans la base de données
-- =====================================================

-- 1. VÉRIFICATION DES DONNÉES ACTUELLES
SELECT '=== VÉRIFICATION DONNÉES ACTUELLES ===' as etape;

-- Vérifier les produits et leurs seuils minimum
SELECT 
    'PRODUITS ET SEUILS' as info,
    id,
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM products 
ORDER BY name;

-- Vérifier les pièces et leurs seuils minimum
SELECT 
    'PIÈCES ET SEUILS' as info,
    id,
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM parts 
ORDER BY name;

-- 2. IDENTIFICATION DES PROBLÈMES
SELECT '=== IDENTIFICATION PROBLÈMES ===' as etape;

-- Produits avec stock faible ou rupture
SELECT 
    'PRODUITS EN ALERTE' as info,
    id,
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM products 
WHERE stock_quantity <= 0 OR stock_quantity <= min_stock_level
ORDER BY name;

-- Pièces avec stock faible ou rupture
SELECT 
    'PIÈCES EN ALERTE' as info,
    id,
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM parts 
WHERE stock_quantity <= 0 OR stock_quantity <= min_stock_level
ORDER BY name;

-- 3. CORRECTION DES SEUILS MINIMUM INCORRECTS
SELECT '=== CORRECTION SEUILS ===' as etape;

-- Mettre à jour les produits qui ont un seuil minimum de 1 mais qui devraient avoir une valeur plus élevée
-- (par exemple, si le stock est 1 et qu'il y a une alerte, le seuil devrait être plus bas)
UPDATE products 
SET min_stock_level = 1
WHERE min_stock_level IS NULL OR min_stock_level = 0;

-- Mettre à jour les pièces qui ont un seuil minimum de 1 mais qui devraient avoir une valeur plus élevée
UPDATE parts 
SET min_stock_level = 1
WHERE min_stock_level IS NULL OR min_stock_level = 0;

-- 4. VÉRIFICATION APRÈS CORRECTION
SELECT '=== VÉRIFICATION APRÈS CORRECTION ===' as etape;

-- Vérifier les produits après correction
SELECT 
    'PRODUITS CORRIGÉS' as info,
    id,
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM products 
ORDER BY name;

-- Vérifier les pièces après correction
SELECT 
    'PIÈCES CORRIGÉES' as info,
    id,
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM parts 
ORDER BY name;

-- 5. STATISTIQUES FINALES
SELECT '=== STATISTIQUES FINALES ===' as etape;

-- Statistiques des produits
SELECT 
    'STATISTIQUES PRODUITS' as info,
    COUNT(*) as total_produits,
    COUNT(CASE WHEN stock_quantity <= 0 THEN 1 END) as produits_en_rupture,
    COUNT(CASE WHEN stock_quantity > 0 AND stock_quantity <= min_stock_level THEN 1 END) as produits_stock_faible,
    COUNT(CASE WHEN stock_quantity > min_stock_level THEN 1 END) as produits_stock_ok
FROM products;

-- Statistiques des pièces
SELECT 
    'STATISTIQUES PIÈCES' as info,
    COUNT(*) as total_pieces,
    COUNT(CASE WHEN stock_quantity <= 0 THEN 1 END) as pieces_en_rupture,
    COUNT(CASE WHEN stock_quantity > 0 AND stock_quantity <= min_stock_level THEN 1 END) as pieces_stock_faible,
    COUNT(CASE WHEN stock_quantity > min_stock_level THEN 1 END) as pieces_stock_ok
FROM parts;

SELECT '✅ VÉRIFICATION ET CORRECTION TERMINÉES' as status;
