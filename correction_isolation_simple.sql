-- Correction isolation simple - Gestion des politiques existantes
-- Problème: Les politiques RLS existent déjà

-- 1. Vérifier l'état actuel des politiques
SELECT 
    'Politiques devices existantes' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'devices'
AND schemaname = 'public'
ORDER BY policyname;

SELECT 
    'Politiques clients existantes' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'clients'
AND schemaname = 'public'
ORDER BY policyname;

SELECT 
    'Politiques appointments existantes' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'appointments'
AND schemaname = 'public'
ORDER BY policyname;

-- 2. Supprimer TOUTES les politiques existantes pour devices
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create devices" ON public.devices;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.devices;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.devices;
DROP POLICY IF EXISTS "Users can view own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own and system devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own and system devices" ON public.devices;

-- 3. Supprimer TOUTES les politiques existantes pour clients
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create clients" ON public.clients;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.clients;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.clients;
DROP POLICY IF EXISTS "Users can view own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own and system clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own and system clients" ON public.clients;

-- 4. Supprimer TOUTES les politiques existantes pour appointments
DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create appointments" ON public.appointments;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.appointments;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.appointments;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.appointments;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.appointments;
DROP POLICY IF EXISTS "Users can view own and system appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own and system appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own and system appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create own and system appointments" ON public.appointments;

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

-- 6. Créer les nouvelles politiques RLS pour clients
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

-- 7. Créer les nouvelles politiques RLS pour appointments
CREATE POLICY "Users can view own and system appointments" ON public.appointments
    FOR SELECT USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can create appointments" ON public.appointments
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid
    );

CREATE POLICY "Users can update own and system appointments" ON public.appointments
    FOR UPDATE USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can delete own and system appointments" ON public.appointments
    FOR DELETE USING (
        user_id = auth.uid() OR 
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 8. Mettre à jour les enregistrements sans user_id
UPDATE public.devices 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

UPDATE public.clients 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

UPDATE public.appointments 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

-- 9. Vérification finale
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

SELECT 
    'Politiques finales appointments' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'appointments'
AND schemaname = 'public'
ORDER BY policyname;

-- 10. Vérifier les données
SELECT 
    'Données devices' as info,
    COUNT(*) as total_devices,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as devices_systeme,
    COUNT(DISTINCT user_id) as utilisateurs_differents
FROM public.devices;

SELECT 
    'Données clients' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as clients_systeme,
    COUNT(DISTINCT user_id) as utilisateurs_differents
FROM public.clients;

SELECT 
    'Données appointments' as info,
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000' THEN 1 END) as appointments_systeme,
    COUNT(DISTINCT user_id) as utilisateurs_differents
FROM public.appointments;
