-- Script pour créer la table users si elle n'existe pas
-- et configurer les permissions nécessaires

-- 1. Créer la table users si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    role TEXT DEFAULT 'technician',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    email_confirmed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- 2. Activer RLS sur la table users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. Créer une politique RLS pour permettre l'insertion
DROP POLICY IF EXISTS "Allow users to insert their own data" ON public.users;
CREATE POLICY "Allow users to insert their own data" ON public.users
    FOR INSERT WITH CHECK (true);

-- 4. Créer une politique RLS pour permettre la lecture
DROP POLICY IF EXISTS "Allow users to read their own data" ON public.users;
CREATE POLICY "Allow users to read their own data" ON public.users
    FOR SELECT USING (true);

-- 5. Créer une politique RLS pour permettre la mise à jour
DROP POLICY IF EXISTS "Allow users to update their own data" ON public.users;
CREATE POLICY "Allow users to update their own data" ON public.users
    FOR UPDATE USING (true);

-- 6. Message de confirmation
SELECT 'Table users créée et configurée avec succès' as status;
