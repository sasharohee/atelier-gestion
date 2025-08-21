-- VÉRIFICATION ET CORRECTION DES POLITIQUES RLS D'ISOLATION
-- Ce script vérifie et corrige les politiques de sécurité au niveau des lignes

-- ============================================================================
-- 1. VÉRIFICATION DES POLITIQUES RLS EXISTANTES
-- ============================================================================

-- Afficher toutes les politiques RLS actuelles
SELECT 
    'Politiques RLS existantes' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- 2. VÉRIFICATION DE L'ACTIVATION RLS PAR TABLE
-- ============================================================================

-- Vérifier quelles tables ont RLS activé
SELECT 
    'Activation RLS par table' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 3. CRÉATION DES POLITIQUES RLS D'ISOLATION
-- ============================================================================

-- Activer RLS sur toutes les tables principales
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. SUPPRESSION DES ANCIENNES POLITIQUES (SI EXISTANTES)
-- ============================================================================

-- Supprimer les anciennes politiques pour éviter les conflits
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can insert own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can insert own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;

DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can insert own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;

DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can insert own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;

DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can insert own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;

DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can insert own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;

DROP POLICY IF EXISTS "Users can view own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can insert own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can update own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can delete own sales" ON public.sales;

DROP POLICY IF EXISTS "Users can view own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can insert own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can delete own messages" ON public.messages;

DROP POLICY IF EXISTS "Users can view own settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can delete own settings" ON public.system_settings;

-- ============================================================================
-- 5. CRÉATION DES NOUVELLES POLITIQUES D'ISOLATION
-- ============================================================================

-- Politiques pour la table clients
CREATE POLICY "Users can view own clients" ON public.clients
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own clients" ON public.clients
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own clients" ON public.clients
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own clients" ON public.clients
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table devices
CREATE POLICY "Users can view own devices" ON public.devices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own devices" ON public.devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices" ON public.devices
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices" ON public.devices
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table services
CREATE POLICY "Users can view own services" ON public.services
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own services" ON public.services
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own services" ON public.services
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own services" ON public.services
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table parts
CREATE POLICY "Users can view own parts" ON public.parts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own parts" ON public.parts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own parts" ON public.parts
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own parts" ON public.parts
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table products
CREATE POLICY "Users can view own products" ON public.products
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own products" ON public.products
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own products" ON public.products
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own products" ON public.products
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table repairs
CREATE POLICY "Users can view own repairs" ON public.repairs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own repairs" ON public.repairs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own repairs" ON public.repairs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own repairs" ON public.repairs
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table appointments
CREATE POLICY "Users can view own appointments" ON public.appointments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own appointments" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own appointments" ON public.appointments
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own appointments" ON public.appointments
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table sales
CREATE POLICY "Users can view own sales" ON public.sales
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sales" ON public.sales
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sales" ON public.sales
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own sales" ON public.sales
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table messages
CREATE POLICY "Users can view own messages" ON public.messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own messages" ON public.messages
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own messages" ON public.messages
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table system_settings
CREATE POLICY "Users can view own settings" ON public.system_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings" ON public.system_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" ON public.system_settings
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own settings" ON public.system_settings
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 6. VÉRIFICATION FINALE DES POLITIQUES
-- ============================================================================

-- Vérifier que toutes les politiques ont été créées
SELECT 
    'Politiques RLS finales' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Vérifier que RLS est activé sur toutes les tables
SELECT 
    'Activation RLS finale' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'appointments', 'sales', 'messages', 'system_settings')
ORDER BY tablename;
