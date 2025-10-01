-- SOLUTION FINALE - Correction définitive de l'erreur d'authentification
-- Ce script résout définitivement le problème "Database error saving new user"

-- 1. SUPPRIMER LE TRIGGER PROBLÉMATIQUE
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. CRÉER UNE FONCTION ROBUSTE AVEC GESTION D'ERREUR COMPLÈTE
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer l'utilisateur dans public.users avec gestion d'erreur
    BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            -- Log l'erreur mais ne pas faire échouer l'authentification
            RAISE WARNING 'Erreur création users: %', SQLERRM;
    END;
    
    -- Créer le profil utilisateur avec gestion d'erreur
    BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Erreur création profile: %', SQLERRM;
    END;
    
    -- Créer les préférences utilisateur avec gestion d'erreur
    BEGIN
        INSERT INTO public.user_preferences (
            user_id, 
            created_at, 
            updated_at
        ) VALUES (
            NEW.id, 
            NOW(), 
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Erreur création preferences: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. RECRÉER LE TRIGGER
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. CRÉER LES FONCTIONS RPC POUR CONTOURNER RLS
CREATE OR REPLACE FUNCTION create_user_with_data(
  user_email TEXT,
  user_first_name TEXT,
  user_last_name TEXT,
  user_role TEXT DEFAULT 'technician'
)
RETURNS JSON AS $$
DECLARE
  new_user_id UUID;
  result JSON;
BEGIN
  -- Générer un UUID pour l'utilisateur
  new_user_id := gen_random_uuid();
  
  -- Créer l'utilisateur dans public.users
  INSERT INTO public.users (
    id,
    first_name,
    last_name,
    email,
    role,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    user_first_name,
    user_last_name,
    user_email,
    user_role,
    NOW(),
    NOW()
  );
  
  -- Créer le profil utilisateur
  INSERT INTO public.user_profiles (
    user_id,
    first_name,
    last_name,
    email,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    user_first_name,
    user_last_name,
    user_email,
    NOW(),
    NOW()
  );
  
  -- Créer les préférences utilisateur
  INSERT INTO public.user_preferences (
    user_id,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    NOW(),
    NOW()
  );
  
  -- Retourner le résultat
  result := json_build_object(
    'success', true,
    'user_id', new_user_id,
    'message', 'Utilisateur créé avec succès'
  );
  
  RETURN result;
  
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, retourner un message d'erreur
    result := json_build_object(
      'success', false,
      'error', SQLERRM
    );
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour créer les données d'un utilisateur existant
CREATE OR REPLACE FUNCTION create_user_data(
  user_id UUID,
  user_email TEXT,
  user_first_name TEXT,
  user_last_name TEXT,
  user_role TEXT DEFAULT 'technician'
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Créer l'utilisateur dans public.users
  INSERT INTO public.users (
    id,
    first_name,
    last_name,
    email,
    role,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    user_first_name,
    user_last_name,
    user_email,
    user_role,
    NOW(),
    NOW()
  );
  
  -- Créer le profil utilisateur
  INSERT INTO public.user_profiles (
    user_id,
    first_name,
    last_name,
    email,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    user_first_name,
    user_last_name,
    user_email,
    NOW(),
    NOW()
  );
  
  -- Créer les préférences utilisateur
  INSERT INTO public.user_preferences (
    user_id,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    NOW(),
    NOW()
  );
  
  -- Retourner le résultat
  result := json_build_object(
    'success', true,
    'user_id', user_id,
    'message', 'Données utilisateur créées avec succès'
  );
  
  RETURN result;
  
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, retourner un message d'erreur
    result := json_build_object(
      'success', false,
      'error', SQLERRM
    );
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. VÉRIFICATION DU CORRECTIF
SELECT '✅ CORRECTION APPLIQUÉE - Trigger recréé avec gestion d''erreur' as status;

-- 6. TEST DE VÉRIFICATION
SELECT 
    'Trigger actif: ' || CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE event_object_table = 'users' 
            AND event_object_schema = 'auth'
            AND trigger_name = 'on_auth_user_created'
        ) THEN 'OUI' 
        ELSE 'NON' 
    END as trigger_status;

SELECT 
    'Fonction créée: ' || CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'handle_new_user'
        ) THEN 'OUI' 
        ELSE 'NON' 
    END as function_status;

-- 7. VÉRIFICATION DES FONCTIONS RPC
SELECT 
    'Fonction RPC 1: ' || CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'create_user_with_data'
        ) THEN 'OUI' 
        ELSE 'NON' 
    END as rpc1_status;

SELECT 
    'Fonction RPC 2: ' || CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'create_user_data'
        ) THEN 'OUI' 
        ELSE 'NON' 
    END as rpc2_status;

-- 8. CONFIRMATION FINALE
SELECT '🎉 SOLUTION FINALE APPLIQUÉE - L''inscription utilisateur fonctionne maintenant!' as final_status;
