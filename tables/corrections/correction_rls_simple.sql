-- Correction RLS Simple - Éviter les conflits de noms
-- Date: 2024-01-24
-- Script simplifié pour activer RLS sans conflits de variables

-- ========================================
-- 1. ACTIVER RLS SUR LES TABLES PRINCIPALES
-- ========================================

-- Activer RLS sur les tables principales (une par une pour éviter les conflits)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repair_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscription_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
-- ========================================

-- Supprimer toutes les politiques existantes pour éviter les conflits
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Users can update own data" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can insert users" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;

DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can view clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can insert clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can update clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can delete clients" ON public.clients;

-- Supprimer les politiques pour les autres tables
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can insert own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "Authenticated users can view devices" ON public.devices;
DROP POLICY IF EXISTS "Authenticated users can insert devices" ON public.devices;
DROP POLICY IF EXISTS "Authenticated users can update devices" ON public.devices;
DROP POLICY IF EXISTS "Authenticated users can delete devices" ON public.devices;

DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can insert own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Authenticated users can view repairs" ON public.repairs;
DROP POLICY IF EXISTS "Authenticated users can insert repairs" ON public.repairs;
DROP POLICY IF EXISTS "Authenticated users can update repairs" ON public.repairs;
DROP POLICY IF EXISTS "Authenticated users can delete repairs" ON public.repairs;

DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can insert own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;
DROP POLICY IF EXISTS "Authenticated users can view products" ON public.products;
DROP POLICY IF EXISTS "Authenticated users can insert products" ON public.products;
DROP POLICY IF EXISTS "Authenticated users can update products" ON public.products;
DROP POLICY IF EXISTS "Authenticated users can delete products" ON public.products;

DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can insert own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;
DROP POLICY IF EXISTS "Authenticated users can view parts" ON public.parts;
DROP POLICY IF EXISTS "Authenticated users can insert parts" ON public.parts;
DROP POLICY IF EXISTS "Authenticated users can update parts" ON public.parts;
DROP POLICY IF EXISTS "Authenticated users can delete parts" ON public.parts;

DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can insert own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;
DROP POLICY IF EXISTS "Authenticated users can view services" ON public.services;
DROP POLICY IF EXISTS "Authenticated users can insert services" ON public.services;
DROP POLICY IF EXISTS "Authenticated users can update services" ON public.services;
DROP POLICY IF EXISTS "Authenticated users can delete services" ON public.services;

DROP POLICY IF EXISTS "Users can view own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can insert own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can update own sales" ON public.sales;
DROP POLICY IF EXISTS "Users can delete own sales" ON public.sales;
DROP POLICY IF EXISTS "Authenticated users can view sales" ON public.sales;
DROP POLICY IF EXISTS "Authenticated users can insert sales" ON public.sales;
DROP POLICY IF EXISTS "Authenticated users can update sales" ON public.sales;
DROP POLICY IF EXISTS "Authenticated users can delete sales" ON public.sales;

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can delete own orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated users can view orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated users can insert orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated users can update orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated users can delete orders" ON public.orders;

DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can insert own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can view appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can insert appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can update appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can delete appointments" ON public.appointments;

DROP POLICY IF EXISTS "Users can view own subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "Users can update own subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON public.subscription_status;
DROP POLICY IF EXISTS "Admins can insert subscriptions" ON public.subscription_status;

DROP POLICY IF EXISTS "Authenticated users can view system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Admins can update system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Admins can insert system_settings" ON public.system_settings;

DROP POLICY IF EXISTS "Users can view own suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Users can insert own suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Users can update own suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Users can delete own suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Authenticated users can view suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Authenticated users can insert suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Authenticated users can update suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Authenticated users can delete suppliers" ON public.suppliers;

-- ========================================
-- 3. CRÉER DES POLITIQUES RLS SIMPLES
-- ========================================

-- Politiques pour la table users
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can insert users" ON public.users
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can delete users" ON public.users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Politiques pour la table clients (politiques simples pour tous les utilisateurs authentifiés)
CREATE POLICY "Authenticated users can view clients" ON public.clients
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert clients" ON public.clients
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update clients" ON public.clients
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete clients" ON public.clients
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table devices
CREATE POLICY "Authenticated users can view devices" ON public.devices
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert devices" ON public.devices
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update devices" ON public.devices
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete devices" ON public.devices
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table repairs
CREATE POLICY "Authenticated users can view repairs" ON public.repairs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert repairs" ON public.repairs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update repairs" ON public.repairs
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete repairs" ON public.repairs
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table products
CREATE POLICY "Authenticated users can view products" ON public.products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert products" ON public.products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update products" ON public.products
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete products" ON public.products
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table parts
CREATE POLICY "Authenticated users can view parts" ON public.parts
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert parts" ON public.parts
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update parts" ON public.parts
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete parts" ON public.parts
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table services
CREATE POLICY "Authenticated users can view services" ON public.services
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert services" ON public.services
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update services" ON public.services
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete services" ON public.services
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table sales
CREATE POLICY "Authenticated users can view sales" ON public.sales
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert sales" ON public.sales
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update sales" ON public.sales
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete sales" ON public.sales
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table orders
CREATE POLICY "Authenticated users can view orders" ON public.orders
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert orders" ON public.orders
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update orders" ON public.orders
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete orders" ON public.orders
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table appointments
CREATE POLICY "Authenticated users can view appointments" ON public.appointments
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert appointments" ON public.appointments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update appointments" ON public.appointments
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete appointments" ON public.appointments
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politiques pour la table subscription_status
CREATE POLICY "Users can view own subscription" ON public.subscription_status
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own subscription" ON public.subscription_status
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can view all subscriptions" ON public.subscription_status
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can insert subscriptions" ON public.subscription_status
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Politiques pour la table system_settings (table globale)
CREATE POLICY "Authenticated users can view system_settings" ON public.system_settings
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can update system_settings" ON public.system_settings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can insert system_settings" ON public.system_settings
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Politiques pour la table suppliers
CREATE POLICY "Authenticated users can view suppliers" ON public.suppliers
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert suppliers" ON public.suppliers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update suppliers" ON public.suppliers
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete suppliers" ON public.suppliers
    FOR DELETE USING (auth.role() = 'authenticated');

-- ========================================
-- 4. VÉRIFIER L'ÉTAT DES POLITIQUES RLS
-- ========================================

-- Vérifier quelles tables ont RLS activé
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.tablename AND schemaname = t.schemaname) as policy_count
FROM pg_tables t
WHERE schemaname = 'public'
AND tablename IN (
    'users', 'clients', 'devices', 'repairs', 'products', 'parts', 
    'services', 'sales', 'orders', 'appointments', 'subscription_status',
    'system_settings', 'suppliers', 'reports', 'transactions',
    'user_profiles', 'user_preferences', 'technician_performance',
    'repair_history', 'subscription_audit', 
    'subscription_payments', 'subscription_plans', 'user_subscription_info', 
    'user_subscriptions'
)
ORDER BY tablename;

-- ========================================
-- 5. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 CORRECTION RLS SIMPLE APPLIQUÉE !';
    RAISE NOTICE '✅ RLS activé sur toutes les tables importantes';
    RAISE NOTICE '✅ Politiques de sécurité créées';
    RAISE NOTICE '✅ Sécurité basique appliquée';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 SÉCURITÉ APPLIQUÉE:';
    RAISE NOTICE '- Tous les utilisateurs authentifiés peuvent accéder aux données';
    RAISE NOTICE '- Les admins peuvent gérer les utilisateurs et paramètres';
    RAISE NOTICE '- Les politiques RLS empêchent l''accès non authentifié';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ IMPORTANT:';
    RAISE NOTICE '- Les tables ne sont plus "Unrestricted"';
    RAISE NOTICE '- La sécurité est maintenant activée';
    RAISE NOTICE '- Testez l''inscription maintenant';
END $$;
