-- Initialisation des données de base pour l'application
-- Script à exécuter après correction_ultime_simple.sql

-- 1. Récupérer l'ID de l'utilisateur admin
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    -- Si aucun admin n'existe, créer un utilisateur par défaut
    IF admin_user_id IS NULL THEN
        INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
        VALUES (gen_random_uuid(), 'Admin', 'Système', 'admin@atelier.com', 'admin', NOW(), NOW())
        RETURNING id INTO admin_user_id;
    END IF;
    
    -- Créer des paramètres système de base avec l'ID utilisateur
    INSERT INTO system_settings (user_id, key, value, description, category, created_at, updated_at)
    VALUES 
      (admin_user_id, 'workshop_name', 'Atelier de Réparation', 'Nom de l''atelier', 'general', NOW(), NOW()),
      (admin_user_id, 'workshop_address', '123 Rue de la Réparation', 'Adresse de l''atelier', 'general', NOW(), NOW()),
      (admin_user_id, 'workshop_phone', '+33 1 23 45 67 89', 'Téléphone de l''atelier', 'general', NOW(), NOW()),
      (admin_user_id, 'workshop_email', 'contact@atelier.com', 'Email de l''atelier', 'general', NOW(), NOW()),
      (admin_user_id, 'default_repair_duration', '60', 'Durée par défaut des réparations (minutes)', 'repairs', NOW(), NOW()),
      (admin_user_id, 'low_stock_threshold', '5', 'Seuil d''alerte de stock faible', 'inventory', NOW(), NOW()),
      (admin_user_id, 'auto_create_users', 'true', 'Création automatique d''utilisateurs', 'security', NOW(), NOW()),
      (admin_user_id, 'max_appointments_per_day', '20', 'Nombre maximum de rendez-vous par jour', 'appointments', NOW(), NOW()),
      (admin_user_id, 'appointment_reminder_hours', '24', 'Rappel de rendez-vous (heures avant)', 'appointments', NOW(), NOW()),
      (admin_user_id, 'default_currency', 'EUR', 'Devise par défaut', 'general', NOW(), NOW()),
      (admin_user_id, 'tax_rate', '20', 'Taux de TVA (%)', 'financial', NOW(), NOW()),
      (admin_user_id, 'invoice_prefix', 'REP', 'Préfixe des factures', 'financial', NOW(), NOW()),
      (admin_user_id, 'enable_sms_notifications', 'false', 'Activer les notifications SMS', 'notifications', NOW(), NOW()),
      (admin_user_id, 'enable_email_notifications', 'true', 'Activer les notifications email', 'notifications', NOW(), NOW()),
      (admin_user_id, 'backup_frequency', 'daily', 'Fréquence de sauvegarde', 'system', NOW(), NOW());
END $$;

-- 2. Créer des statuts de réparation
INSERT INTO repair_statuses (id, name, color, "order", created_at, updated_at)
VALUES 
  ('new', 'Nouvelle', '#2196f3', 1, NOW(), NOW()),
  ('in_progress', 'En cours', '#ff9800', 2, NOW(), NOW()),
  ('waiting_parts', 'En attente de pièces', '#f44336', 3, NOW(), NOW()),
  ('waiting_delivery', 'Livraison attendue', '#9c27b0', 4, NOW(), NOW()),
  ('completed', 'Terminée', '#4caf50', 5, NOW(), NOW()),
  ('cancelled', 'Annulée', '#757575', 6, NOW(), NOW());

-- 3. Créer des services de base
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    INSERT INTO services (id, user_id, name, description, price, duration_minutes, created_at, updated_at)
    VALUES 
      (gen_random_uuid(), admin_user_id, 'Diagnostic', 'Diagnostic complet de l''appareil', 25.00, 30, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Nettoyage', 'Nettoyage complet de l''appareil', 15.00, 20, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Remplacement écran', 'Remplacement d''écran cassé', 80.00, 60, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Remplacement batterie', 'Remplacement de batterie', 45.00, 45, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Réparation logicielle', 'Réparation de problèmes logiciels', 35.00, 40, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Récupération données', 'Récupération de données perdues', 50.00, 90, NOW(), NOW());
END $$;

-- 4. Créer des modèles d'appareils de base
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    INSERT INTO device_models (id, user_id, name, brand, category, difficulty_level, estimated_repair_time, created_at, updated_at)
    VALUES 
      (gen_random_uuid(), admin_user_id, 'iPhone 12', 'Apple', 'Smartphone', 'medium', 60, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'iPhone 13', 'Apple', 'Smartphone', 'medium', 60, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'iPhone 14', 'Apple', 'Smartphone', 'medium', 60, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Samsung Galaxy S21', 'Samsung', 'Smartphone', 'medium', 60, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Samsung Galaxy S22', 'Samsung', 'Smartphone', 'medium', 60, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'MacBook Air M1', 'Apple', 'Ordinateur portable', 'hard', 120, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'MacBook Pro M2', 'Apple', 'Ordinateur portable', 'hard', 120, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Dell XPS 13', 'Dell', 'Ordinateur portable', 'hard', 120, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'iPad Air', 'Apple', 'Tablette', 'medium', 45, NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'iPad Pro', 'Apple', 'Tablette', 'medium', 45, NOW(), NOW());
END $$;

-- 5. Créer des produits de base
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    INSERT INTO products (id, user_id, name, description, price, stock_quantity, min_stock_level, category, created_at, updated_at)
    VALUES 
      (gen_random_uuid(), admin_user_id, 'Écran iPhone 12', 'Écran de remplacement pour iPhone 12', 120.00, 10, 3, 'Écrans', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Écran iPhone 13', 'Écran de remplacement pour iPhone 13', 130.00, 8, 3, 'Écrans', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Batterie iPhone 12', 'Batterie de remplacement pour iPhone 12', 45.00, 15, 5, 'Batteries', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Batterie iPhone 13', 'Batterie de remplacement pour iPhone 13', 50.00, 12, 5, 'Batteries', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Câble Lightning', 'Câble Lightning original Apple', 15.00, 25, 10, 'Câbles', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Chargeur USB-C', 'Chargeur USB-C 20W', 20.00, 20, 8, 'Chargeurs', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Coque iPhone 12', 'Coque de protection iPhone 12', 25.00, 30, 10, 'Protection', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Coque iPhone 13', 'Coque de protection iPhone 13', 25.00, 28, 10, 'Protection', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Kit de réparation', 'Kit complet de réparation', 35.00, 15, 5, 'Outils', NOW(), NOW()),
      (gen_random_uuid(), admin_user_id, 'Pâte thermique', 'Pâte thermique pour ordinateurs', 8.00, 40, 15, 'Outils', NOW(), NOW());
END $$;

-- 6. Afficher les statistiques
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
  'Services' as table_name,
  COUNT(*) as count
FROM services
UNION ALL
SELECT 
  'Modèles d''appareils' as table_name,
  COUNT(*) as count
FROM device_models
UNION ALL
SELECT 
  'Produits' as table_name,
  COUNT(*) as count
FROM products;

SELECT 'Données de base initialisées avec succès !' as status;
