-- SCRIPT IMMÉDIAT POUR CORRIGER LE CATALOGUE
-- Exécutez ce script pour corriger immédiatement les problèmes

-- 1. AJOUTER LA COLONNE applicable_devices À LA TABLE services
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS applicable_devices TEXT[] DEFAULT '{}';

-- 2. AJOUTER LA COLONNE compatible_devices À LA TABLE parts
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS compatible_devices TEXT[] DEFAULT '{}';

-- 3. AJOUTER user_id À TOUTES LES TABLES SI MANQUANT
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. ACTIVER RLS
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 5. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
DROP POLICY IF EXISTS "CATALOG_Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "CATALOG_Users can view own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can create own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can update own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can delete own services" ON public.services;

DROP POLICY IF EXISTS "CATALOG_Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can create own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can delete own parts" ON public.parts;

DROP POLICY IF EXISTS "CATALOG_Users can view own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can create own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can update own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can delete own products" ON public.products;

-- 6. CRÉER LES POLITIQUES RLS COMPLÈTES
-- Devices
CREATE POLICY "CATALOG_Users can view own devices" ON public.devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can create own devices" ON public.devices FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can update own devices" ON public.devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can delete own devices" ON public.devices FOR DELETE USING (auth.uid() = user_id);

-- Services
CREATE POLICY "CATALOG_Users can view own services" ON public.services FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can create own services" ON public.services FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can update own services" ON public.services FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can delete own services" ON public.services FOR DELETE USING (auth.uid() = user_id);

-- Parts
CREATE POLICY "CATALOG_Users can view own parts" ON public.parts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can create own parts" ON public.parts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can update own parts" ON public.parts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can delete own parts" ON public.parts FOR DELETE USING (auth.uid() = user_id);

-- Products
CREATE POLICY "CATALOG_Users can view own products" ON public.products FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can create own products" ON public.products FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can update own products" ON public.products FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_Users can delete own products" ON public.products FOR DELETE USING (auth.uid() = user_id);

-- 7. VÉRIFICATION
SELECT 'Colonnes et politiques ajoutées avec succès' as status;
