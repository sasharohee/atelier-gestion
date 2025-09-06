-- Fonction RPC simplifiée pour créer un utilisateur (version fallback)
-- Cette version évite les problèmes de syntaxe et d'échappement

CREATE OR REPLACE FUNCTION create_user_simple_fallback(
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
  -- Vérifier que l'utilisateur actuel est authentifié
  IF auth.uid() IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Utilisateur non authentifie.'
    );
  END IF;

  -- Vérifier si l'email existe déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'L''email ' || p_email || ' est deja utilise par un autre utilisateur.'
    );
  END IF;

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe deja.'
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
    created_by,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    auth.uid(),
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
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$$;

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_simple_fallback(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
