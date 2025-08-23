-- SCRIPT POUR CORRIGER LES TABLES DU CATALOGUE
-- Ce script s'assure que toutes les tables ont les bonnes colonnes et l'isolation par utilisateur

-- 1. CRÉER LES TABLES SI ELLES N'EXISTENT PAS
CREATE TABLE IF NOT EXISTS public.devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    serial_number TEXT,
    type TEXT NOT NULL DEFAULT 'other',
    specifications JSONB,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    duration INTEGER DEFAULT 60,
    price DECIMAL(10,2) DEFAULT 0,
    category TEXT DEFAULT 'réparation',
    applicable_devices TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.parts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    part_number TEXT NOT NULL,
    brand TEXT NOT NULL,
    compatible_devices TEXT[] DEFAULT '{}',
    stock_quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 5,
    price DECIMAL(10,2) DEFAULT 0,
    supplier TEXT,
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'accessoire',
    price DECIMAL(10,2) DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. AJOUTER LES COLONNES MANQUANTES
-- Devices
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS brand TEXT;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS serial_number TEXT;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'other';
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS specifications JSONB;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Services
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 60;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'réparation';
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS applicable_devices TEXT[] DEFAULT '{}';
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Parts
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS part_number TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS brand TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS compatible_devices TEXT[] DEFAULT '{}';
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 5;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS supplier TEXT;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Products
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'accessoire';
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. FORCER LES CONTRAINTES NOT NULL
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;

-- 4. ACTIVER RLS SUR TOUTES LES TABLES
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 5. SUPPRIMER LES ANCIENNES POLITIQUES
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can create own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can create own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can create own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;

-- 6. CRÉER LES NOUVELLES POLITIQUES RLS
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

-- 7. CRÉER DES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);
CREATE INDEX IF NOT EXISTS idx_parts_user_id ON public.parts(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);

-- 8. VÉRIFICATION FINALE
SELECT 
    'devices' as table_name, COUNT(*) as count FROM public.devices
UNION ALL
SELECT 'services', COUNT(*) FROM public.services
UNION ALL
SELECT 'parts', COUNT(*) FROM public.parts
UNION ALL
SELECT 'products', COUNT(*) FROM public.products;

-- 9. AFFICHER LA STRUCTURE DES TABLES
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('devices', 'services', 'parts', 'products')
ORDER BY table_name, ordinal_position;

-- 10. MESSAGE DE CONFIRMATION
SELECT 
    'CATALOGUE CORRIGÉ' as status,
    'Toutes les tables du catalogue ont été corrigées avec isolation par utilisateur.' as message;
