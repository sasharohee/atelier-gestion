-- Correction de l'accès aux clients créés par l'utilisateur système
-- Problème: Les clients créés par l'utilisateur système ne sont pas accessibles aux utilisateurs connectés

-- 1. Vérifier l'état actuel
SELECT 
    'État actuel' as status,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as clients_systeme,
    COUNT(CASE WHEN user_id != '00000000-0000-0000-0000-000000000000' THEN 1 END) as clients_utilisateurs
FROM public.clients;

-- 2. Option 1: Modifier les politiques RLS pour permettre l'accès aux clients système
-- Supprimer TOUTES les politiques existantes pour clients
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can view own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create clients" ON public.clients;

-- Créer de nouvelles politiques qui permettent l'accès aux clients système
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

-- 3. Option 2: Modifier les politiques pour les devices aussi
-- Supprimer TOUTES les politiques existantes pour devices
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can view own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create devices" ON public.devices;

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

-- 4. Vérification des politiques créées
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('clients', 'devices')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- 5. Test de la correction
-- Simuler un accès utilisateur aux clients système
SELECT 
    'Test accès clients' as test_type,
    COUNT(*) as clients_accessibles
FROM public.clients 
WHERE user_id = '00000000-0000-0000-0000-000000000000';

-- 6. Vérification finale
SELECT 
    'Correction terminée' as status,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as clients_systeme,
    COUNT(CASE WHEN user_id != '00000000-0000-0000-0000-000000000000' THEN 1 END) as clients_utilisateurs
FROM public.clients;
