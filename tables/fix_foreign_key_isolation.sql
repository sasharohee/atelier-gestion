-- SCRIPT POUR CORRIGER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- Ce script assure que toutes les relations respectent l'isolation par utilisateur

-- 1. DÉSACTIVER RLS TEMPORAIREMENT
ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.services DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES DONNÉES POUR REPARTIR DE ZÉRO
DELETE FROM public.repairs;
DELETE FROM public.sales;
DELETE FROM public.appointments;
DELETE FROM public.devices;
DELETE FROM public.clients;
DELETE FROM public.parts;
DELETE FROM public.products;
DELETE FROM public.services;

-- 3. VÉRIFIER ET CORRIGER LES CONTRAINTES DE CLÉS ÉTRANGÈRES

-- Supprimer les anciennes contraintes problématiques
ALTER TABLE public.repairs DROP CONSTRAINT IF EXISTS repairs_client_id_fkey;
ALTER TABLE public.repairs DROP CONSTRAINT IF EXISTS repairs_device_id_fkey;
ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_client_id_fkey;
ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_product_id_fkey;
ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS appointments_client_id_fkey;
ALTER TABLE public.devices DROP CONSTRAINT IF EXISTS devices_client_id_fkey;

-- Recréer les contraintes avec CASCADE pour l'isolation
ALTER TABLE public.repairs 
ADD CONSTRAINT repairs_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

ALTER TABLE public.repairs 
ADD CONSTRAINT repairs_device_id_fkey 
FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;

ALTER TABLE public.sales 
ADD CONSTRAINT sales_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

ALTER TABLE public.sales 
ADD CONSTRAINT sales_product_id_fkey 
FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.appointments 
ADD CONSTRAINT appointments_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

ALTER TABLE public.devices 
ADD CONSTRAINT devices_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

-- 4. S'ASSURER QUE LES COLONNES user_id EXISTENT ET SONT CORRECTES
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 5. FORCER LES CONTRAINTES NOT NULL
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.appointments ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;

-- 6. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "STRICT_Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "STRICT_Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "STRICT_Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "STRICT_Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "STRICT_Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "STRICT_Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "STRICT_Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "STRICT_Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;
DROP POLICY IF EXISTS "STRICT_Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "STRICT_Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "STRICT_Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "STRICT_Users can delete own repairs" ON public.repairs;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Users can view own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can create own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can update own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can delete own sales" ON public.sales;
DROP POLICY IF EXISTS "STRICT_Users can view own sales" ON public.sales;
DROP POLICY IF EXISTS "STRICT_Users can create own sales" ON public.sales;
DROP POLICY IF EXISTS "STRICT_Users can update own sales" ON public.sales;
DROP POLICY IF EXISTS "STRICT_Users can delete own sales" ON public.sales;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
DROP POLICY IF EXISTS "STRICT_Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "STRICT_Users can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "STRICT_Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "STRICT_Users can delete own appointments" ON public.appointments;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can create own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;
DROP POLICY IF EXISTS "STRICT_Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "STRICT_Users can create own parts" ON public.parts;
DROP POLICY IF EXISTS "STRICT_Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "STRICT_Users can delete own parts" ON public.parts;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can create own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;
DROP POLICY IF EXISTS "STRICT_Users can view own products" ON public.products;
DROP POLICY IF EXISTS "STRICT_Users can create own products" ON public.products;
DROP POLICY IF EXISTS "STRICT_Users can update own products" ON public.products;
DROP POLICY IF EXISTS "STRICT_Users can delete own products" ON public.products;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can create own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;
DROP POLICY IF EXISTS "STRICT_Users can view own services" ON public.services;
DROP POLICY IF EXISTS "STRICT_Users can create own services" ON public.services;
DROP POLICY IF EXISTS "STRICT_Users can update own services" ON public.services;
DROP POLICY IF EXISTS "STRICT_Users can delete own services" ON public.services;

-- 7. CRÉER DES POLITIQUES RLS ULTRA-STRICTES AVEC VÉRIFICATION DES RELATIONS
-- Clients (table parent)
CREATE POLICY "ULTRA_Users can view own clients" ON public.clients FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own clients" ON public.clients FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can update own clients" ON public.clients FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own clients" ON public.clients FOR DELETE USING (auth.uid() = user_id);

-- Devices (dépend de clients)
CREATE POLICY "ULTRA_Users can view own devices" ON public.devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own devices" ON public.devices FOR INSERT WITH CHECK (
  auth.uid() = user_id AND 
  EXISTS (SELECT 1 FROM public.clients WHERE id = client_id AND user_id = auth.uid())
);
CREATE POLICY "ULTRA_Users can update own devices" ON public.devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own devices" ON public.devices FOR DELETE USING (auth.uid() = user_id);

-- Repairs (dépend de clients et devices)
CREATE POLICY "ULTRA_Users can view own repairs" ON public.repairs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own repairs" ON public.repairs FOR INSERT WITH CHECK (
  auth.uid() = user_id AND 
  EXISTS (SELECT 1 FROM public.clients WHERE id = client_id AND user_id = auth.uid()) AND
  EXISTS (SELECT 1 FROM public.devices WHERE id = device_id AND user_id = auth.uid())
);
CREATE POLICY "ULTRA_Users can update own repairs" ON public.repairs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own repairs" ON public.repairs FOR DELETE USING (auth.uid() = user_id);

-- Sales (dépend de clients et products)
CREATE POLICY "ULTRA_Users can view own sales" ON public.sales FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own sales" ON public.sales FOR INSERT WITH CHECK (
  auth.uid() = user_id AND 
  EXISTS (SELECT 1 FROM public.clients WHERE id = client_id AND user_id = auth.uid()) AND
  EXISTS (SELECT 1 FROM public.products WHERE id = product_id AND user_id = auth.uid())
);
CREATE POLICY "ULTRA_Users can update own sales" ON public.sales FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own sales" ON public.sales FOR DELETE USING (auth.uid() = user_id);

-- Appointments (dépend de clients)
CREATE POLICY "ULTRA_Users can view own appointments" ON public.appointments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own appointments" ON public.appointments FOR INSERT WITH CHECK (
  auth.uid() = user_id AND 
  EXISTS (SELECT 1 FROM public.clients WHERE id = client_id AND user_id = auth.uid())
);
CREATE POLICY "ULTRA_Users can update own appointments" ON public.appointments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own appointments" ON public.appointments FOR DELETE USING (auth.uid() = user_id);

-- Parts (table indépendante)
CREATE POLICY "ULTRA_Users can view own parts" ON public.parts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own parts" ON public.parts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can update own parts" ON public.parts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own parts" ON public.parts FOR DELETE USING (auth.uid() = user_id);

-- Products (table indépendante)
CREATE POLICY "ULTRA_Users can view own products" ON public.products FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own products" ON public.products FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can update own products" ON public.products FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own products" ON public.products FOR DELETE USING (auth.uid() = user_id);

-- Services (table indépendante)
CREATE POLICY "ULTRA_Users can view own services" ON public.services FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can create own services" ON public.services FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can update own services" ON public.services FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ULTRA_Users can delete own services" ON public.services FOR DELETE USING (auth.uid() = user_id);

-- 8. RÉACTIVER RLS
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 9. CRÉER DES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_parts_user_id ON public.parts(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);

-- 10. VÉRIFICATION FINALE
SELECT 
    'clients' as table_name, COUNT(*) as count FROM public.clients
UNION ALL
SELECT 'devices', COUNT(*) FROM public.devices
UNION ALL
SELECT 'repairs', COUNT(*) FROM public.repairs
UNION ALL
SELECT 'sales', COUNT(*) FROM public.sales
UNION ALL
SELECT 'appointments', COUNT(*) FROM public.appointments
UNION ALL
SELECT 'parts', COUNT(*) FROM public.parts
UNION ALL
SELECT 'products', COUNT(*) FROM public.products
UNION ALL
SELECT 'services', COUNT(*) FROM public.services;

-- 11. AFFICHER LES UTILISATEURS DISPONIBLES
SELECT 
    id,
    email,
    role,
    created_at
FROM public.users
ORDER BY created_at;

-- 12. MESSAGE DE CONFIRMATION
SELECT 
    'ISOLATION COMPLÈTE AVEC CLÉS ÉTRANGÈRES RÉUSSIE' as status,
    'Toutes les données ont été supprimées. Les contraintes de clés étrangères respectent maintenant l''isolation par utilisateur.' as message,
    COUNT(*) as total_users
FROM public.users;
