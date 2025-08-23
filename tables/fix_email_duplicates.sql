-- Script pour nettoyer les doublons d'email et améliorer la gestion des contraintes

-- 1. Identifier les doublons d'email
SELECT 
    email,
    COUNT(*) as count,
    array_agg(id) as user_ids
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- 2. Supprimer les doublons (garder le plus récent)
DELETE FROM users 
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) as rn
        FROM users
    ) t
    WHERE t.rn > 1
);

-- 3. Vérifier qu'il n'y a plus de doublons
SELECT 
    email,
    COUNT(*) as count
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- 4. Ajouter un index unique sur email (si pas déjà présent)
CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users(email);

-- 5. Fonction pour vérifier si un email existe déjà
CREATE OR REPLACE FUNCTION check_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM users WHERE email = p_email
    ) INTO v_exists;
    
    RETURN v_exists;
END;
$$;

-- 6. Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION check_email_exists(TEXT) TO authenticated;

-- 7. Fonction pour créer un utilisateur avec vérification d'email
CREATE OR REPLACE FUNCTION create_user_with_email_check(
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
      'error', 'Utilisateur non authentifié.'
    );
  END IF;

  -- Vérifier si l'email existe déjà
  IF check_email_exists(p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'L''email "' || p_email || '" est déjà utilisé par un autre utilisateur.'
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

-- 8. Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_with_email_check(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
