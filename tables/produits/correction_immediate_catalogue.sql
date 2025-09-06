-- CORRECTION IMMÉDIATE DU CATALOGUE
-- Script simple pour résoudre l'erreur "Could not find the 'is_active' column"

-- ============================================================================
-- 1. AJOUT DES COLONNES MANQUANTES À PRODUCTS
-- ============================================================================

-- Ajouter user_id si manquant
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- Ajouter is_active si manquant
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Ajouter stock_quantity si manquant
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;

-- ============================================================================
-- 2. AJOUT DES COLONNES MANQUANTES AUX AUTRES TABLES
-- ============================================================================

-- Parts
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS part_number TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS brand TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS compatible_devices TEXT[];
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 5;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS supplier TEXT;

-- Services
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 60;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS applicable_devices TEXT[];

-- Devices
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS brand TEXT;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS serial_number TEXT;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'other';
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS specifications JSONB;

-- Clients
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS address TEXT;

-- ============================================================================
-- 3. RAFRAÎCHIR LE CACHE POSTGREST
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- 4. VÉRIFICATION RAPIDE
-- ============================================================================

-- Vérifier que les colonnes sont présentes
SELECT 
    'products' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
    AND column_name IN ('user_id', 'is_active', 'stock_quantity')
ORDER BY column_name;
