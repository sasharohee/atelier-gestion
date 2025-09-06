-- Correction isolation appareils et clients
-- Problème: Les appareils créés par un utilisateur sont visibles par d'autres utilisateurs

-- 1. Vérifier la structure actuelle de la table devices
SELECT 
    'Structure table devices' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'devices' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes sur la table devices
SELECT 
    'Contraintes table devices' as info,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'devices' 
AND table_schema = 'public';

-- 3. Vérifier les politiques RLS actuelles pour devices
SELECT 
    'Politiques RLS devices' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'devices'
AND schemaname = 'public'
ORDER BY policyname;

-- 4. Supprimer toutes les politiques RLS existantes pour devices
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create devices" ON public.devices;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.devices;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.devices;

-- 5. Créer les nouvelles politiques RLS pour devices
CREATE POLICY "Users can view own and system devices" ON public.devices
    FOR SELECT USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can create devices" ON public.devices
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid
    );

CREATE POLICY "Users can update own and system devices" ON public.devices
    FOR UPDATE USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can delete own and system devices" ON public.devices
    FOR DELETE USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 6. Vérifier les politiques RLS pour clients
SELECT 
    'Politiques RLS clients' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'clients'
AND schemaname = 'public'
ORDER BY policyname;

-- 7. Supprimer toutes les politiques RLS existantes pour clients
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create clients" ON public.clients;
DROP POLICY IF EXISTS "Users can view own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own and system clients" ON public.clients;

-- 8. Créer les nouvelles politiques RLS pour clients
CREATE POLICY "Users can view own and system clients" ON public.clients
    FOR SELECT USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can create clients" ON public.clients
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid
    );

CREATE POLICY "Users can update own and system clients" ON public.clients
    FOR UPDATE USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can delete own and system clients" ON public.clients
    FOR DELETE USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 9. Vérifier les données existantes
SELECT 
    'Données devices' as info,
    COUNT(*) as total_devices,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as devices_sans_user_id,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as devices_systeme,
    COUNT(DISTINCT user_id) as utilisateurs_differents
FROM public.devices;

SELECT 
    'Données clients' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as clients_systeme,
    COUNT(DISTINCT user_id) as utilisateurs_differents
FROM public.clients;

-- 10. Mettre à jour les enregistrements sans user_id
UPDATE public.devices 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

UPDATE public.clients 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

-- 11. Vérification finale des politiques
SELECT 
    'Politiques finales devices' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'devices'
AND schemaname = 'public'
ORDER BY policyname;

SELECT 
    'Politiques finales clients' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'clients'
AND schemaname = 'public'
ORDER BY policyname;

-- 12. Vérifier l'utilisateur système
SELECT 
    'Utilisateur système' as info,
    id,
    email,
    created_at
FROM public.users 
WHERE id = '00000000-0000-0000-0000-000000000000';
