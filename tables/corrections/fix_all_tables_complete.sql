-- =====================================================
-- CORRECTION COMPLÈTE DE TOUTES LES TABLES
-- =====================================================
-- Date: 2025-01-23
-- Problèmes: 
-- - "Could not find the 'notes' column of 'clients' in the schema cache"
-- - "Could not find the 'brand' column of 'devices' in the schema cache"
-- - "Could not find the 'actual_duration' column of 'repairs' in the schema cache"
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DE TOUTES LES TABLES
SELECT '=== STRUCTURE ACTUELLE CLIENTS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE ACTUELLE DEVICES ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE ACTUELLE REPAIRS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'repairs'
ORDER BY ordinal_position;

-- 2. CORRECTION DE LA TABLE CLIENTS
SELECT '=== CORRECTION TABLE CLIENTS ===' as section;

DO $$
BEGIN
    -- Ajouter user_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans la table clients';
    END IF;

    -- Ajouter first_name si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'first_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN first_name TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne first_name ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne first_name existe déjà dans la table clients';
    END IF;

    -- Ajouter last_name si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'last_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN last_name TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne last_name ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne last_name existe déjà dans la table clients';
    END IF;

    -- Ajouter email si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'email'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne email ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne email existe déjà dans la table clients';
    END IF;

    -- Ajouter phone si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'phone'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN phone TEXT;
        RAISE NOTICE '✅ Colonne phone ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne phone existe déjà dans la table clients';
    END IF;

    -- Ajouter address si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'address'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN address TEXT;
        RAISE NOTICE '✅ Colonne address ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne address existe déjà dans la table clients';
    END IF;

    -- Ajouter notes si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN notes TEXT;
        RAISE NOTICE '✅ Colonne notes ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne notes existe déjà dans la table clients';
    END IF;

    -- Ajouter created_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans la table clients';
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans la table clients';
    END IF;
END $$;

-- 3. CORRECTION DE LA TABLE DEVICES
SELECT '=== CORRECTION TABLE DEVICES ===' as section;

DO $$
BEGIN
    -- Ajouter user_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans la table devices';
    END IF;

    -- Ajouter brand si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'brand'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN brand TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne brand ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne brand existe déjà dans la table devices';
    END IF;

    -- Ajouter model si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'model'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN model TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne model ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne model existe déjà dans la table devices';
    END IF;

    -- Ajouter serial_number si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'serial_number'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN serial_number TEXT;
        RAISE NOTICE '✅ Colonne serial_number ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne serial_number existe déjà dans la table devices';
    END IF;

    -- Ajouter type si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'type'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN type TEXT NOT NULL DEFAULT 'other';
        RAISE NOTICE '✅ Colonne type ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne type existe déjà dans la table devices';
    END IF;

    -- Ajouter specifications si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN specifications JSONB;
        RAISE NOTICE '✅ Colonne specifications ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne specifications existe déjà dans la table devices';
    END IF;

    -- Ajouter created_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans la table devices';
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans la table devices';
    END IF;
END $$;

-- 4. CORRECTION DE LA TABLE REPAIRS
SELECT '=== CORRECTION TABLE REPAIRS ===' as section;

DO $$
BEGIN
    -- Ajouter user_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans la table repairs';
    END IF;

    -- Ajouter client_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'client_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN client_id UUID REFERENCES public.clients(id);
        RAISE NOTICE '✅ Colonne client_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne client_id existe déjà dans la table repairs';
    END IF;

    -- Ajouter device_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'device_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN device_id UUID REFERENCES public.devices(id);
        RAISE NOTICE '✅ Colonne device_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne device_id existe déjà dans la table repairs';
    END IF;

    -- Ajouter status si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'status'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN status TEXT DEFAULT 'new';
        RAISE NOTICE '✅ Colonne status ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne status existe déjà dans la table repairs';
    END IF;

    -- Ajouter assigned_technician_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'assigned_technician_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN assigned_technician_id UUID REFERENCES public.users(id);
        RAISE NOTICE '✅ Colonne assigned_technician_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne assigned_technician_id existe déjà dans la table repairs';
    END IF;

    -- Ajouter description si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'description'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN description TEXT;
        RAISE NOTICE '✅ Colonne description ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne description existe déjà dans la table repairs';
    END IF;

    -- Ajouter issue si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'issue'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN issue TEXT;
        RAISE NOTICE '✅ Colonne issue ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne issue existe déjà dans la table repairs';
    END IF;

    -- Ajouter estimated_duration si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'estimated_duration'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN estimated_duration INTEGER;
        RAISE NOTICE '✅ Colonne estimated_duration ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne estimated_duration existe déjà dans la table repairs';
    END IF;

    -- Ajouter actual_duration si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'actual_duration'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN actual_duration INTEGER;
        RAISE NOTICE '✅ Colonne actual_duration ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne actual_duration existe déjà dans la table repairs';
    END IF;

    -- Ajouter estimated_start_date si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'estimated_start_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN estimated_start_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne estimated_start_date ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne estimated_start_date existe déjà dans la table repairs';
    END IF;

    -- Ajouter estimated_end_date si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'estimated_end_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN estimated_end_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne estimated_end_date ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne estimated_end_date existe déjà dans la table repairs';
    END IF;

    -- Ajouter start_date si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN start_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne start_date ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne start_date existe déjà dans la table repairs';
    END IF;

    -- Ajouter end_date si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN end_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne end_date ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne end_date existe déjà dans la table repairs';
    END IF;

    -- Ajouter due_date si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'due_date'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN due_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
        RAISE NOTICE '✅ Colonne due_date ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne due_date existe déjà dans la table repairs';
    END IF;

    -- Ajouter is_urgent si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'is_urgent'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN is_urgent BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Colonne is_urgent ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne is_urgent existe déjà dans la table repairs';
    END IF;

    -- Ajouter notes si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN notes TEXT;
        RAISE NOTICE '✅ Colonne notes ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne notes existe déjà dans la table repairs';
    END IF;

    -- Ajouter total_price si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'total_price'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN total_price DECIMAL(10,2) DEFAULT 0;
        RAISE NOTICE '✅ Colonne total_price ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne total_price existe déjà dans la table repairs';
    END IF;

    -- Ajouter is_paid si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'is_paid'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN is_paid BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Colonne is_paid ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne is_paid existe déjà dans la table repairs';
    END IF;

    -- Ajouter created_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans la table repairs';
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à la table repairs';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans la table repairs';
    END IF;
END $$;

-- 5. CRÉER LES INDEX NÉCESSAIRES
SELECT '=== CRÉATION DES INDEX ===' as section;

-- Index pour clients
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_email ON public.clients(email);

-- Index pour devices
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_brand ON public.devices(brand);
CREATE INDEX IF NOT EXISTS idx_devices_type ON public.devices(type);

-- Index pour repairs
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_client_id ON public.repairs(client_id);
CREATE INDEX IF NOT EXISTS idx_repairs_device_id ON public.repairs(device_id);
CREATE INDEX IF NOT EXISTS idx_repairs_status ON public.repairs(status);

-- 6. ACTIVER RLS SUR TOUTES LES TABLES
SELECT '=== ACTIVATION RLS ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;

-- 7. CRÉER LES POLITIQUES RLS
SELECT '=== CRÉATION DES POLITIQUES RLS ===' as section;

-- Politiques pour clients
DO $$
BEGIN
    -- Politique de lecture
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can view own clients'
    ) THEN
        CREATE POLICY "Users can view own clients" ON public.clients 
            FOR SELECT USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de lecture créée pour clients';
    END IF;

    -- Politique d'insertion
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can create own clients'
    ) THEN
        CREATE POLICY "Users can create own clients" ON public.clients 
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique d''insertion créée pour clients';
    END IF;

    -- Politique de mise à jour
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can update own clients'
    ) THEN
        CREATE POLICY "Users can update own clients" ON public.clients 
            FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de mise à jour créée pour clients';
    END IF;

    -- Politique de suppression
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can delete own clients'
    ) THEN
        CREATE POLICY "Users can delete own clients" ON public.clients 
            FOR DELETE USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de suppression créée pour clients';
    END IF;
END $$;

-- Politiques pour devices
DO $$
BEGIN
    -- Politique de lecture
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can view own devices'
    ) THEN
        CREATE POLICY "Users can view own devices" ON public.devices 
            FOR SELECT USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de lecture créée pour devices';
    END IF;

    -- Politique d'insertion
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can create own devices'
    ) THEN
        CREATE POLICY "Users can create own devices" ON public.devices 
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique d''insertion créée pour devices';
    END IF;

    -- Politique de mise à jour
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can update own devices'
    ) THEN
        CREATE POLICY "Users can update own devices" ON public.devices 
            FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de mise à jour créée pour devices';
    END IF;

    -- Politique de suppression
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can delete own devices'
    ) THEN
        CREATE POLICY "Users can delete own devices" ON public.devices 
            FOR DELETE USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de suppression créée pour devices';
    END IF;
END $$;

-- Politiques pour repairs
DO $$
BEGIN
    -- Politique de lecture
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'repairs' 
            AND policyname = 'Users can view own repairs'
    ) THEN
        CREATE POLICY "Users can view own repairs" ON public.repairs 
            FOR SELECT USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de lecture créée pour repairs';
    END IF;

    -- Politique d'insertion
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'repairs' 
            AND policyname = 'Users can create own repairs'
    ) THEN
        CREATE POLICY "Users can create own repairs" ON public.repairs 
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique d''insertion créée pour repairs';
    END IF;

    -- Politique de mise à jour
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'repairs' 
            AND policyname = 'Users can update own repairs'
    ) THEN
        CREATE POLICY "Users can update own repairs" ON public.repairs 
            FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de mise à jour créée pour repairs';
    END IF;

    -- Politique de suppression
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'repairs' 
            AND policyname = 'Users can delete own repairs'
    ) THEN
        CREATE POLICY "Users can delete own repairs" ON public.repairs 
            FOR DELETE USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de suppression créée pour repairs';
    END IF;
END $$;

-- 8. RAFRAÎCHIR LE CACHE POSTGREST (CRITIQUE)
SELECT '=== RAFRAÎCHISSEMENT DU CACHE ===' as section;

NOTIFY pgrst, 'reload schema';

-- 9. ATTENDRE UN MOMENT POUR LA SYNCHRONISATION
SELECT pg_sleep(3);

-- 10. VÉRIFIER LA STRUCTURE FINALE
SELECT '=== STRUCTURE FINALE CLIENTS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE FINALE DEVICES ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE FINALE REPAIRS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'repairs'
ORDER BY ordinal_position;

-- 11. TESTS D'INSERTION
SELECT '=== TESTS D''INSERTION ===' as section;

-- Test d'insertion client
DO $$
DECLARE
    test_client_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, utilisation d''un ID par défaut';
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Test d'insertion client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, notes, user_id
    ) VALUES (
        'Test Complet', 'Client', 'test.complet@example.com', '0123456789', '123 Test St', 'Notes de test complètes', current_user_id
    ) RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Test d''insertion client réussi. Client ID: %', test_client_id;
    
    -- Nettoyer le test
    DELETE FROM public.clients WHERE id = test_client_id;
    RAISE NOTICE '✅ Test client nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test client: %', SQLERRM;
END $$;

-- Test d'insertion device
DO $$
DECLARE
    test_device_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, utilisation d''un ID par défaut';
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Test d'insertion device
    INSERT INTO public.devices (
        brand, model, serial_number, type, specifications, user_id
    ) VALUES (
        'Apple', 'iPhone 15', 'SN123456789', 'smartphone', '{"color": "black", "storage": "128GB"}', current_user_id
    ) RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Test d''insertion device réussi. Device ID: %', test_device_id;
    
    -- Nettoyer le test
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '✅ Test device nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test device: %', SQLERRM;
END $$;

-- Test d'insertion repair
DO $$
DECLARE
    test_repair_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, utilisation d''un ID par défaut';
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Test d'insertion repair
    INSERT INTO public.repairs (
        client_id, device_id, status, description, issue, estimated_duration, actual_duration, due_date, user_id
    ) VALUES (
        NULL, NULL, 'new', 'Test de réparation', 'Problème de test', 60, 45, NOW() + INTERVAL '7 days', current_user_id
    ) RETURNING id INTO test_repair_id;
    
    RAISE NOTICE '✅ Test d''insertion repair réussi. Repair ID: %', test_repair_id;
    
    -- Nettoyer le test
    DELETE FROM public.repairs WHERE id = test_repair_id;
    RAISE NOTICE '✅ Test repair nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test repair: %', SQLERRM;
END $$;

-- 12. VÉRIFICATION FINALE
SELECT 'CORRECTION COMPLÈTE DE TOUTES LES TABLES TERMINÉE' as status;
