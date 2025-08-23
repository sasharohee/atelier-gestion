-- DIAGNOSTIC SIMPLIFIÉ - VÉRIFICATION DES PRODUITS
-- Script à exécuter dans l'interface SQL de Supabase

-- Vérifier la structure de la table products
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les produits existants (sans comparaison UUID problématique)
SELECT 
  id,
  name,
  CASE 
    WHEN id IS NULL THEN '❌ ID NULL'
    ELSE '✅ ID PRÉSENT'
  END as status_id,
  stock_quantity,
  is_active,
  created_at
FROM public.products
ORDER BY created_at DESC
LIMIT 20;

-- Compter les produits
SELECT 
  COUNT(*) as nombre_total_produits,
  COUNT(CASE WHEN id IS NOT NULL THEN 1 END) as produits_avec_id,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as produits_avec_stock,
  COUNT(CASE WHEN is_active = TRUE THEN 1 END) as produits_actifs
FROM public.products;

-- Vérifier si la colonne id a une contrainte de clé primaire
SELECT 
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'products' 
  AND tc.table_schema = 'public'
  AND kcu.column_name = 'id';
