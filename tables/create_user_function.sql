-- Fonction RPC pour créer un utilisateur de manière sécurisée
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
  -- Vérifier que l'utilisateur actuel est un administrateur
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Accès non autorisé. Seuls les administrateurs peuvent créer des utilisateurs.'
    );
  END IF;

  -- Vérifier que l'email n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe déjà.'
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
    -- En cas d'erreur, supprimer l'utilisateur auth créé si possible
    IF v_user_id IS NOT NULL THEN
      DELETE FROM auth.users WHERE id = v_user_id;
    END IF;
    
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
    );
END;
$$;

-- Donner les permissions d'exécution à tous les utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION create_user_with_auth(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Politique RLS pour permettre l'exécution de la fonction
CREATE POLICY "Allow authenticated users to execute create_user_with_auth" ON users
  FOR ALL USING (auth.role() = 'authenticated');
