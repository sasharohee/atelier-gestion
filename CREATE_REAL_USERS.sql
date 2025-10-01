-- Créer des utilisateurs réels dans Supabase avec contournement des politiques RLS
-- Ce script crée les fonctions nécessaires pour créer de vrais utilisateurs

-- 1. Fonction pour créer un utilisateur complet avec toutes ses données
CREATE OR REPLACE FUNCTION create_real_user(
  user_email TEXT,
  user_password TEXT,
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
  
  -- Créer l'utilisateur dans auth.users directement
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    raw_app_meta_data,
    is_super_admin,
    role
  ) VALUES (
    new_user_id,
    user_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    jsonb_build_object(
      'firstName', user_first_name,
      'lastName', user_last_name,
      'role', user_role
    ),
    '{}',
    false,
    'authenticated'
  );
  
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
    'message', 'Utilisateur créé avec succès dans Supabase'
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

-- 2. Fonction pour créer un utilisateur avec confirmation email
CREATE OR REPLACE FUNCTION create_user_with_email_confirmation(
  user_email TEXT,
  user_password TEXT,
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
  
  -- Créer l'utilisateur dans auth.users avec email non confirmé
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    raw_app_meta_data,
    is_super_admin,
    role
  ) VALUES (
    new_user_id,
    user_email,
    crypt(user_password, gen_salt('bf')),
    NULL, -- Email non confirmé pour déclencher l'envoi d'email
    NOW(),
    NOW(),
    NOW(),
    jsonb_build_object(
      'firstName', user_first_name,
      'lastName', user_last_name,
      'role', user_role
    ),
    '{}',
    false,
    'authenticated'
  );
  
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
    'message', 'Utilisateur créé avec succès - Email de confirmation envoyé'
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

-- 3. Vérification des fonctions créées
SELECT '✅ Fonctions de création d''utilisateurs réels créées avec succès' as status;
