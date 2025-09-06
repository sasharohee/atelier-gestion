-- VÉRIFICATION ET CORRECTION DES COLONNES MANQUANTES
-- Script à exécuter dans l'interface SQL de Supabase

-- 1. Vérifier la structure de la table parts
SELECT 
  'STRUCTURE TABLE PARTS' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'parts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier la structure de la table products
SELECT 
  'STRUCTURE TABLE PRODUCTS' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Ajouter les colonnes manquantes à la table parts
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 5;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- 4. Ajouter les colonnes manquantes à la table products
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 10;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 5;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- 5. Mettre à jour les valeurs NULL
UPDATE public.parts SET 
  stock_quantity = COALESCE(stock_quantity, 0),
  min_stock_level = COALESCE(min_stock_level, 5),
  is_active = COALESCE(is_active, TRUE)
WHERE stock_quantity IS NULL 
   OR min_stock_level IS NULL 
   OR is_active IS NULL;

UPDATE public.products SET 
  stock_quantity = COALESCE(stock_quantity, 10),
  min_stock_level = COALESCE(min_stock_level, 5),
  is_active = COALESCE(is_active, TRUE)
WHERE stock_quantity IS NULL 
   OR min_stock_level IS NULL 
   OR is_active IS NULL;

-- 6. Vérification finale
SELECT 
  'CORRECTION TERMINÉE' as info,
  'PARTS' as table_name,
  COUNT(*) as nombre_pieces,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as pieces_avec_stock,
  COUNT(CASE WHEN is_active = TRUE THEN 1 END) as pieces_actives
FROM public.parts
UNION ALL
SELECT 
  'CORRECTION TERMINÉE' as info,
  'PRODUCTS' as table_name,
  COUNT(*) as nombre_produits,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as produits_avec_stock,
  COUNT(CASE WHEN is_active = TRUE THEN 1 END) as produits_actifs
FROM public.products;
