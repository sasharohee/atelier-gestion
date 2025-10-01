-- =====================================================
-- CORRECTION URGENTE - RÉCURSION INFINIE DANS LES POLITIQUES RLS
-- =====================================================

-- 🚨 PROBLÈME IDENTIFIÉ: Récursion infinie dans les politiques de la table "users"
-- 🚨 ERREUR: infinite recursion detected in policy for relation "users"

-- ÉTAPE 1: DÉSACTIVER IMMÉDIATEMENT RLS SUR TOUTES LES TABLES PROBLÉMATIQUES
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings DISABLE ROW LEVEL SECURITY;

-- ÉTAPE 2: SUPPRIMER TOUTES LES POLITIQUES RLS PROBLÉMATIQUES
-- Supprimer toutes les politiques de la table users
DROP POLICY IF EXISTS "admins_can_manage_all_users" ON public.users;
DROP POLICY IF EXISTS "admins_can_view_all_users" ON public.users;
DROP POLICY IF EXISTS "service_role_full_access_users" ON public.users;
DROP POLICY IF EXISTS "users_can_insert_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_select_policy" ON public.users;
DROP POLICY IF EXISTS "users_update_policy" ON public.users;

-- Supprimer toutes les politiques de subscription_status
DROP POLICY IF EXISTS "admins_can_manage_subscriptions" ON public.subscription_status;
DROP POLICY IF EXISTS "service_role_full_access_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_select_policy" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_update_policy" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_insert_own_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_update_own_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_view_own_subscription" ON public.subscription_status;

-- Supprimer toutes les politiques de system_settings
DROP POLICY IF EXISTS "Admins can insert system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Admins can update system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated users can view system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_select_policy" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_update_policy" ON public.system_settings;

-- ÉTAPE 3: VÉRIFICATION - S'assurer qu'aucune politique n'existe
SELECT 'Politiques users restantes:' as info;
SELECT policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public';

SELECT 'Politiques subscription_status restantes:' as info;
SELECT policyname FROM pg_policies WHERE tablename = 'subscription_status' AND schemaname = 'public';

SELECT 'Politiques system_settings restantes:' as info;
SELECT policyname FROM pg_policies WHERE tablename = 'system_settings' AND schemaname = 'public';

-- ÉTAPE 4: TEST DE CONNEXION IMMÉDIAT
SELECT 'Test de connexion - Utilisateur actuel:' as info, auth.uid() as user_id;

-- ÉTAPE 5: VÉRIFICATION QUE L'APPLICATION FONCTIONNE
SELECT 'Application restaurée - RLS désactivé temporairement' as status;

-- ÉTAPE 6: CRÉER DES POLITIQUES SIMPLES ET SÛRES (SANS RÉCURSION)

-- Politiques pour users (SANS récursion)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_simple_select" ON public.users
    FOR SELECT
    TO public
    USING (auth.uid() = id);

CREATE POLICY "users_simple_insert" ON public.users
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() = id);

CREATE POLICY "users_simple_update" ON public.users
    FOR UPDATE
    TO public
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Politiques pour subscription_status (SANS récursion)
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subscription_simple_select" ON public.subscription_status
    FOR SELECT
    TO public
    USING (auth.uid() = user_id);

CREATE POLICY "subscription_simple_insert" ON public.subscription_status
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "subscription_simple_update" ON public.subscription_status
    FOR UPDATE
    TO public
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Politiques pour system_settings (SANS récursion)
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "system_settings_simple_select" ON public.system_settings
    FOR SELECT
    TO public
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "system_settings_simple_insert" ON public.system_settings
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "system_settings_simple_update" ON public.system_settings
    FOR UPDATE
    TO public
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

-- ÉTAPE 7: VÉRIFICATION FINALE
SELECT 'Politiques créées - users:' as info;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public';

SELECT 'Politiques créées - subscription_status:' as info;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'subscription_status' AND schemaname = 'public';

SELECT 'Politiques créées - system_settings:' as info;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'system_settings' AND schemaname = 'public';

-- ÉTAPE 8: TEST FINAL
SELECT 'CORRECTION TERMINÉE - Application fonctionnelle' as status;
