-- Script de correction pour les contraintes user_id dans les tables clients et devices
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si la colonne user_id existe dans la table clients
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'user_id'
    ) THEN
        -- Ajouter la colonne user_id si elle n'existe pas
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Vérifier si la colonne user_id existe dans la table devices
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'user_id'
    ) THEN
        -- Ajouter la colonne user_id si elle n'existe pas
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Vérifier si la colonne user_id existe dans la table repairs
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' AND column_name = 'user_id'
    ) THEN
        -- Ajouter la colonne user_id si elle n'existe pas
        ALTER TABLE public.repairs ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 4. Mettre à jour les enregistrements existants pour assigner un user_id par défaut
-- (utiliser le premier utilisateur admin ou le premier utilisateur disponible)
UPDATE public.clients 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.devices 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

UPDATE public.repairs 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

-- 5. Maintenant que tous les enregistrements ont un user_id, ajouter la contrainte NOT NULL
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;

-- 6. Mettre à jour les politiques RLS pour inclure user_id
-- Supprimer TOUTES les politiques existantes pour éviter les conflits
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.devices;
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;

-- 7. Créer de nouvelles politiques RLS basées sur user_id
-- Politiques pour la table clients
CREATE POLICY "Users can view own clients" ON public.clients
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own clients" ON public.clients
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own clients" ON public.clients
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own clients" ON public.clients
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table devices
CREATE POLICY "Users can view own devices" ON public.devices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own devices" ON public.devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices" ON public.devices
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices" ON public.devices
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour la table repairs
CREATE POLICY "Users can view own repairs" ON public.repairs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own repairs" ON public.repairs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own repairs" ON public.repairs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own repairs" ON public.repairs
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);

-- 9. Vérification de la structure finale
SELECT 
    'clients' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'clients' 
ORDER BY ordinal_position;

SELECT 
    'devices' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'devices' 
ORDER BY ordinal_position;

SELECT 
    'repairs' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'repairs' 
ORDER BY ordinal_position;

-- 10. Vérification des politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('clients', 'devices', 'repairs')
ORDER BY tablename, policyname;
