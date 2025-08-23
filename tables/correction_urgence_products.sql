-- CORRECTION URGENCE - TABLE PRODUCTS
-- Script ultra-simple pour corriger immédiatement

-- Ajouter stock_quantity
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 10;

-- Ajouter min_stock_level  
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 5;

-- Ajouter is_active
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Mettre à jour les valeurs NULL
UPDATE public.products SET stock_quantity = 10 WHERE stock_quantity IS NULL;
UPDATE public.products SET min_stock_level = 5 WHERE min_stock_level IS NULL;
UPDATE public.products SET is_active = TRUE WHERE is_active IS NULL;

-- Vérification rapide
SELECT 'CORRECTION TERMINÉE' as status;
