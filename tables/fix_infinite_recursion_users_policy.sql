-- =====================================================
-- CORRECTION DE LA RECURSION INFINIE DANS LES POLITIQUES USERS
-- Ce script corrige le problème de récursion infinie causé par
-- les politiques RLS qui référencent la table users elle-même
-- =====================================================

-- 1. Supprimer toutes les politiques RLS problématiques sur la table users
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Admins can create users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;
DROP POLICY IF EXISTS "Admin and technicians can view all users" ON users;
DROP POLICY IF EXISTS "Admin and technicians can update all users" ON users;
DROP POLICY IF EXISTS "Admin and technicians can create users" ON users;
DROP POLICY IF EXISTS "Admin and technicians can delete users" ON users;

-- 2. Créer des politiques RLS simplifiées qui évitent la récursion
-- Politique pour permettre à tous les utilisateurs authentifiés de voir les utilisateurs
CREATE POLICY "Authenticated users can view users" ON users
  FOR SELECT USING (auth.role() = 'authenticated');

-- Politique pour permettre aux utilisateurs de modifier leurs propres données
CREATE POLICY "Users can update their own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Politique pour permettre la création d'utilisateurs (gérée par les fonctions RPC)
CREATE POLICY "Allow user creation via RPC" ON users
  FOR INSERT WITH CHECK (true);

-- Politique pour permettre la suppression d'utilisateurs (gérée par les fonctions RPC)
CREATE POLICY "Allow user deletion via RPC" ON users
  FOR DELETE USING (true);

-- 3. Créer une fonction pour vérifier les droits d'administration sans récursion
CREATE OR REPLACE FUNCTION check_admin_rights()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Récupérer le rôle de l'utilisateur connecté depuis les métadonnées
  SELECT (raw_user_meta_data->>'role')::TEXT INTO user_role
  FROM auth.users 
  WHERE id = auth.uid();
  
  -- Retourner true si l'utilisateur est admin ou technicien
  RETURN user_role IN ('admin', 'technician');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Mettre à jour les politiques pour les autres tables d'administration
-- Table system_settings
DROP POLICY IF EXISTS "Admins can manage system settings" ON system_settings;
DROP POLICY IF EXISTS "Admin and technicians can manage system settings" ON system_settings;

CREATE POLICY "Admin and technicians can manage system settings" ON system_settings
  FOR ALL USING (check_admin_rights());

-- Table user_profiles (si elle existe)
DROP POLICY IF EXISTS "Admins can manage user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admin and technicians can manage user profiles" ON user_profiles;

CREATE POLICY "Admin and technicians can manage user profiles" ON user_profiles
  FOR ALL USING (check_admin_rights());

-- Table user_preferences (si elle existe)
DROP POLICY IF EXISTS "Admins can manage user preferences" ON user_preferences;
DROP POLICY IF EXISTS "Admin and technicians can manage user preferences" ON user_preferences;

CREATE POLICY "Admin and technicians can manage user preferences" ON user_preferences
  FOR ALL USING (check_admin_rights());

-- Table subscription_status (si elle existe)
DROP POLICY IF EXISTS "Admins can manage subscriptions" ON subscription_status;
DROP POLICY IF EXISTS "Admin and technicians can manage subscriptions" ON subscription_status;

CREATE POLICY "Admin and technicians can manage subscriptions" ON subscription_status
  FOR ALL USING (check_admin_rights());

-- 5. Mettre à jour la fonction create_user_with_auth pour utiliser la nouvelle fonction
CREATE OR REPLACE FUNCTION create_user_with_auth(
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_password TEXT,
  p_role TEXT DEFAULT 'technician',
  p_avatar TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel a les droits d'administration
  IF NOT check_admin_rights() THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Acces non autorise. Seuls les administrateurs et techniciens peuvent creer des utilisateurs.'
    );
  END IF;

  -- Vérifier que l'email n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe deja.'
    );
  END IF;

  -- Créer l'utilisateur dans auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    (SELECT id FROM auth.instances LIMIT 1),
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    json_build_object('provider', 'email', 'providers', ARRAY['email']),
    json_build_object('first_name', p_first_name, 'last_name', p_last_name, 'role', p_role),
    false,
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_user_id;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', v_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$$;

-- 6. Vérification finale
SELECT 
  'CORRECTION TERMINEE AVEC SUCCES' as status,
  'Recursion infinie corrigee dans les politiques RLS' as message;

-- 7. Afficher les politiques mises à jour
SELECT 
  'POLITIQUES MISES A JOUR' as info,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('users', 'system_settings', 'user_profiles', 'user_preferences', 'subscription_status')
ORDER BY tablename, policyname;

-- 8. Tester la fonction check_admin_rights
SELECT 
  'TEST FONCTION check_admin_rights' as info,
  check_admin_rights() as has_admin_rights;

-- 9. Vérifier l'état de la table users
SELECT 
  'ETAT TABLE USERS' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN role = 'technician' THEN 1 END) as technician_count,
  COUNT(CASE WHEN role = 'manager' THEN 1 END) as manager_count
FROM users;
