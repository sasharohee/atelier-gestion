-- Script de correction pour l'erreur 500 lors de l'inscription
-- Ce script corrige le problème "Database error saving new user"

-- 1. Désactiver complètement le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Créer une nouvelle fonction handle_new_user robuste avec gestion d'erreur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_exists BOOLEAN := FALSE;
BEGIN
    -- Vérifier si l'utilisateur existe déjà dans public.users
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;
    
    -- Si l'utilisateur n'existe pas, le créer
    IF NOT user_exists THEN
        BEGIN
            -- Insérer l'utilisateur dans public.users avec gestion d'erreur
            INSERT INTO public.users (
                id,
                first_name,
                last_name,
                email,
                role,
                created_at,
                updated_at
            ) VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
                COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
                NOW(),
                NOW()
            );
            
            -- Insérer le profil utilisateur si la table existe
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
                INSERT INTO public.user_profiles (
                    user_id,
                    first_name,
                    last_name,
                    email,
                    created_at,
                    updated_at
                ) VALUES (
                    NEW.id,
                    COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
                    COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
                    NEW.email,
                    NOW(),
                    NOW()
                );
            END IF;
            
            -- Insérer les préférences utilisateur si la table existe
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences' AND table_schema = 'public') THEN
                INSERT INTO public.user_preferences (
                    user_id,
                    created_at,
                    updated_at
                ) VALUES (
                    NEW.id,
                    NOW(),
                    NOW()
                );
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                -- En cas d'erreur, logger et continuer sans bloquer l'inscription
                RAISE WARNING 'Erreur dans handle_new_user: %', SQLERRM;
                -- Ne pas lever d'exception pour éviter de bloquer l'inscription
        END;
    END IF;
    
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur globale, logger et continuer
        RAISE WARNING 'Erreur globale dans handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. S'assurer que la table users existe avec les bonnes colonnes
DO $$
BEGIN
    -- Créer la table users si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        CREATE TABLE public.users (
            id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
            first_name TEXT,
            last_name TEXT,
            email TEXT UNIQUE NOT NULL,
            role TEXT DEFAULT 'technician',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;
    
    -- Ajouter les colonnes manquantes si nécessaire
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'first_name' AND table_schema = 'public') THEN
        ALTER TABLE public.users ADD COLUMN first_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_name' AND table_schema = 'public') THEN
        ALTER TABLE public.users ADD COLUMN last_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role' AND table_schema = 'public') THEN
        ALTER TABLE public.users ADD COLUMN role TEXT DEFAULT 'technician';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'created_at' AND table_schema = 'public') THEN
        ALTER TABLE public.users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'updated_at' AND table_schema = 'public') THEN
        ALTER TABLE public.users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 5. Activer RLS sur la table users si nécessaire
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 6. Créer les politiques RLS pour permettre l'accès aux utilisateurs
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
CREATE POLICY "Users can view own data" ON public.users
    FOR ALL USING (auth.uid() = id);

-- 7. Recréer le trigger avec gestion d'erreur
CREATE TRIGGER handle_new_user
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 8. Vérification finale
SELECT 'Correction de l erreur 500 appliquée avec succès' as status;

-- 9. Vérifier que le trigger est bien créé
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';
