-- CORRECTION FORCÉE - TABLE PRODUCTS
-- Script qui force l'ajout des colonnes manquantes

-- Supprimer les colonnes si elles existent (pour éviter les conflits)
ALTER TABLE public.products DROP COLUMN IF EXISTS stock_quantity;
ALTER TABLE public.products DROP COLUMN IF EXISTS min_stock_level;
ALTER TABLE public.products DROP COLUMN IF EXISTS is_active;

-- Ajouter les colonnes avec des valeurs par défaut
ALTER TABLE public.products ADD COLUMN stock_quantity INTEGER DEFAULT 10;
ALTER TABLE public.products ADD COLUMN min_stock_level INTEGER DEFAULT 1;
ALTER TABLE public.products ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

-- Mettre à jour toutes les lignes existantes
UPDATE public.products SET 
  stock_quantity = 10,
  min_stock_level = 1,
  is_active = TRUE;

-- Vérification
SELECT 
  'CORRECTION FORCÉE TERMINÉE' as status,
  COUNT(*) as nombre_produits,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as produits_avec_stock,
  COUNT(CASE WHEN min_stock_level IS NOT NULL THEN 1 END) as produits_avec_seuil,
  COUNT(CASE WHEN is_active IS NOT NULL THEN 1 END) as produits_avec_statut
FROM public.products;
