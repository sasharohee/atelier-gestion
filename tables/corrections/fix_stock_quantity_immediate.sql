-- CORRECTION IMMÉDIATE - COLONNE STOCK_QUANTITY
-- Script à exécuter dans l'interface SQL de Supabase

-- Ajouter la colonne stock_quantity si elle n'existe pas
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 10;

-- Mettre à jour les lignes existantes qui n'ont pas de stock_quantity
UPDATE public.products SET stock_quantity = 10 WHERE stock_quantity IS NULL;

-- Vérification
SELECT 
  'CORRECTION TERMINÉE' as status,
  COUNT(*) as nombre_produits,
  COUNT(CASE WHEN stock_quantity IS NOT NULL THEN 1 END) as produits_avec_stock
FROM public.products;
