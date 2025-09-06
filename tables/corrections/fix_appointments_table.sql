-- Script pour corriger la table appointments
-- À exécuter dans l'éditeur SQL de Supabase

-- Vérifier si la table appointments existe, sinon la créer
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

-- Vérifier et ajouter les colonnes manquantes si nécessaire
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

-- S'assurer que les colonnes de clés étrangères acceptent NULL
DO $$
BEGIN
    -- Modifier client_id pour accepter NULL si ce n'est pas déjà le cas
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'client_id' 
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN client_id DROP NOT NULL;
    END IF;
    
    -- Modifier repair_id pour accepter NULL si ce n'est pas déjà le cas
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'repair_id' 
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN repair_id DROP NOT NULL;
    END IF;
    
    -- Modifier assigned_user_id pour accepter NULL si ce n'est pas déjà le cas
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'assigned_user_id' 
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN assigned_user_id DROP NOT NULL;
    END IF;
END $$;

-- Activer RLS sur la table appointments si ce n'est pas déjà fait
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS si elles n'existent pas
DO $$
BEGIN
    -- Politique de lecture
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'appointments' AND policyname = 'Enable read access for authenticated users'
    ) THEN
        CREATE POLICY "Enable read access for authenticated users" ON public.appointments FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
    
    -- Politique d'insertion
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'appointments' AND policyname = 'Enable insert for authenticated users'
    ) THEN
        CREATE POLICY "Enable insert for authenticated users" ON public.appointments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
    -- Politique de mise à jour
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'appointments' AND policyname = 'Enable update for authenticated users'
    ) THEN
        CREATE POLICY "Enable update for authenticated users" ON public.appointments FOR UPDATE USING (auth.role() = 'authenticated');
    END IF;
    
    -- Politique de suppression
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'appointments' AND policyname = 'Enable delete for authenticated users'
    ) THEN
        CREATE POLICY "Enable delete for authenticated users" ON public.appointments FOR DELETE USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- Afficher un message de succès
SELECT 'Table appointments corrigée avec succès !' as message;
