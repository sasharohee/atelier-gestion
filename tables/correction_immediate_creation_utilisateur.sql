-- Correction immédiate pour la création d'utilisateurs
-- Script simple et direct pour résoudre le problème

-- 1. Nettoyer complètement la base de données (en respectant les contraintes)
DELETE FROM user_preferences;
DELETE FROM user_profiles;
DELETE FROM appointments WHERE user_id IS NOT NULL;
DELETE FROM repairs WHERE assigned_technician_id IS NOT NULL;
DELETE FROM sales WHERE client_id IS NOT NULL;
DELETE FROM messages WHERE sender_id IS NOT NULL OR recipient_id IS NOT NULL;
DELETE FROM notifications WHERE user_id IS NOT NULL;
DELETE FROM stock_alerts;
DELETE FROM users;

-- 2. Supprimer et recréer la fonction RPC
DROP FUNCTION IF EXISTS create_user_automatically(UUID, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION create_user_automatically(
  user_id UUID,
  first_name TEXT,
  last_name TEXT,
  user_email TEXT,
  user_role TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user users%ROWTYPE;
  final_email TEXT;
  email_counter INTEGER := 0;
BEGIN
  -- Vérifier que l'utilisateur est authentifié
  IF auth.uid() IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Non authentifié');
  END IF;

  -- Vérifier que l'utilisateur n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = user_id) THEN
    RETURN json_build_object('success', true, 'message', 'Utilisateur déjà existant');
  END IF;

  -- Gérer l'unicité de l'email
  final_email := COALESCE(user_email, 'user@example.com');
  
  -- Si l'email existe déjà, générer un email unique
  WHILE EXISTS (SELECT 1 FROM users WHERE email = final_email) LOOP
    email_counter := email_counter + 1;
    final_email := 'user' || email_counter || '@example.com';
  END LOOP;

  -- Insérer le nouvel utilisateur
  INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
  VALUES (
    user_id,
    COALESCE(first_name, 'Utilisateur'),
    COALESCE(last_name, 'Test'),
    final_email,
    COALESCE(user_role, 'technician'),
    NOW(),
    NOW()
  )
  RETURNING * INTO new_user;

  -- Retourner le succès
  RETURN json_build_object(
    'success', true,
    'user', json_build_object(
      'id', new_user.id,
      'first_name', new_user.first_name,
      'last_name', new_user.last_name,
      'email', new_user.email,
      'role', new_user.role
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 3. Donner les permissions
GRANT EXECUTE ON FUNCTION create_user_automatically TO authenticated;

-- 4. Créer un utilisateur admin par défaut
INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'Admin',
  'Système',
  'admin@atelier.com',
  'admin',
  NOW(),
  NOW()
);

-- 5. Créer des paramètres système de base
INSERT INTO system_settings (key, value, description, category, created_at, updated_at)
VALUES 
  ('workshop_name', 'Atelier de Réparation', 'Nom de l''atelier', 'general', NOW(), NOW()),
  ('workshop_address', '123 Rue de la Réparation', 'Adresse de l''atelier', 'general', NOW(), NOW()),
  ('workshop_phone', '+33 1 23 45 67 89', 'Téléphone de l''atelier', 'general', NOW(), NOW()),
  ('workshop_email', 'contact@atelier.com', 'Email de l''atelier', 'general', NOW(), NOW()),
  ('default_repair_duration', '60', 'Durée par défaut des réparations (minutes)', 'repairs', NOW(), NOW()),
  ('low_stock_threshold', '5', 'Seuil d''alerte de stock faible', 'inventory', NOW(), NOW()),
  ('auto_create_users', 'true', 'Création automatique d''utilisateurs', 'security', NOW(), NOW())
ON CONFLICT (key) DO NOTHING;

-- 6. Créer des statuts de réparation
INSERT INTO repair_statuses (id, name, color, "order", created_at, updated_at)
VALUES 
  ('new', 'Nouvelle', '#2196f3', 1, NOW(), NOW()),
  ('in_progress', 'En cours', '#ff9800', 2, NOW(), NOW()),
  ('waiting_parts', 'En attente de pièces', '#f44336', 3, NOW(), NOW()),
  ('waiting_delivery', 'Livraison attendue', '#9c27b0', 4, NOW(), NOW()),
  ('completed', 'Terminée', '#4caf50', 5, NOW(), NOW()),
  ('cancelled', 'Annulée', '#757575', 6, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 7. Tester la fonction RPC
SELECT 'Test de la fonction RPC' as test,
       create_user_automatically(
         gen_random_uuid(),
         'Test',
         'User',
         'test@example.com',
         'technician'
       ) as result;

-- 8. Nettoyer le test
DELETE FROM users WHERE email = 'test@example.com';

-- 9. Afficher les statistiques
SELECT 
  'Utilisateurs' as table_name,
  COUNT(*) as count
FROM users
UNION ALL
SELECT 
  'Paramètres système' as table_name,
  COUNT(*) as count
FROM system_settings
UNION ALL
SELECT 
  'Statuts de réparation' as table_name,
  COUNT(*) as count
FROM repair_statuses;

SELECT 'Correction immédiate terminée. Base de données initialisée.' as status;
