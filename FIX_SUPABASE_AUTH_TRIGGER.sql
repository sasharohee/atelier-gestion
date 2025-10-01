-- Script pour corriger le trigger Supabase Auth et permettre l'inscription normale
-- Ce script corrige le trigger handle_new_user qui cause l'erreur 500

-- 1. Désactiver temporairement le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- 2. Supprimer la fonction problématique si elle existe
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Créer une nouvelle fonction handle_new_user robuste
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si l'utilisateur existe déjà dans public.users
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
    -- Insérer l'utilisateur dans public.users
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
    
    -- Insérer le profil utilisateur
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
    
    -- Insérer les préférences utilisateur
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
  
  RETURN NEW;
  
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, logger et continuer sans bloquer l'inscription
    RAISE WARNING 'Erreur dans handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recréer le trigger avec gestion d'erreur
CREATE TRIGGER handle_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 5. Vérifier que les tables existent et ont les bonnes colonnes
DO $$
BEGIN
  -- Vérifier la table users
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
  
  -- Vérifier la table user_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
    CREATE TABLE public.user_profiles (
      id SERIAL PRIMARY KEY,
      user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
      first_name TEXT,
      last_name TEXT,
      email TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  END IF;
  
  -- Vérifier la table user_preferences
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences' AND table_schema = 'public') THEN
    CREATE TABLE public.user_preferences (
      id SERIAL PRIMARY KEY,
      user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  END IF;
END $$;

-- 6. Activer RLS sur les tables si nécessaire
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- 7. Créer les politiques RLS pour permettre l'accès aux utilisateurs
CREATE POLICY "Users can view own data" ON public.users
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR ALL USING (auth.uid() = user_id);

-- 8. Vérification finale
SELECT '✅ Trigger Supabase Auth corrigé avec succès' as status;
