-- DIAGNOSTIC - VÉRIFICATION DES IDs DES PRODUITS
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

-- Vérifier les produits existants et leurs IDs
SELECT 
  id,
  name,
  CASE 
    WHEN id IS NULL THEN '❌ ID NULL'
    WHEN id::text = '' THEN '❌ ID VIDE'
    WHEN id::text = 'undefined' THEN '❌ ID UNDEFINED'
    ELSE '✅ ID VALIDE'
  END as status_id,
  stock_quantity,
  is_active,
  created_at
FROM public.products
ORDER BY created_at DESC
LIMIT 20;

-- Compter les produits par statut d'ID
SELECT 
  CASE 
    WHEN id IS NULL THEN 'ID NULL'
    WHEN id::text = '' THEN 'ID VIDE'
    WHEN id::text = 'undefined' THEN 'ID UNDEFINED'
    ELSE 'ID VALIDE'
  END as status_id,
  COUNT(*) as nombre_produits
FROM public.products
GROUP BY 
  CASE 
    WHEN id IS NULL THEN 'ID NULL'
    WHEN id::text = '' THEN 'ID VIDE'
    WHEN id::text = 'undefined' THEN 'ID UNDEFINED'
    ELSE 'ID VALIDE'
  END;

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
