-- =====================================================
-- REMISE ISOLATION RLS - TOUTES LES TABLES
-- =====================================================
-- Objectif: Remettre les politiques RLS et l'isolation sur toutes les tables
-- Date: 2025-01-23
-- =====================================================

-- 1. ACTIVER RLS SUR TOUTES LES TABLES
SELECT '=== ACTIVATION RLS ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
SELECT '=== SUPPRESSION POLITIQUES EXISTANTES ===' as section;

-- Clients
DROP POLICY IF EXISTS clients_select_policy ON public.clients;
DROP POLICY IF EXISTS clients_insert_policy ON public.clients;
DROP POLICY IF EXISTS clients_update_policy ON public.clients;
DROP POLICY IF EXISTS clients_delete_policy ON public.clients;

-- Devices
DROP POLICY IF EXISTS devices_select_policy ON public.devices;
DROP POLICY IF EXISTS devices_insert_policy ON public.devices;
DROP POLICY IF EXISTS devices_update_policy ON public.devices;
DROP POLICY IF EXISTS devices_delete_policy ON public.devices;

-- Repairs
DROP POLICY IF EXISTS repairs_select_policy ON public.repairs;
DROP POLICY IF EXISTS repairs_insert_policy ON public.repairs;
DROP POLICY IF EXISTS repairs_update_policy ON public.repairs;
DROP POLICY IF EXISTS repairs_delete_policy ON public.repairs;

-- Device Models
DROP POLICY IF EXISTS device_models_select_policy ON public.device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON public.device_models;
DROP POLICY IF EXISTS device_models_update_policy ON public.device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON public.device_models;

-- Products
DROP POLICY IF EXISTS products_select_policy ON public.products;
DROP POLICY IF EXISTS products_insert_policy ON public.products;
DROP POLICY IF EXISTS products_update_policy ON public.products;
DROP POLICY IF EXISTS products_delete_policy ON public.products;

-- Sales
DROP POLICY IF EXISTS sales_select_policy ON public.sales;
DROP POLICY IF EXISTS sales_insert_policy ON public.sales;
DROP POLICY IF EXISTS sales_update_policy ON public.sales;
DROP POLICY IF EXISTS sales_delete_policy ON public.sales;

-- Appointments
DROP POLICY IF EXISTS appointments_select_policy ON public.appointments;
DROP POLICY IF EXISTS appointments_insert_policy ON public.appointments;
DROP POLICY IF EXISTS appointments_update_policy ON public.appointments;
DROP POLICY IF EXISTS appointments_delete_policy ON public.appointments;

-- Messages
DROP POLICY IF EXISTS messages_select_policy ON public.messages;
DROP POLICY IF EXISTS messages_insert_policy ON public.messages;
DROP POLICY IF EXISTS messages_update_policy ON public.messages;
DROP POLICY IF EXISTS messages_delete_policy ON public.messages;

-- Transactions
DROP POLICY IF EXISTS transactions_select_policy ON public.transactions;
DROP POLICY IF EXISTS transactions_insert_policy ON public.transactions;
DROP POLICY IF EXISTS transactions_update_policy ON public.transactions;
DROP POLICY IF EXISTS transactions_delete_policy ON public.transactions;

-- 3. S'ASSURER QUE LES COLONNES D'ISOLATION EXISTENT
SELECT '=== VÉRIFICATION COLONNES ISOLATION ===' as section;

-- Clients
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans clients';
    END IF;
END $$;

-- Devices
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans devices';
    END IF;
END $$;

-- Repairs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à repairs';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans repairs';
    END IF;
END $$;

-- Device Models
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_models';
    END IF;
END $$;

-- Products
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans products';
    END IF;
END $$;

-- Sales
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans sales';
    END IF;
END $$;

-- Appointments
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans appointments';
    END IF;
END $$;

-- Messages
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.messages ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à messages';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans messages';
    END IF;
END $$;

-- Transactions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transactions' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.transactions ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à transactions';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans transactions';
    END IF;
END $$;

-- 4. CRÉER LES POLITIQUES RLS STRICTES
SELECT '=== CRÉATION POLITIQUES RLS ===' as section;

-- CLIENTS
CREATE POLICY clients_select_policy ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY clients_insert_policy ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY clients_update_policy ON public.clients
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY clients_delete_policy ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- DEVICES
CREATE POLICY devices_select_policy ON public.devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY devices_insert_policy ON public.devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY devices_update_policy ON public.devices
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY devices_delete_policy ON public.devices
    FOR DELETE USING (user_id = auth.uid());

-- REPAIRS
CREATE POLICY repairs_select_policy ON public.repairs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY repairs_insert_policy ON public.repairs
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY repairs_update_policy ON public.repairs
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY repairs_delete_policy ON public.repairs
    FOR DELETE USING (user_id = auth.uid());

-- DEVICE MODELS
CREATE POLICY device_models_select_policy ON public.device_models
    FOR SELECT USING (created_by = auth.uid());

CREATE POLICY device_models_insert_policy ON public.device_models
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY device_models_update_policy ON public.device_models
    FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY device_models_delete_policy ON public.device_models
    FOR DELETE USING (created_by = auth.uid());

-- PRODUCTS
CREATE POLICY products_select_policy ON public.products
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY products_insert_policy ON public.products
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY products_update_policy ON public.products
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY products_delete_policy ON public.products
    FOR DELETE USING (user_id = auth.uid());

-- SALES
CREATE POLICY sales_select_policy ON public.sales
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY sales_insert_policy ON public.sales
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY sales_update_policy ON public.sales
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY sales_delete_policy ON public.sales
    FOR DELETE USING (user_id = auth.uid());

-- APPOINTMENTS
CREATE POLICY appointments_select_policy ON public.appointments
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY appointments_insert_policy ON public.appointments
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY appointments_update_policy ON public.appointments
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY appointments_delete_policy ON public.appointments
    FOR DELETE USING (user_id = auth.uid());

-- MESSAGES
CREATE POLICY messages_select_policy ON public.messages
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY messages_insert_policy ON public.messages
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY messages_update_policy ON public.messages
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY messages_delete_policy ON public.messages
    FOR DELETE USING (user_id = auth.uid());

-- TRANSACTIONS
CREATE POLICY transactions_select_policy ON public.transactions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY transactions_insert_policy ON public.transactions
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY transactions_update_policy ON public.transactions
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY transactions_delete_policy ON public.transactions
    FOR DELETE USING (user_id = auth.uid());

-- 5. CRÉER LES TRIGGERS POUR L'ISOLATION AUTOMATIQUE
SELECT '=== CRÉATION TRIGGERS ===' as section;

-- Trigger pour clients
CREATE OR REPLACE FUNCTION set_client_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_client_user ON public.clients;
CREATE TRIGGER set_client_user
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user();

-- Trigger pour devices
CREATE OR REPLACE FUNCTION set_device_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_device_user ON public.devices;
CREATE TRIGGER set_device_user
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user();

-- Trigger pour repairs
CREATE OR REPLACE FUNCTION set_repair_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_repair_user ON public.repairs;
CREATE TRIGGER set_repair_user
    BEFORE INSERT ON public.repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_user();

-- Trigger pour device_models
CREATE OR REPLACE FUNCTION set_device_model_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_device_model_user ON public.device_models;
CREATE TRIGGER set_device_model_user
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_user();

-- Trigger pour products
CREATE OR REPLACE FUNCTION set_product_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_product_user ON public.products;
CREATE TRIGGER set_product_user
    BEFORE INSERT ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION set_product_user();

-- Trigger pour sales
CREATE OR REPLACE FUNCTION set_sale_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_sale_user ON public.sales;
CREATE TRIGGER set_sale_user
    BEFORE INSERT ON public.sales
    FOR EACH ROW
    EXECUTE FUNCTION set_sale_user();

-- Trigger pour appointments
CREATE OR REPLACE FUNCTION set_appointment_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_appointment_user ON public.appointments;
CREATE TRIGGER set_appointment_user
    BEFORE INSERT ON public.appointments
    FOR EACH ROW
    EXECUTE FUNCTION set_appointment_user();

-- Trigger pour messages
CREATE OR REPLACE FUNCTION set_message_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_message_user ON public.messages;
CREATE TRIGGER set_message_user
    BEFORE INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION set_message_user();

-- Trigger pour transactions
CREATE OR REPLACE FUNCTION set_transaction_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_transaction_user ON public.transactions;
CREATE TRIGGER set_transaction_user
    BEFORE INSERT ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION set_transaction_user();

-- 6. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier le statut RLS
SELECT 
    'Statut RLS' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'repairs', 'device_models', 'products', 'sales', 'appointments', 'messages', 'transactions')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    'Politiques créées' as info,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Vérifier les triggers créés
SELECT 
    'Triggers créés' as info,
    event_object_table,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'repairs', 'device_models', 'products', 'sales', 'appointments', 'messages', 'transactions')
ORDER BY event_object_table, trigger_name;

SELECT 'ISOLATION RLS REMISE AVEC SUCCÈS' as status;
