-- Script pour créer une fonction RPC permettant de créer automatiquement un utilisateur administrateur
-- Cette fonction sera utilisée par la page Administration

-- Fonction pour créer un utilisateur administrateur automatiquement
CREATE OR REPLACE FUNCTION create_admin_user_auto(
  p_email TEXT,
  p_first_name TEXT DEFAULT NULL,
  p_last_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_created_user RECORD;
  v_result JSON;
BEGIN
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
    
    -- Récupérer les données mises à jour
    SELECT * INTO v_created_user
    FROM users
    WHERE id = v_user_id;
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur promu administrateur avec succès',
      'data', row_to_json(v_created_user)
    );
  ELSE
    -- Créer un nouvel utilisateur administrateur
    v_user_id := gen_random_uuid();
    
    -- Extraire le prénom et nom de l'email si pas fournis
    IF p_first_name IS NULL OR p_last_name IS NULL THEN
      DECLARE
        v_email_parts TEXT[];
        v_name_parts TEXT[];
      BEGIN
        v_email_parts := string_to_array(p_email, '@');
        v_name_parts := string_to_array(v_email_parts[1], '.');
        
        IF p_first_name IS NULL THEN
          IF array_length(v_name_parts, 1) >= 2 THEN
            p_first_name := initcap(v_name_parts[1]);
          ELSE
            p_first_name := initcap(v_email_parts[1]);
          END IF;
        END IF;
        
        IF p_last_name IS NULL THEN
          IF array_length(v_name_parts, 1) >= 2 THEN
            p_last_name := initcap(v_name_parts[2]);
          ELSE
            p_last_name := 'Administrateur';
          END IF;
        END IF;
      END;
    END IF;
    
    -- Insérer le nouvel utilisateur
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
      p_first_name,
      p_last_name,
      p_email,
      'admin',
      NOW(),
      NOW()
    );
    
    -- Récupérer les données créées
    SELECT * INTO v_created_user
    FROM users
    WHERE id = v_user_id;
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur administrateur créé avec succès',
      'data', row_to_json(v_created_user)
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
GRANT EXECUTE ON FUNCTION create_admin_user_auto(TEXT, TEXT, TEXT) TO authenticated;

-- Commentaire sur la fonction
COMMENT ON FUNCTION create_admin_user_auto(TEXT, TEXT, TEXT) IS 
'Fonction pour créer automatiquement un utilisateur administrateur ou promouvoir un utilisateur existant au rôle admin';

-- Exemple d'utilisation :
-- SELECT create_admin_user_auto('admin@example.com', 'John', 'Doe');
-- SELECT create_admin_user_auto('admin@example.com'); -- Extraction automatique du nom depuis l'email
