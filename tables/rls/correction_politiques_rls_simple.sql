-- Correction simplifiée des politiques RLS
-- Ce script supprime et recrée toutes les politiques nécessaires

-- 1. Supprimer TOUTES les politiques existantes pour clients
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can view own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create clients" ON public.clients;

-- 2. Supprimer TOUTES les politiques existantes pour devices
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can view own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create devices" ON public.devices;

-- 3. Créer les nouvelles politiques pour clients
CREATE POLICY "Users can view own and system clients" ON public.clients
    FOR SELECT USING (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

CREATE POLICY "Users can update own and system clients" ON public.clients
    FOR UPDATE USING (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

CREATE POLICY "Users can delete own and system clients" ON public.clients
    FOR DELETE USING (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

CREATE POLICY "Users can create clients" ON public.clients
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

-- 4. Créer les nouvelles politiques pour devices
CREATE POLICY "Users can view own and system devices" ON public.devices
    FOR SELECT USING (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

CREATE POLICY "Users can update own and system devices" ON public.devices
    FOR UPDATE USING (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

CREATE POLICY "Users can delete own and system devices" ON public.devices
    FOR DELETE USING (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

CREATE POLICY "Users can create devices" ON public.devices
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR 
        user_id = '00000000-0000-0000-0000-000000000000'
    );

-- 5. Vérification
SELECT 
    'Correction terminée' as status,
    COUNT(*) as total_politiques
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices');
