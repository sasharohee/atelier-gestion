-- =====================================================
-- CORRECTION COMPLÈTE DE TOUTES LES TABLES (INCLUANT DEVICE_MODELS)
-- =====================================================
-- Date: 2025-01-23
-- Problèmes: 
-- - "Could not find the 'notes' column of 'clients' in the schema cache"
-- - "Could not find the 'brand' column of 'devices' in the schema cache"
-- - "Could not find the 'actual_duration' column of 'repairs' in the schema cache"
-- - "Could not find the 'common_issues' column of 'device_models' in the schema cache"
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DE TOUTES LES TABLES
SELECT '=== STRUCTURE ACTUELLE CLIENTS ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'clients'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE ACTUELLE DEVICES ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE ACTUELLE REPAIRS ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'repairs'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE ACTUELLE DEVICE_MODELS ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. CORRECTION DE LA TABLE CLIENTS
SELECT '=== CORRECTION TABLE CLIENTS ===' as section;
DO $$
BEGIN
    -- Ajouter toutes les colonnes manquantes pour clients
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS first_name TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS last_name TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS email TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS phone TEXT;
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS notes TEXT;
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    RAISE NOTICE '✅ Colonnes clients ajoutées';
END $$;

-- 3. CORRECTION DE LA TABLE DEVICES
SELECT '=== CORRECTION TABLE DEVICES ===' as section;
DO $$
BEGIN
    -- Ajouter toutes les colonnes manquantes pour devices
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS brand TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS model TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS serial_number TEXT;
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'other';
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS specifications JSONB;
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    RAISE NOTICE '✅ Colonnes devices ajoutées';
END $$;

-- 4. CORRECTION DE LA TABLE REPAIRS
SELECT '=== CORRECTION TABLE REPAIRS ===' as section;
DO $$
BEGIN
    -- Ajouter toutes les colonnes manquantes pour repairs
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.clients(id);
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS device_id UUID REFERENCES public.devices(id);
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'new';
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS assigned_technician_id UUID REFERENCES public.users(id);
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS description TEXT;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS issue TEXT;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS estimated_duration INTEGER;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS actual_duration INTEGER;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS estimated_start_date TIMESTAMP WITH TIME ZONE;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS estimated_end_date TIMESTAMP WITH TIME ZONE;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS due_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS is_urgent BOOLEAN DEFAULT false;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS notes TEXT;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2) DEFAULT 0;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT false;
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    RAISE NOTICE '✅ Colonnes repairs ajoutées';
END $$;

-- 5. CORRECTION DE LA TABLE DEVICE_MODELS
SELECT '=== CORRECTION TABLE DEVICE_MODELS ===' as section;
DO $$
BEGIN
    -- Ajouter toutes les colonnes manquantes pour device_models
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS brand TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS model TEXT NOT NULL DEFAULT '';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'other';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS year INTEGER NOT NULL DEFAULT 2024;
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS specifications JSONB DEFAULT '{}';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS common_issues TEXT[] DEFAULT '{}';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS repair_difficulty TEXT DEFAULT 'medium';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS parts_availability TEXT DEFAULT 'medium';
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    RAISE NOTICE '✅ Colonnes device_models ajoutées';
END $$;

-- 6. CRÉER LES INDEX NÉCESSAIRES
SELECT '=== CRÉATION DES INDEX ===' as section;
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_email ON public.clients(email);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_brand ON public.devices(brand);
CREATE INDEX IF NOT EXISTS idx_devices_type ON public.devices(type);
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_client_id ON public.repairs(client_id);
CREATE INDEX IF NOT EXISTS idx_repairs_device_id ON public.repairs(device_id);
CREATE INDEX IF NOT EXISTS idx_repairs_status ON public.repairs(status);
CREATE INDEX IF NOT EXISTS idx_device_models_brand ON public.device_models(brand);
CREATE INDEX IF NOT EXISTS idx_device_models_type ON public.device_models(type);
CREATE INDEX IF NOT EXISTS idx_device_models_is_active ON public.device_models(is_active);

-- 7. ACTIVER RLS SUR TOUTES LES TABLES
SELECT '=== ACTIVATION RLS ===' as section;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;

-- 8. CRÉER LES POLITIQUES RLS DE BASE
SELECT '=== CRÉATION DES POLITIQUES RLS ===' as section;
DO $$
BEGIN
    -- Politiques pour clients
    DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
    DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
    DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
    DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
    
    CREATE POLICY "Users can view own clients" ON public.clients FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can create own clients" ON public.clients FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update own clients" ON public.clients FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can delete own clients" ON public.clients FOR DELETE USING (auth.uid() = user_id);
    
    -- Politiques pour devices
    DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
    DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
    DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
    DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
    
    CREATE POLICY "Users can view own devices" ON public.devices FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can create own devices" ON public.devices FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update own devices" ON public.devices FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can delete own devices" ON public.devices FOR DELETE USING (auth.uid() = user_id);
    
    -- Politiques pour repairs
    DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
    DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
    DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
    DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;
    
    CREATE POLICY "Users can view own repairs" ON public.repairs FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can create own repairs" ON public.repairs FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update own repairs" ON public.repairs FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can delete own repairs" ON public.repairs FOR DELETE USING (auth.uid() = user_id);
    
    RAISE NOTICE '✅ Politiques RLS créées';
END $$;

-- 9. RAFRAÎCHIR LE CACHE POSTGREST (CRITIQUE)
SELECT '=== RAFRAÎCHISSEMENT DU CACHE ===' as section;
NOTIFY pgrst, 'reload schema';

-- 10. ATTENDRE UN MOMENT POUR LA SYNCHRONISATION
SELECT pg_sleep(3);

-- 11. VÉRIFIER LA STRUCTURE FINALE
SELECT '=== STRUCTURE FINALE CLIENTS ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'clients'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE FINALE DEVICES ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE FINALE REPAIRS ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'repairs'
ORDER BY ordinal_position;

SELECT '=== STRUCTURE FINALE DEVICE_MODELS ===' as section;
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 12. TESTS D'INSERTION
SELECT '=== TESTS D''INSERTION ===' as section;

-- Test d'insertion client
DO $$
DECLARE
    test_client_id UUID;
    current_user_id UUID;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    IF current_user_id IS NULL THEN
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    INSERT INTO public.clients (first_name, last_name, email, phone, address, notes, user_id)
    VALUES ('Test', 'Client', 'test@example.com', '0123456789', '123 Test St', 'Notes de test', current_user_id)
    RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Test client réussi. ID: %', test_client_id;
    DELETE FROM public.clients WHERE id = test_client_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur test client: %', SQLERRM;
END $$;

-- Test d'insertion device
DO $$
DECLARE
    test_device_id UUID;
    current_user_id UUID;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    IF current_user_id IS NULL THEN
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    INSERT INTO public.devices (brand, model, serial_number, type, specifications, user_id)
    VALUES ('Apple', 'iPhone 15', 'SN123456789', 'smartphone', '{"color": "black"}', current_user_id)
    RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Test device réussi. ID: %', test_device_id;
    DELETE FROM public.devices WHERE id = test_device_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur test device: %', SQLERRM;
END $$;

-- Test d'insertion repair
DO $$
DECLARE
    test_repair_id UUID;
    current_user_id UUID;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    IF current_user_id IS NULL THEN
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    INSERT INTO public.repairs (client_id, device_id, status, description, issue, estimated_duration, actual_duration, due_date, user_id)
    VALUES (NULL, NULL, 'new', 'Test de réparation', 'Problème de test', 60, 45, NOW() + INTERVAL '7 days', current_user_id)
    RETURNING id INTO test_repair_id;
    
    RAISE NOTICE '✅ Test repair réussi. ID: %', test_repair_id;
    DELETE FROM public.repairs WHERE id = test_repair_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur test repair: %', SQLERRM;
END $$;

-- Test d'insertion device_model
DO $$
DECLARE
    test_model_id UUID;
BEGIN
    INSERT INTO public.device_models (brand, model, type, year, specifications, common_issues, repair_difficulty, parts_availability, is_active)
    VALUES ('Apple', 'iPhone 15', 'smartphone', 2024, '{"screen": "6.1 inch"}', ARRAY['Écran cassé'], 'medium', 'high', true)
    RETURNING id INTO test_model_id;
    
    RAISE NOTICE '✅ Test device_model réussi. ID: %', test_model_id;
    DELETE FROM public.device_models WHERE id = test_model_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur test device_model: %', SQLERRM;
END $$;

-- 13. VÉRIFICATION FINALE
SELECT 'CORRECTION COMPLÈTE DE TOUTES LES TABLES TERMINÉE' as status;
