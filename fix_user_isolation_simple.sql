-- Script simple pour forcer l'isolation des données par utilisateur
-- Ce script évite les conflits de noms et résout le problème d'isolation

-- 1. Ajouter user_id à toutes les tables principales (si pas déjà fait)
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. Assigner les données existantes au premier utilisateur admin
UPDATE public.clients SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.devices SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.repairs SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.sales SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.appointments SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.parts SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.products SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;
UPDATE public.services SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1) WHERE user_id IS NULL;

-- 3. Forcer la contrainte NOT NULL
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

-- 5. Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.sales;
DROP POLICY IF EXISTS "Users can view own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can create own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can update own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can delete own sales" ON public.sales;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.appointments;
DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;

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

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can create own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;

-- 6. Créer les nouvelles politiques RLS
-- Clients
CREATE POLICY "Users can view own clients" ON public.clients FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own clients" ON public.clients FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own clients" ON public.clients FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own clients" ON public.clients FOR DELETE USING (auth.uid() = user_id);

-- Devices
CREATE POLICY "Users can view own devices" ON public.devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own devices" ON public.devices FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own devices" ON public.devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own devices" ON public.devices FOR DELETE USING (auth.uid() = user_id);

-- Repairs
CREATE POLICY "Users can view own repairs" ON public.repairs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own repairs" ON public.repairs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own repairs" ON public.repairs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own repairs" ON public.repairs FOR DELETE USING (auth.uid() = user_id);

-- Sales
CREATE POLICY "Users can view own sales" ON public.sales FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own sales" ON public.sales FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sales" ON public.sales FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sales" ON public.sales FOR DELETE USING (auth.uid() = user_id);

-- Appointments
CREATE POLICY "Users can view own appointments" ON public.appointments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own appointments" ON public.appointments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own appointments" ON public.appointments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own appointments" ON public.appointments FOR DELETE USING (auth.uid() = user_id);

-- Parts
CREATE POLICY "Users can view own parts" ON public.parts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own parts" ON public.parts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own parts" ON public.parts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own parts" ON public.parts FOR DELETE USING (auth.uid() = user_id);

-- Products
CREATE POLICY "Users can view own products" ON public.products FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own products" ON public.products FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own products" ON public.products FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own products" ON public.products FOR DELETE USING (auth.uid() = user_id);

-- Services
CREATE POLICY "Users can view own services" ON public.services FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own services" ON public.services FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own services" ON public.services FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own services" ON public.services FOR DELETE USING (auth.uid() = user_id);

-- 7. Créer des index pour les performances
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_parts_user_id ON public.parts(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);

-- 8. Vérification finale
SELECT 'Isolation simple terminée' as status, COUNT(*) as total_users FROM public.users;

-- 9. Afficher un résumé des données par utilisateur
SELECT 
    u.email,
    u.role,
    COUNT(c.id) as clients_count,
    COUNT(d.id) as devices_count,
    COUNT(r.id) as repairs_count,
    COUNT(s.id) as sales_count,
    COUNT(a.id) as appointments_count,
    COUNT(p.id) as parts_count,
    COUNT(pr.id) as products_count,
    COUNT(se.id) as services_count
FROM public.users u
LEFT JOIN public.clients c ON u.id = c.user_id
LEFT JOIN public.devices d ON u.id = d.user_id
LEFT JOIN public.repairs r ON u.id = r.user_id
LEFT JOIN public.sales s ON u.id = s.user_id
LEFT JOIN public.appointments a ON u.id = a.user_id
LEFT JOIN public.parts p ON u.id = p.user_id
LEFT JOIN public.products pr ON u.id = pr.user_id
LEFT JOIN public.services se ON u.id = se.user_id
GROUP BY u.id, u.email, u.role
ORDER BY u.email;
