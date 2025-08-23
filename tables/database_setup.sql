-- Script de création des tables pour l'application Atelier
-- À exécuter dans l'éditeur SQL de Supabase

-- Table des utilisateurs (extension de auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  role TEXT DEFAULT 'technician',
  avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des clients
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des appareils
CREATE TABLE IF NOT EXISTS public.devices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  serial_number TEXT,
  type TEXT NOT NULL,
  specifications JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des réparations
CREATE TABLE IF NOT EXISTS public.repairs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id),
  device_id UUID REFERENCES public.devices(id),
  status TEXT DEFAULT 'new',
  assigned_technician_id UUID REFERENCES public.users(id),
  description TEXT,
  issue TEXT,
  estimated_duration INTEGER,
  actual_duration INTEGER,
  estimated_start_date TIMESTAMP WITH TIME ZONE,
  estimated_end_date TIMESTAMP WITH TIME ZONE,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_urgent BOOLEAN DEFAULT false,
  notes TEXT,
  total_price DECIMAL(10,2) DEFAULT 0,
  is_paid BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des pièces
CREATE TABLE IF NOT EXISTS public.parts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  part_number TEXT,
  brand TEXT,
  compatible_devices TEXT[],
  stock_quantity INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 5,
  price DECIMAL(10,2) NOT NULL,
  supplier TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des produits
CREATE TABLE IF NOT EXISTS public.products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des ventes
CREATE TABLE IF NOT EXISTS public.sales (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id),
  items JSONB NOT NULL DEFAULT '[]',
  subtotal DECIMAL(10,2) NOT NULL,
  tax DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  payment_method TEXT DEFAULT 'cash',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des éléments de vente (alternative à JSONB)
CREATE TABLE IF NOT EXISTS public.sale_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'product', 'service', 'part'
  item_id UUID NOT NULL,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des rendez-vous
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id),
  repair_id UUID REFERENCES public.repairs(id),
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  assigned_user_id UUID REFERENCES public.users(id),
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) - Activer pour toutes les tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Politiques RLS basiques pour les utilisateurs authentifiés
CREATE POLICY "Enable read access for authenticated users" ON public.users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.clients FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.devices FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.repairs FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.parts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.products FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.sales FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.appointments FOR SELECT USING (auth.role() = 'authenticated');

-- Politiques d'écriture
CREATE POLICY "Enable insert for authenticated users" ON public.users FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.clients FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.devices FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.repairs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.parts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.sales FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.appointments FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Politiques de mise à jour
CREATE POLICY "Enable update for authenticated users" ON public.users FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.clients FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.devices FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.repairs FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.parts FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.products FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.sales FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.appointments FOR UPDATE USING (auth.role() = 'authenticated');

-- Politiques de suppression
CREATE POLICY "Enable delete for authenticated users" ON public.users FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.clients FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.devices FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.repairs FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.parts FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.products FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.sales FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.appointments FOR DELETE USING (auth.role() = 'authenticated');

-- Insérer quelques données de test
INSERT INTO public.clients (first_name, last_name, email, phone) VALUES
('Jean', 'Dupont', 'jean.dupont@email.com', '0123456789'),
('Marie', 'Martin', 'marie.martin@email.com', '0987654321'),
('Pierre', 'Durand', 'pierre.durand@email.com', '0555666777')
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.devices (brand, model, type, serial_number) VALUES
('Apple', 'iPhone 13', 'smartphone', 'SN001'),
('Samsung', 'Galaxy S21', 'smartphone', 'SN002'),
('Dell', 'XPS 13', 'laptop', 'SN003');

INSERT INTO public.parts (name, description, part_number, brand, stock_quantity, price) VALUES
('Écran iPhone 13', 'Écran de remplacement pour iPhone 13', 'IP13-SCR-001', 'Apple', 5, 89.99),
('Batterie Samsung S21', 'Batterie de remplacement', 'SS21-BAT-001', 'Samsung', 3, 45.50),
('Clavier Dell XPS', 'Clavier de remplacement', 'DX13-KBD-001', 'Dell', 2, 120.00);
