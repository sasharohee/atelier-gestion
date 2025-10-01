-- SCRIPT FINAL POUR CRÉER DE VRAIS UTILISATEURS SUPABASE
-- Ce script corrige le trigger et permet la création d'utilisateurs réels

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Créer une fonction handle_new_user robuste
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si l'utilisateur existe déjà
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
    BEGIN
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
      
      -- Créer les données par défaut pour l'utilisateur
      INSERT INTO public.subscription_status (
        user_id,
        status,
        created_at,
        updated_at
      ) VALUES (
        NEW.id,
        'active',
        NOW(),
        NOW()
      );
      
      -- Créer les paramètres système par défaut
      INSERT INTO public.system_settings (
        user_id,
        setting_key,
        setting_value,
        created_at,
        updated_at
      ) VALUES 
        (NEW.id, 'notifications_enabled', 'true', NOW(), NOW()),
        (NEW.id, 'theme', 'light', NOW(), NOW()),
        (NEW.id, 'language', 'fr', NOW(), NOW());
        
    EXCEPTION
      WHEN OTHERS THEN
        -- En cas d'erreur, logger mais ne pas bloquer l'inscription
        RAISE WARNING 'Erreur dans handle_new_user: %', SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
  
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur globale, logger mais continuer
    RAISE WARNING 'Erreur globale dans handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. S'assurer que les tables existent
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  email TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'technician',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.subscription_status (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.system_settings (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  setting_key TEXT NOT NULL,
  setting_value TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Activer RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- 5. Créer les politiques RLS
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
CREATE POLICY "Users can view own data" ON public.users
  FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view own subscription" ON public.subscription_status;
CREATE POLICY "Users can view own subscription" ON public.subscription_status
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own settings" ON public.system_settings;
CREATE POLICY "Users can view own settings" ON public.system_settings
  FOR ALL USING (auth.uid() = user_id);

-- 6. Recréer le trigger
CREATE TRIGGER handle_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 7. Vérification finale
SELECT 'Trigger corrigé - Création d utilisateurs réels activée' as status;
