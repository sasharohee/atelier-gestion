-- =====================================================
-- SUPPRESSION DES CATÉGORIES PAR DÉFAUT
-- =====================================================
-- Date: 2025-01-23
-- Objectif: Supprimer les catégories d'appareils par défaut
-- =====================================================

-- 1. AFFICHER LES CATÉGORIES ACTUELLES
SELECT '=== CATÉGORIES ACTUELLES ===' as section;

SELECT 
    id,
    name,
    description,
    is_active,
    created_at
FROM public.product_categories
ORDER BY name;

-- 2. SUPPRIMER LES CATÉGORIES PAR DÉFAUT
SELECT '=== SUPPRESSION DES CATÉGORIES PAR DÉFAUT ===' as section;

-- Supprimer les catégories spécifiques
DELETE FROM public.product_categories 
WHERE name IN (
    'Smartphones',
    'Tablettes', 
    'Ordinateurs portables',
    'Ordinateurs fixes'
);

-- 3. VÉRIFIER LA SUPPRESSION
SELECT '=== VÉRIFICATION DE LA SUPPRESSION ===' as section;

SELECT 
    'Catégories supprimées' as action,
    COUNT(*) as nombre_supprime
FROM public.product_categories 
WHERE name IN (
    'Smartphones',
    'Tablettes', 
    'Ordinateurs portables',
    'Ordinateurs fixes'
);

-- 4. AFFICHER LES CATÉGORIES RESTANTES
SELECT '=== CATÉGORIES RESTANTES ===' as section;

SELECT 
    id,
    name,
    description,
    is_active,
    created_at
FROM public.product_categories
ORDER BY name;

-- 5. STATISTIQUES FINALES
SELECT '=== STATISTIQUES FINALES ===' as section;

SELECT 
    'Total catégories restantes' as statut,
    COUNT(*) as nombre
FROM public.product_categories

UNION ALL

SELECT 
    'Catégories actives' as statut,
    COUNT(*) as nombre
FROM public.product_categories
WHERE is_active = true

UNION ALL

SELECT 
    'Catégories inactives' as statut,
    COUNT(*) as nombre
FROM public.product_categories
WHERE is_active = false;

-- 6. MESSAGE DE CONFIRMATION
SELECT '=== CONFIRMATION ===' as section,
       'Les catégories par défaut ont été supprimées avec succès.' as message;

