-- VÉRIFICATION ET CORRECTION DES VALEURS DE STOCK
-- Script à exécuter dans l'interface SQL de Supabase

-- 1. Vérifier la structure de la table products
SELECT 
  'STRUCTURE DE LA TABLE' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les valeurs actuelles de stock_quantity
SELECT 
  'VALEURS DE STOCK ACTUELLES' as info,
  id,
  name,
  stock_quantity,
  CASE 
    WHEN stock_quantity IS NULL THEN '❌ NULL'
    WHEN stock_quantity = 0 THEN '⚠️ ZÉRO'
    ELSE '✅ VALIDE'
  END as status_stock
FROM public.products
ORDER BY name;

-- 3. Compter les produits par statut de stock
SELECT 
  'STATISTIQUES DE STOCK' as info,
  COUNT(*) as total_produits,
  COUNT(CASE WHEN stock_quantity IS NULL THEN 1 END) as produits_sans_stock,
  COUNT(CASE WHEN stock_quantity = 0 THEN 1 END) as produits_stock_zero,
  COUNT(CASE WHEN stock_quantity > 0 THEN 1 END) as produits_avec_stock
FROM public.products;

-- 4. Corriger les valeurs NULL en 0
UPDATE public.products 
SET stock_quantity = 0 
WHERE stock_quantity IS NULL;

-- 5. Vérification finale
SELECT 
  'CORRECTION TERMINÉE' as info,
  COUNT(*) as total_produits,
  COUNT(CASE WHEN stock_quantity IS NULL THEN 1 END) as produits_sans_stock,
  COUNT(CASE WHEN stock_quantity = 0 THEN 1 END) as produits_stock_zero,
  COUNT(CASE WHEN stock_quantity > 0 THEN 1 END) as produits_avec_stock
FROM public.products;
