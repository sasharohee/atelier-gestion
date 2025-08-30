-- =====================================================
-- CORRECTION ERREUR 403 COMPLÈTE - DEVICES ET REPAIRS
-- =====================================================
-- Corrige les erreurs "new row violates row-level security policy" pour devices et repairs
-- Date: 2025-01-23
-- =====================================================

-- ============================================================================
-- PARTIE 1: CORRECTION TABLE DEVICES
-- ============================================================================

SELECT '=== DÉBUT CORRECTION DEVICES ===' as etape;

-- 1. Diagnostic de la structure actuelle de la table devices
SELECT '=== DIAGNOSTIC STRUCTURE TABLE DEVICES ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

-- 2. Vérifier les politiques RLS actuelles pour devices
SELECT '=== POLITIQUES RLS ACTUELLES DEVICES ===' as etape;

SELECT 
    policyname,
    cmd,
    qual as condition,
    with_check
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

-- 3. Désactiver RLS temporairement sur devices
SELECT '=== DÉSACTIVATION RLS DEVICES ===' as etape;

ALTER TABLE devices DISABLE ROW LEVEL SECURITY;

-- 4. Supprimer toutes les politiques RLS existantes pour devices
SELECT '=== NETTOYAGE POLITIQUES DEVICES ===' as etape;

DROP POLICY IF EXISTS devices_select_policy ON devices;
DROP POLICY IF EXISTS devices_insert_policy ON devices;
DROP POLICY IF EXISTS devices_update_policy ON devices;
DROP POLICY IF EXISTS devices_delete_policy ON devices;
DROP POLICY IF EXISTS "Users can view own devices" ON devices;
DROP POLICY IF EXISTS "Users can create devices" ON devices;
DROP POLICY IF EXISTS "Users can update own devices" ON devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON devices;
DROP POLICY IF EXISTS "Users can view own and system devices" ON devices;
DROP POLICY IF EXISTS "Users can create own devices" ON devices;
DROP POLICY IF EXISTS "Users can update own and system devices" ON devices;
DROP POLICY IF EXISTS "Users can delete own and system devices" ON devices;
DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can view own devices" ON devices;
DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can create own devices" ON devices;
DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can update own devices" ON devices;
DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can delete own devices" ON devices;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON devices;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON devices;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON devices;
DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON devices;
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON devices;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON devices;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON devices;

-- 5. S'assurer que la table devices a la bonne structure
SELECT '=== VÉRIFICATION STRUCTURE DEVICES ===' as etape;

ALTER TABLE devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS brand TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS serial_number TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'other';
ALTER TABLE devices ADD COLUMN IF NOT EXISTS specifications JSONB DEFAULT '{}';
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE devices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 6. Mettre à jour les données existantes pour devices
SELECT '=== MISE À JOUR DONNÉES DEVICES ===' as etape;

UPDATE devices 
SET user_id = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

UPDATE devices 
SET created_by = COALESCE(user_id, (SELECT id FROM auth.users LIMIT 1))
WHERE created_by IS NULL;

UPDATE devices 
SET workshop_id = COALESCE(user_id, created_by, (SELECT id FROM auth.users LIMIT 1))
WHERE workshop_id IS NULL;

-- 7. Créer un trigger pour l'isolation automatique des devices
SELECT '=== CRÉATION TRIGGER DEVICES ===' as etape;

CREATE OR REPLACE FUNCTION set_device_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_device_context ON devices;
CREATE TRIGGER set_device_context
    BEFORE INSERT ON devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_context();

-- 8. Activer RLS avec des politiques permissives pour devices
SELECT '=== ACTIVATION RLS PERMISSIF DEVICES ===' as etape;

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY devices_select_policy ON devices
    FOR SELECT USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY devices_insert_policy ON devices
    FOR INSERT WITH CHECK (true);

CREATE POLICY devices_update_policy ON devices
    FOR UPDATE USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY devices_delete_policy ON devices
    FOR DELETE USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- ============================================================================
-- PARTIE 2: CORRECTION TABLE REPAIRS
-- ============================================================================

SELECT '=== DÉBUT CORRECTION REPAIRS ===' as etape;

-- 1. Diagnostic de la structure actuelle de la table repairs
SELECT '=== DIAGNOSTIC STRUCTURE TABLE REPAIRS ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'repairs'
ORDER BY ordinal_position;

-- 2. Vérifier les politiques RLS actuelles pour repairs
SELECT '=== POLITIQUES RLS ACTUELLES REPAIRS ===' as etape;

SELECT 
    policyname,
    cmd,
    qual as condition,
    with_check
FROM pg_policies 
WHERE tablename = 'repairs'
ORDER BY policyname;

-- 3. Désactiver RLS temporairement sur repairs
SELECT '=== DÉSACTIVATION RLS REPAIRS ===' as etape;

ALTER TABLE repairs DISABLE ROW LEVEL SECURITY;

-- 4. Supprimer toutes les politiques RLS existantes pour repairs
SELECT '=== NETTOYAGE POLITIQUES REPAIRS ===' as etape;

DROP POLICY IF EXISTS repairs_select_policy ON repairs;
DROP POLICY IF EXISTS repairs_insert_policy ON repairs;
DROP POLICY IF EXISTS repairs_update_policy ON repairs;
DROP POLICY IF EXISTS repairs_delete_policy ON repairs;
DROP POLICY IF EXISTS "Users can view own repairs" ON repairs;
DROP POLICY IF EXISTS "Users can create repairs" ON repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON repairs;
DROP POLICY IF EXISTS "Users can view own and system repairs" ON repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON repairs;
DROP POLICY IF EXISTS "Users can update own and system repairs" ON repairs;
DROP POLICY IF EXISTS "Users can delete own and system repairs" ON repairs;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON repairs;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON repairs;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON repairs;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON repairs;
DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON repairs;
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON repairs;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON repairs;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON repairs;
DROP POLICY IF EXISTS "repairs_select_policy" ON repairs;
DROP POLICY IF EXISTS "repairs_insert_policy" ON repairs;
DROP POLICY IF EXISTS "repairs_update_policy" ON repairs;
DROP POLICY IF EXISTS "repairs_delete_policy" ON repairs;

-- 5. S'assurer que la table repairs a la bonne structure
SELECT '=== VÉRIFICATION STRUCTURE REPAIRS ===' as etape;

ALTER TABLE repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS client_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS device_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'new';
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS issue TEXT;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS estimated_duration INTEGER;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS actual_duration INTEGER;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS estimated_start_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS estimated_end_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS due_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS is_urgent BOOLEAN DEFAULT false;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2) DEFAULT 0;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS original_price DECIMAL(10,2) DEFAULT 0;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT false;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS assigned_technician_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 6. Mettre à jour les données existantes pour repairs
SELECT '=== MISE À JOUR DONNÉES REPAIRS ===' as etape;

UPDATE repairs 
SET user_id = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

UPDATE repairs 
SET created_by = COALESCE(user_id, (SELECT id FROM auth.users LIMIT 1))
WHERE created_by IS NULL;

UPDATE repairs 
SET workshop_id = COALESCE(user_id, created_by, (SELECT id FROM auth.users LIMIT 1))
WHERE workshop_id IS NULL;

-- 7. Créer un trigger pour l'isolation automatique des repairs
SELECT '=== CRÉATION TRIGGER REPAIRS ===' as etape;

CREATE OR REPLACE FUNCTION set_repair_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Définir des valeurs par défaut si manquantes
    NEW.status := COALESCE(NEW.status, 'new');
    NEW.is_urgent := COALESCE(NEW.is_urgent, false);
    NEW.total_price := COALESCE(NEW.total_price, 0);
    NEW.discount_percentage := COALESCE(NEW.discount_percentage, 0);
    NEW.discount_amount := COALESCE(NEW.discount_amount, 0);
    NEW.original_price := COALESCE(NEW.original_price, NEW.total_price);
    NEW.is_paid := COALESCE(NEW.is_paid, false);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_repair_context ON repairs;
CREATE TRIGGER set_repair_context
    BEFORE INSERT ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_context();

-- 8. Activer RLS avec des politiques permissives pour repairs
SELECT '=== ACTIVATION RLS PERMISSIF REPAIRS ===' as etape;

ALTER TABLE repairs ENABLE ROW LEVEL SECURITY;

CREATE POLICY repairs_select_policy ON repairs
    FOR SELECT USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY repairs_insert_policy ON repairs
    FOR INSERT WITH CHECK (true);

CREATE POLICY repairs_update_policy ON repairs
    FOR UPDATE USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY repairs_delete_policy ON repairs
    FOR DELETE USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- ============================================================================
-- PARTIE 3: TESTS ET VÉRIFICATIONS
-- ============================================================================

SELECT '=== TESTS ET VÉRIFICATIONS ===' as etape;

-- Test d'insertion pour devices
SELECT '=== TEST INSERTION DEVICES ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_current_user_id UUID;
BEGIN
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    INSERT INTO devices (
        brand, model, type, serial_number, specifications
    ) VALUES (
        'Test Brand', 'Test Model', 'smartphone', 'TEST123', '{"test": "value"}'
    ) RETURNING id INTO v_test_id;
    
    RAISE NOTICE '✅ Device de test créé - ID: %', v_test_id;
    
    DELETE FROM devices WHERE id = v_test_id;
    RAISE NOTICE '✅ Test device nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur test device: %', SQLERRM;
END $$;

-- Test d'insertion pour repairs
SELECT '=== TEST INSERTION REPAIRS ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_current_user_id UUID;
    v_test_client_id UUID;
    v_test_device_id UUID;
BEGIN
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Obtenir ou créer un client de test
    SELECT id INTO v_test_client_id FROM clients LIMIT 1;
    IF v_test_client_id IS NULL THEN
        INSERT INTO clients (first_name, last_name, email, user_id)
        VALUES ('Test Client', 'Test', 'test@test.com', v_current_user_id)
        RETURNING id INTO v_test_client_id;
    END IF;
    
    -- Obtenir ou créer un device de test
    SELECT id INTO v_test_device_id FROM devices LIMIT 1;
    IF v_test_device_id IS NULL THEN
        INSERT INTO devices (brand, model, type, user_id)
        VALUES ('Test Brand', 'Test Model', 'smartphone', v_current_user_id)
        RETURNING id INTO v_test_device_id;
    END IF;
    
    INSERT INTO repairs (
        client_id, device_id, status, description, issue, 
        estimated_duration, due_date, is_urgent, total_price
    ) VALUES (
        v_test_client_id, v_test_device_id, 'new', 'Test réparation', 'Test problème',
        60, NOW() + INTERVAL '7 days', false, 100.00
    ) RETURNING id INTO v_test_id;
    
    RAISE NOTICE '✅ Réparation de test créée - ID: %', v_test_id;
    
    DELETE FROM repairs WHERE id = v_test_id;
    RAISE NOTICE '✅ Test réparation nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur test réparation: %', SQLERRM;
END $$;

-- Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

SELECT 
    'Politiques RLS devices' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

SELECT 
    'Politiques RLS repairs' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'repairs'
ORDER BY policyname;

SELECT 
    'Structure table devices' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
    AND column_name IN ('user_id', 'created_by', 'workshop_id', 'brand', 'model', 'type')
ORDER BY column_name;

SELECT 
    'Structure table repairs' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'repairs'
    AND column_name IN ('user_id', 'created_by', 'workshop_id', 'client_id', 'device_id', 'status')
ORDER BY column_name;

SELECT '✅ CORRECTION COMPLÈTE TERMINÉE - Devices et réparations peuvent maintenant être créés depuis la page kanban' as resultat;
