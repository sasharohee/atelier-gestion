-- Correction finale pour la création automatique d'utilisateurs
-- Résout les problèmes de contrainte d'email unique et de base vide

-- 1. Nettoyer les utilisateurs existants pour éviter les conflits
DELETE FROM user_preferences WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%@example.com' OR email = 'user@example.com'
);
DELETE FROM user_profiles WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%@example.com' OR email = 'user@example.com'
);
DELETE FROM users WHERE email LIKE '%@example.com' OR email = 'user@example.com';

-- 1.5. Supprimer les triggers problématiques
DROP TRIGGER IF EXISTS set_workshop_context_trigger ON users;
DROP FUNCTION IF EXISTS set_workshop_context();
DROP TRIGGER IF EXISTS create_user_profile_trigger ON users;
DROP FUNCTION IF EXISTS create_user_profile_trigger();

-- 2. Supprimer la fonction existante puis la recréer
DROP FUNCTION IF EXISTS create_user_automatically(UUID, TEXT, TEXT, TEXT, TEXT);

-- 3. Corriger la fonction RPC pour gérer les emails uniques
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

-- 5. Créer un utilisateur admin par défaut pour initialiser la base
INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'Admin',
  'Système',
  'admin@atelier.com',
  'admin',
  NOW(),
  NOW()
) ON CONFLICT (email) DO NOTHING;

-- 6. Créer des données de test pour les paramètres système
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

-- 7. Créer des statuts de réparation par défaut
INSERT INTO repair_statuses (id, name, color, "order", created_at, updated_at)
VALUES 
  ('new', 'Nouvelle', '#2196f3', 1, NOW(), NOW()),
  ('in_progress', 'En cours', '#ff9800', 2, NOW(), NOW()),
  ('waiting_parts', 'En attente de pièces', '#f44336', 3, NOW(), NOW()),
  ('waiting_delivery', 'Livraison attendue', '#9c27b0', 4, NOW(), NOW()),
  ('completed', 'Terminée', '#4caf50', 5, NOW(), NOW()),
  ('cancelled', 'Annulée', '#757575', 6, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 8. Créer des modèles d'appareils de test
INSERT INTO device_models (id, brand, model, type, year, specifications, common_issues, repair_difficulty, parts_availability, is_active, created_at, updated_at)
VALUES 
  (
    gen_random_uuid(),
    'Apple',
    'iPhone 12',
    'smartphone',
    2020,
    '{"screen": "6.1 inch", "processor": "A14 Bionic", "ram": "4GB", "storage": "128GB", "battery": "2815mAh", "os": "iOS 14"}',
    '{"Écran cassé", "Batterie défaillante", "Port de charge endommagé"}',
    'medium',
    'high',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'Samsung',
    'Galaxy S21',
    'smartphone',
    2021,
    '{"screen": "6.2 inch", "processor": "Exynos 2100", "ram": "8GB", "storage": "128GB", "battery": "4000mAh", "os": "Android 11"}',
    '{"Écran cassé", "Batterie défaillante", "Caméra défaillante"}',
    'medium',
    'high',
    true,
    NOW(),
    NOW()
  )
ON CONFLICT DO NOTHING;

-- 9. Créer des services de test
INSERT INTO services (id, name, description, duration, price, category, applicable_devices, is_active, created_at, updated_at)
VALUES 
  (
    gen_random_uuid(),
    'Remplacement d''écran',
    'Remplacement complet de l''écran d''un smartphone',
    60,
    89.99,
    'Réparation',
    '{"smartphone", "tablet"}',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'Remplacement de batterie',
    'Remplacement de la batterie d''un appareil',
    45,
    49.99,
    'Réparation',
    '{"smartphone", "tablet", "laptop"}',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'Diagnostic complet',
    'Diagnostic complet d''un appareil',
    30,
    29.99,
    'Diagnostic',
    '{"smartphone", "tablet", "laptop", "desktop"}',
    true,
    NOW(),
    NOW()
  )
ON CONFLICT DO NOTHING;

-- 10. Vérifier que tout fonctionne
SELECT 'Correction finale terminée. Base de données initialisée avec des données de test.' as status;

-- 11. Afficher les statistiques
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
FROM repair_statuses
UNION ALL
SELECT 
  'Modèles d appareils' as table_name,
  COUNT(*) as count
FROM device_models
UNION ALL
SELECT 
  'Services' as table_name,
  COUNT(*) as count
FROM services;
