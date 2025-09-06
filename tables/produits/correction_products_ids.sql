-- CORRECTION - PRODUITS AVEC IDs INVALIDES
-- Script à exécuter dans l'interface SQL de Supabase

-- 1. Supprimer les produits avec des IDs invalides
DELETE FROM public.products 
WHERE id IS NULL 
   OR id::text = '' 
   OR id::text = 'undefined';

-- 2. Vérifier que la colonne id a une contrainte de clé primaire avec génération automatique
-- Si ce n'est pas le cas, recréer la table avec la bonne structure

-- 3. Recréer la table products avec la bonne structure si nécessaire
DROP TABLE IF EXISTS public.products_backup;
CREATE TABLE public.products_backup AS SELECT * FROM public.products;

-- Supprimer et recréer la table products
DROP TABLE IF EXISTS public.products;

CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  stock_quantity INTEGER DEFAULT 10,
  min_stock_level INTEGER DEFAULT 5,
  is_active BOOLEAN DEFAULT TRUE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Restaurer les données valides
INSERT INTO public.products (
  name, description, category, price, stock_quantity, min_stock_level, 
  is_active, user_id, created_at, updated_at
)
SELECT 
  name, description, category, price, 
  COALESCE(stock_quantity, 10) as stock_quantity,
  COALESCE(min_stock_level, 5) as min_stock_level,
  COALESCE(is_active, TRUE) as is_active,
  user_id, created_at, updated_at
FROM public.products_backup
WHERE id IS NOT NULL 
  AND id::text != '' 
  AND id::text != 'undefined'
  AND name IS NOT NULL;

-- 4. Vérification finale
SELECT 
  'CORRECTION TERMINÉE' as status,
  COUNT(*) as nombre_produits,
  COUNT(CASE WHEN id IS NOT NULL THEN 1 END) as produits_avec_id_valide,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as produits_avec_stock
FROM public.products;

-- 5. Nettoyer la table de sauvegarde
DROP TABLE IF EXISTS public.products_backup;
