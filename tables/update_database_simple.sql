-- Script de mise à jour de la base de données (version simplifiée)
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

-- 2. Vérifier et corriger les colonnes de la table sales
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

-- 3. Vérifier et corriger les colonnes de la table clients
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

-- 4. Vérifier et corriger les colonnes de la table devices
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

-- 5. Vérifier et corriger les colonnes de la table repairs
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

-- 6. Vérifier et corriger les colonnes de la table appointments
DO $$ 
BEGIN
    -- Vérifier client_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN client_id UUID REFERENCES public.clients(id);
    END IF;
    
    -- Vérifier repair_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'repair_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN repair_id UUID REFERENCES public.repairs(id);
    END IF;
    
    -- Vérifier title
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'title'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN title TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Vérifier description
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'description'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN description TEXT;
    END IF;
    
    -- Vérifier start_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
    END IF;
    
    -- Vérifier end_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN end_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
    END IF;
    
    -- Vérifier assigned_user_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'assigned_user_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN assigned_user_id UUID REFERENCES public.users(id);
    END IF;
    
    -- Vérifier status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN status TEXT DEFAULT 'scheduled';
    END IF;
    
    -- Vérifier created_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Vérifier updated_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 7. Afficher un message de succès
SELECT 'Mise à jour de la base de données terminée avec succès !' as message;
