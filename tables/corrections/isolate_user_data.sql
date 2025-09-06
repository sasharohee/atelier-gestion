-- Script complet pour isoler toutes les données par utilisateur
-- Ce script ajoute user_id à toutes les tables et configure les politiques RLS

-- 1. Ajouter user_id à toutes les tables principales
DO $$ 
BEGIN
    -- Ajouter user_id à clients
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à devices
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à repairs
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à sales
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à appointments
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à parts
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parts' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à products
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter user_id à services
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'services' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.services ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Mettre à jour les enregistrements existants pour assigner un user_id par défaut
-- Utiliser le premier utilisateur admin ou le premier utilisateur disponible
UPDATE public.clients 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.devices 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.repairs 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.sales 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.appointments 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.parts 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.products 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.services 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

-- 3. Ajouter la contrainte NOT NULL après avoir assigné les valeurs
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.appointments ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;

-- 4. Activer RLS sur toutes les tables
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 5. Supprimer toutes les politiques existantes pour éviter les conflits
-- Clients
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

-- Devices
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

-- Repairs
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;

-- Sales
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Users can view own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can create own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can update own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can delete own sales" ON public.sales;

-- Appointments
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;

-- Parts
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can create own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;

-- Products
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can create own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;

-- Services
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can create own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;

-- 6. Créer les nouvelles politiques RLS pour chaque table
-- Clients
CREATE POLICY "Users can view own clients" ON public.clients
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own clients" ON public.clients
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own clients" ON public.clients
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own clients" ON public.clients
    FOR DELETE USING (auth.uid() = user_id);

-- Devices
CREATE POLICY "Users can view own devices" ON public.devices
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own devices" ON public.devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own devices" ON public.devices
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own devices" ON public.devices
    FOR DELETE USING (auth.uid() = user_id);

-- Repairs
CREATE POLICY "Users can view own repairs" ON public.repairs
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own repairs" ON public.repairs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own repairs" ON public.repairs
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own repairs" ON public.repairs
    FOR DELETE USING (auth.uid() = user_id);

-- Sales
CREATE POLICY "Users can view own sales" ON public.sales
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own sales" ON public.sales
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sales" ON public.sales
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sales" ON public.sales
    FOR DELETE USING (auth.uid() = user_id);

-- Appointments
CREATE POLICY "Users can view own appointments" ON public.appointments
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own appointments" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own appointments" ON public.appointments
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own appointments" ON public.appointments
    FOR DELETE USING (auth.uid() = user_id);

-- Parts
CREATE POLICY "Users can view own parts" ON public.parts
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own parts" ON public.parts
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own parts" ON public.parts
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own parts" ON public.parts
    FOR DELETE USING (auth.uid() = user_id);

-- Products
CREATE POLICY "Users can view own products" ON public.products
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own products" ON public.products
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own products" ON public.products
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own products" ON public.products
    FOR DELETE USING (auth.uid() = user_id);

-- Services
CREATE POLICY "Users can view own services" ON public.services
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own services" ON public.services
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own services" ON public.services
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own services" ON public.services
    FOR DELETE USING (auth.uid() = user_id);

-- 7. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_parts_user_id ON public.parts(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);

-- 8. Vérification finale
SELECT 
    'Configuration terminée' as status,
    COUNT(*) as total_users
FROM public.users;

-- 9. Afficher les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services')
ORDER BY tablename, policyname;
