-- Fonction RPC simplifiée pour créer un utilisateur
-- Cette fonction crée seulement l'enregistrement dans la table users
-- L'utilisateur devra être créé manuellement dans auth.users ou via l'API Supabase

CREATE OR REPLACE FUNCTION create_user_simple(
  p_user_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_role TEXT DEFAULT 'technician',
  p_avatar TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
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

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe déjà.'
    );
  END IF;

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
    p_user_id,
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
      'id', p_user_id,
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
      'error', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
    );
END;
$$;

-- Donner les permissions d'exécution à tous les utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION create_user_simple(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
