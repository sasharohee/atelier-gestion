-- NETTOYAGE - PRODUITS AVEC IDs INVALIDES
-- Script à exécuter dans l'interface SQL de Supabase

-- 1. Identifier les produits problématiques
SELECT 
  'PRODUITS PROBLÉMATIQUES IDENTIFIÉS' as status,
  COUNT(*) as nombre_produits_problematiques
FROM public.products 
WHERE id IS NULL 
   OR id::text = '' 
   OR id::text = 'undefined'
   OR name IS NULL
   OR name = '';

-- 2. Supprimer les produits avec des IDs invalides
DELETE FROM public.products 
WHERE id IS NULL 
   OR id::text = '' 
   OR id::text = 'undefined'
   OR name IS NULL
   OR name = '';

-- 3. Vérifier qu'il reste des produits valides
SELECT 
  'NETTOYAGE TERMINÉ' as status,
  COUNT(*) as nombre_produits_restants,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as produits_avec_stock,
  COUNT(CASE WHEN is_active = TRUE THEN 1 END) as produits_actifs
FROM public.products;

-- 4. Vérifier la structure de la table
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
AND column_name = 'id';
