-- =====================================================
-- CORRECTION COMPLÈTE DES TABLES CLIENTS ET DEVICES
-- =====================================================
-- Date: 2025-01-23
-- Problèmes: 
-- - "Could not find the 'notes' column of 'clients' in the schema cache"
-- - "Could not find the 'brand' column of 'devices' in the schema cache"
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DES TABLES
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

-- 4. CRÉER LES INDEX NÉCESSAIRES
SELECT '=== CRÉATION DES INDEX ===' as section;

-- Index pour clients
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_email ON public.clients(email);

-- Index pour devices
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_brand ON public.devices(brand);
CREATE INDEX IF NOT EXISTS idx_devices_type ON public.devices(type);

-- 5. ACTIVER RLS SUR LES DEUX TABLES
SELECT '=== ACTIVATION RLS ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER LES POLITIQUES RLS
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

-- 7. RAFRAÎCHIR LE CACHE POSTGREST (CRITIQUE)
SELECT '=== RAFRAÎCHISSEMENT DU CACHE ===' as section;

NOTIFY pgrst, 'reload schema';

-- 8. ATTENDRE UN MOMENT POUR LA SYNCHRONISATION
SELECT pg_sleep(3);

-- 9. VÉRIFIER LA STRUCTURE FINALE
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

-- 10. TESTS D'INSERTION
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

-- 11. VÉRIFICATION FINALE
SELECT 'CORRECTION COMPLÈTE DES TABLES CLIENTS ET DEVICES TERMINÉE' as status;
