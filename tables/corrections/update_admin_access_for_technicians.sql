-- =====================================================
-- MISE A JOUR DES POLITIQUES RLS POUR ACCES ADMINISTRATION
-- Ce script met a jour les politiques pour permettre aux techniciens
-- d'avoir acces aux fonctionnalites d'administration
-- =====================================================

-- 1. Fonction utilitaire pour verifier si l'utilisateur a les droits d'administration
CREATE OR REPLACE FUNCTION has_admin_access(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id AND (role = 'admin' OR role = 'technician')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Mettre a jour les politiques RLS pour la table users
-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Admins can create users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;

-- Creer les nouvelles politiques qui incluent les techniciens
CREATE POLICY "Admin and technicians can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

CREATE POLICY "Admin and technicians can update all users" ON users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

CREATE POLICY "Admin and technicians can create users" ON users
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

CREATE POLICY "Admin and technicians can delete users" ON users
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

-- 3. Mettre a jour les politiques pour les autres tables d'administration
-- Table system_settings
DROP POLICY IF EXISTS "Admins can manage system settings" ON system_settings;
CREATE POLICY "Admin and technicians can manage system settings" ON system_settings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

-- Table user_profiles (si elle existe)
DROP POLICY IF EXISTS "Admins can manage user profiles" ON user_profiles;
CREATE POLICY "Admin and technicians can manage user profiles" ON user_profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

-- Table user_preferences (si elle existe)
DROP POLICY IF EXISTS "Admins can manage user preferences" ON user_preferences;
CREATE POLICY "Admin and technicians can manage user preferences" ON user_preferences
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

-- 4. Mettre a jour les politiques pour les tables de gestion
-- Table subscription_status (si elle existe)
DROP POLICY IF EXISTS "Admins can manage subscriptions" ON subscription_status;
CREATE POLICY "Admin and technicians can manage subscriptions" ON subscription_status
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
    )
  );

-- 5. Verifier et mettre a jour les fonctions RPC qui verifient les roles
-- Fonction pour creer un utilisateur (mise a jour)
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
  -- Verifier que l'utilisateur actuel est un administrateur ou technicien
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Acces non autorise. Seuls les administrateurs et techniciens peuvent creer des utilisateurs.'
    );
  END IF;

  -- Verifier que l'email n'existe pas deja
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe deja.'
    );
  END IF;

  -- Creer l'utilisateur dans auth.users
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

  -- Creer l'enregistrement dans la table users
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

  -- Retourner le succes avec les donnees de l'utilisateur cree
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

-- 6. Verification finale
SELECT 
  'MISE A JOUR TERMINEE AVEC SUCCES' as status,
  'Politiques RLS mises a jour pour permettre l''acces aux techniciens' as message;

-- 7. Afficher les politiques mises a jour
SELECT 
  'POLITIQUES MISES A JOUR' as info,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('users', 'system_settings', 'user_profiles', 'user_preferences', 'subscription_status')
  AND policyname LIKE '%Admin and technicians%'
ORDER BY tablename, policyname;

-- 8. Tester la fonction has_admin_access
SELECT 
  'TEST FONCTION has_admin_access' as info,
  u.email,
  u.role,
  has_admin_access(u.id) as has_admin_access
FROM users u
ORDER BY u.role, u.email;
