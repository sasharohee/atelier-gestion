-- Script de mise à jour de la base de données pour corriger les erreurs
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Ajouter la colonne 'items' à la table sales si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'items'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN items JSONB NOT NULL DEFAULT '[]';
    END IF;
END $$;

-- 2. Vérifier et corriger les noms de colonnes existants
-- La table sales devrait avoir : id, client_id, items, subtotal, tax, total, payment_method, status, created_at, updated_at

-- 3. Ajouter la table sale_items si elle n'existe pas
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

-- 4. Activer RLS sur la nouvelle table
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- 5. Ajouter les politiques RLS pour sale_items
CREATE POLICY "Enable read access for authenticated users" ON public.sale_items 
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.sale_items 
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.sale_items 
FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.sale_items 
FOR DELETE USING (auth.role() = 'authenticated');

-- 6. Vérifier que toutes les colonnes nécessaires existent dans sales
DO $$ 
BEGIN
    -- Vérifier client_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN client_id UUID REFERENCES public.clients(id);
    END IF;
    
    -- Vérifier payment_method
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'payment_method'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN payment_method TEXT DEFAULT 'cash';
    END IF;
    
    -- Vérifier status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;
END $$;

-- 7. Vérifier la structure de la table clients
DO $$ 
BEGIN
    -- Vérifier first_name
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'first_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN first_name TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Vérifier last_name
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'last_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN last_name TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Vérifier email
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'email'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email TEXT UNIQUE NOT NULL DEFAULT '';
    END IF;
    
    -- Vérifier phone
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'phone'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN phone TEXT;
    END IF;
    
    -- Vérifier address
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'address'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN address TEXT;
    END IF;
    
    -- Vérifier notes
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN notes TEXT;
    END IF;
END $$;

-- 8. Vérifier la structure de la table devices
DO $$ 
BEGIN
    -- Vérifier brand
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'brand'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN brand TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Vérifier model
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'model'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN model TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Vérifier serial_number
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'serial_number'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN serial_number TEXT;
    END IF;
    
    -- Vérifier type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'type'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN type TEXT NOT NULL DEFAULT 'other';
    END IF;
    
    -- Vérifier specifications
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN specifications JSONB;
    END IF;
END $$;

-- 9. Vérifier la structure de la table repairs
DO $$ 
BEGIN
    -- Vérifier client_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN client_id UUID REFERENCES public.clients(id);
    END IF;
    
    -- Vérifier device_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'device_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN device_id UUID REFERENCES public.devices(id);
    END IF;
    
    -- Vérifier assigned_technician_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'assigned_technician_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN assigned_technician_id UUID REFERENCES public.users(id);
    END IF;
    
    -- Vérifier estimated_duration
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'estimated_duration'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN estimated_duration INTEGER;
    END IF;
    
    -- Vérifier actual_duration
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'actual_duration'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN actual_duration INTEGER;
    END IF;
    
    -- Vérifier estimated_start_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'estimated_start_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN estimated_start_date TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Vérifier estimated_end_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'estimated_end_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN estimated_end_date TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Vérifier start_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN start_date TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Vérifier end_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN end_date TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Vérifier due_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'due_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN due_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
    END IF;
    
    -- Vérifier is_urgent
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'is_urgent'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN is_urgent BOOLEAN DEFAULT false;
    END IF;
    
    -- Vérifier total_price
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'total_price'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN total_price DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    -- Vérifier is_paid
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'is_paid'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN is_paid BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 10. Afficher la structure finale des tables
SELECT 
    'sales' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'sales' 

UNION ALL

SELECT 
    'clients' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'clients' 

UNION ALL

SELECT 
    'devices' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'devices' 

UNION ALL

SELECT 
    'repairs' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'repairs' 

ORDER BY table_name, ordinal_position;
