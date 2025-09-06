-- Version simplifiée de la fonction pour créer un administrateur
-- Cette fonction est plus simple et plus robuste

CREATE OR REPLACE FUNCTION create_simple_admin_user(
  p_email TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_first_name TEXT;
  v_last_name TEXT;
  v_email_parts TEXT[];
  v_name_parts TEXT[];
  v_result JSON;
BEGIN
  -- Extraire le nom depuis l'email
  v_email_parts := string_to_array(p_email, '@');
  v_name_parts := string_to_array(v_email_parts[1], '.');
  
  IF array_length(v_name_parts, 1) >= 2 THEN
    v_first_name := initcap(v_name_parts[1]);
    v_last_name := initcap(v_name_parts[2]);
  ELSE
    v_first_name := initcap(v_email_parts[1]);
    v_last_name := 'Administrateur';
  END IF;
  
  -- Vérifier si l'utilisateur existe déjà
  SELECT id INTO v_user_id
  FROM users
  WHERE email = p_email;
  
  -- Si l'utilisateur existe déjà, le mettre à jour avec le rôle admin
  IF FOUND THEN
    UPDATE users 
    SET 
      role = 'admin',
      updated_at = NOW()
    WHERE id = v_user_id;
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur promu administrateur avec succès',
      'user_id', v_user_id,
      'email', p_email,
      'role', 'admin'
    );
  ELSE
    -- Créer un nouvel utilisateur administrateur
    v_user_id := gen_random_uuid();
    
    INSERT INTO users (
      id,
      first_name,
      last_name,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      v_first_name,
      v_last_name,
      p_email,
      'admin',
      NOW(),
      NOW()
    );
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur administrateur créé avec succès',
      'user_id', v_user_id,
      'email', p_email,
      'first_name', v_first_name,
      'last_name', v_last_name,
      'role', 'admin'
    );
  END IF;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erreur lors de la creation de l''utilisateur administrateur'
    );
    RETURN v_result;
END;
$$;

-- Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION create_simple_admin_user(TEXT) TO authenticated;

-- Commentaire sur la fonction
COMMENT ON FUNCTION create_simple_admin_user(TEXT) IS 
'Fonction simplifiée pour créer automatiquement un utilisateur administrateur';

-- Exemple d'utilisation :
-- SELECT create_simple_admin_user('admin@example.com');
-- SELECT create_simple_admin_user('john.doe@example.com');
