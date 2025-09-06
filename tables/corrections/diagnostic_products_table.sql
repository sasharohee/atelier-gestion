-- DIAGNOSTIC DE LA TABLE PRODUCTS
-- Script pour vérifier l'état actuel de la table products

-- ============================================================================
-- 1. VÉRIFICATION DE LA STRUCTURE
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
-- 2. VÉRIFICATION DES DONNÉES
-- ============================================================================

-- Vérifier les données existantes
SELECT 
    'DONNÉES PRODUCTS' as section,
    COUNT(*) as nombre_produits,
    COUNT(CASE WHEN stock_quantity IS NULL THEN 1 END) as produits_sans_stock,
    COUNT(CASE WHEN min_stock_level IS NULL THEN 1 END) as produits_sans_seuil,
    COUNT(CASE WHEN is_active IS NULL THEN 1 END) as produits_sans_statut
FROM public.products;

-- ============================================================================
-- 3. VÉRIFICATION DES INDEX
-- ============================================================================

-- Vérifier les index existants
SELECT 
    'INDEX PRODUCTS' as section,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'products'
ORDER BY indexname;

-- ============================================================================
-- 4. VÉRIFICATION RLS
-- ============================================================================

-- Vérifier si RLS est activé
SELECT 
    'STATUT RLS PRODUCTS' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN 'ACTIVÉ'
        ELSE 'DÉSACTIVÉ'
    END as statut
FROM pg_tables 
WHERE tablename = 'products';

-- Vérifier les politiques RLS
SELECT 
    'POLITIQUES RLS PRODUCTS' as section,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'products'
ORDER BY policyname;

-- ============================================================================
-- 5. EXEMPLE DE DONNÉES
-- ============================================================================

-- Afficher quelques exemples de produits
SELECT 
    'EXEMPLES DE PRODUITS' as section,
    id,
    name,
    stock_quantity,
    min_stock_level,
    is_active,
    created_at
FROM public.products
LIMIT 5;

-- ============================================================================
-- 6. RECOMMANDATIONS
-- ============================================================================

SELECT 
    'RECOMMANDATIONS' as section,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'products' 
                AND column_name = 'stock_quantity'
        ) THEN '✅ Colonne stock_quantity existe'
        ELSE '❌ Colonne stock_quantity manquante - Exécuter add_stock_to_products.sql'
    END as stock_quantity_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'products' 
                AND column_name = 'min_stock_level'
        ) THEN '✅ Colonne min_stock_level existe'
        ELSE '❌ Colonne min_stock_level manquante - Exécuter add_stock_to_products.sql'
    END as min_stock_level_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'products' 
                AND column_name = 'is_active'
        ) THEN '✅ Colonne is_active existe'
        ELSE '❌ Colonne is_active manquante - Exécuter add_stock_to_products.sql'
    END as is_active_status;
