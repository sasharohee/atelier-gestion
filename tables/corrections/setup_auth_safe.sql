-- Configuration sécurisée des tables d'authentification pour Atelier Gestion
-- Ce script vérifie l'existence des objets avant de les créer

-- 1. Création de la table users si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT CHECK (role IN ('admin', 'technician', 'manager')) DEFAULT 'technician',
    avatar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Création de la table user_profiles si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    company TEXT,
    position TEXT,
    bio TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Création de la table user_preferences si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    notifications_email BOOLEAN DEFAULT true,
    notifications_push BOOLEAN DEFAULT true,
    notifications_sms BOOLEAN DEFAULT false,
    theme_dark_mode BOOLEAN DEFAULT false,
    theme_compact_mode BOOLEAN DEFAULT false,
    language TEXT DEFAULT 'fr',
    timezone TEXT DEFAULT 'Europe/Paris',
    two_factor_auth BOOLEAN DEFAULT false,
    multiple_sessions BOOLEAN DEFAULT true,
    repair_notifications BOOLEAN DEFAULT true,
    status_notifications BOOLEAN DEFAULT true,
    stock_notifications BOOLEAN DEFAULT true,
    daily_reports BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Activation de Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- 5. Suppression sécurisée des politiques existantes pour la table users
DO $$
BEGIN
    -- Supprimer les politiques existantes
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can view all users') THEN
        DROP POLICY "Users can view all users" ON public.users;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can update own profile') THEN
        DROP POLICY "Users can update own profile" ON public.users;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Only admins can create users') THEN
        DROP POLICY "Only admins can create users" ON public.users;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Only admins can delete users') THEN
        DROP POLICY "Only admins can delete users" ON public.users;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Ignorer les erreurs si les politiques n'existent pas
        NULL;
END $$;

-- 6. Création des politiques pour la table users
CREATE POLICY "Users can view all users" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Only admins can create users" ON public.users
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Only admins can delete users" ON public.users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 7. Suppression sécurisée des politiques existantes pour la table user_profiles
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can view all profiles') THEN
        DROP POLICY "Users can view all profiles" ON public.user_profiles;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can update own profile') THEN
        DROP POLICY "Users can update own profile" ON public.user_profiles;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can create own profile') THEN
        DROP POLICY "Users can create own profile" ON public.user_profiles;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Ignorer les erreurs si les politiques n'existent pas
        NULL;
END $$;

-- 8. Création des politiques pour la table user_profiles
CREATE POLICY "Users can view all profiles" ON public.user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can create own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 9. Suppression sécurisée des politiques existantes pour la table user_preferences
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can view own preferences') THEN
        DROP POLICY "Users can view own preferences" ON public.user_preferences;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can update own preferences') THEN
        DROP POLICY "Users can update own preferences" ON public.user_preferences;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can create own preferences') THEN
        DROP POLICY "Users can create own preferences" ON public.user_preferences;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Ignorer les erreurs si les politiques n'existent pas
        NULL;
END $$;

-- 10. Création des politiques pour la table user_preferences
CREATE POLICY "Users can view own preferences" ON public.user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can create own preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 11. Fonction pour créer automatiquement un profil utilisateur lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer automatiquement un enregistrement dans la table users
    INSERT INTO public.users (id, first_name, last_name, email, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
        COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician')
    );
    
    -- Créer automatiquement un profil utilisateur
    INSERT INTO public.user_profiles (user_id, first_name, last_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
        COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
        NEW.email
    );
    
    -- Créer automatiquement les préférences utilisateur
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Suppression sécurisée du trigger existant
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 13. Création du trigger pour appeler la fonction lors de la création d'un nouvel utilisateur
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 14. Fonction pour mettre à jour les timestamps (créée seulement si elle n'existe pas)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 15. Suppression sécurisée des triggers existants
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON public.user_preferences;

-- 16. Création des triggers pour mettre à jour automatiquement les timestamps
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 17. Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);

-- 18. Vérification de la configuration
SELECT 
    'Configuration sécurisée terminée' as status,
    COUNT(*) as total_users
FROM public.users;
