-- Initialisation des données de base pour l'application
-- Script qui vérifie l'existence des tables ET des colonnes avant insertion

-- 1. Récupérer l'ID de l'utilisateur admin et créer des paramètres système
DO $$
DECLARE
    admin_user_id UUID;
    table_exists BOOLEAN;
    column_exists BOOLEAN;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    -- Si aucun admin n'existe, créer un utilisateur par défaut
    IF admin_user_id IS NULL THEN
        INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
        VALUES (gen_random_uuid(), 'Admin', 'Système', 'admin@atelier.com', 'admin', NOW(), NOW())
        RETURNING id INTO admin_user_id;
    END IF;
    
    -- Vérifier si la table system_settings existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'system_settings'
    ) INTO table_exists;
    
    -- Créer des paramètres système si la table existe
    IF table_exists THEN
        -- Vérifier si la colonne user_id existe
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id'
        ) INTO column_exists;
        
        IF column_exists THEN
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
        ELSE
            INSERT INTO system_settings (key, value, description, category, created_at, updated_at)
            VALUES 
              ('workshop_name', 'Atelier de Réparation', 'Nom de l''atelier', 'general', NOW(), NOW()),
              ('workshop_address', '123 Rue de la Réparation', 'Adresse de l''atelier', 'general', NOW(), NOW()),
              ('workshop_phone', '+33 1 23 45 67 89', 'Téléphone de l''atelier', 'general', NOW(), NOW()),
              ('workshop_email', 'contact@atelier.com', 'Email de l''atelier', 'general', NOW(), NOW()),
              ('default_repair_duration', '60', 'Durée par défaut des réparations (minutes)', 'repairs', NOW(), NOW()),
              ('low_stock_threshold', '5', 'Seuil d''alerte de stock faible', 'inventory', NOW(), NOW()),
              ('auto_create_users', 'true', 'Création automatique d''utilisateurs', 'security', NOW(), NOW()),
              ('max_appointments_per_day', '20', 'Nombre maximum de rendez-vous par jour', 'appointments', NOW(), NOW()),
              ('appointment_reminder_hours', '24', 'Rappel de rendez-vous (heures avant)', 'appointments', NOW(), NOW()),
              ('default_currency', 'EUR', 'Devise par défaut', 'general', NOW(), NOW()),
              ('tax_rate', '20', 'Taux de TVA (%)', 'financial', NOW(), NOW()),
              ('invoice_prefix', 'REP', 'Préfixe des factures', 'financial', NOW(), NOW()),
              ('enable_sms_notifications', 'false', 'Activer les notifications SMS', 'notifications', NOW(), NOW()),
              ('enable_email_notifications', 'true', 'Activer les notifications email', 'notifications', NOW(), NOW()),
              ('backup_frequency', 'daily', 'Fréquence de sauvegarde', 'system', NOW(), NOW());
        END IF;
        
        RAISE NOTICE 'Paramètres système créés avec succès';
    ELSE
        RAISE NOTICE 'Table system_settings n''existe pas, ignorée';
    END IF;
END $$;

-- 2. Créer des services de base (si la table existe)
DO $$
DECLARE
    admin_user_id UUID;
    table_exists BOOLEAN;
    user_id_exists BOOLEAN;
    duration_exists BOOLEAN;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    -- Vérifier si la table services existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'services'
    ) INTO table_exists;
    
    -- Créer des services si la table existe
    IF table_exists THEN
        -- Vérifier si la colonne user_id existe
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'user_id'
        ) INTO user_id_exists;
        
        -- Vérifier si la colonne duration_minutes existe
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'duration_minutes'
        ) INTO duration_exists;
        
        IF user_id_exists AND duration_exists THEN
            INSERT INTO services (id, user_id, name, description, price, duration_minutes, created_at, updated_at)
            VALUES 
              (gen_random_uuid(), admin_user_id, 'Diagnostic', 'Diagnostic complet de l''appareil', 25.00, 30, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Nettoyage', 'Nettoyage complet de l''appareil', 15.00, 20, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Remplacement écran', 'Remplacement d''écran cassé', 80.00, 60, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Remplacement batterie', 'Remplacement de batterie', 45.00, 45, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Réparation logicielle', 'Réparation de problèmes logiciels', 35.00, 40, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Récupération données', 'Récupération de données perdues', 50.00, 90, NOW(), NOW());
        ELSIF user_id_exists THEN
            INSERT INTO services (id, user_id, name, description, price, created_at, updated_at)
            VALUES 
              (gen_random_uuid(), admin_user_id, 'Diagnostic', 'Diagnostic complet de l''appareil', 25.00, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Nettoyage', 'Nettoyage complet de l''appareil', 15.00, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Remplacement écran', 'Remplacement d''écran cassé', 80.00, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Remplacement batterie', 'Remplacement de batterie', 45.00, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Réparation logicielle', 'Réparation de problèmes logiciels', 35.00, NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Récupération données', 'Récupération de données perdues', 50.00, NOW(), NOW());
        ELSE
            INSERT INTO services (id, name, description, price, created_at, updated_at)
            VALUES 
              (gen_random_uuid(), 'Diagnostic', 'Diagnostic complet de l''appareil', 25.00, NOW(), NOW()),
              (gen_random_uuid(), 'Nettoyage', 'Nettoyage complet de l''appareil', 15.00, NOW(), NOW()),
              (gen_random_uuid(), 'Remplacement écran', 'Remplacement d''écran cassé', 80.00, NOW(), NOW()),
              (gen_random_uuid(), 'Remplacement batterie', 'Remplacement de batterie', 45.00, NOW(), NOW()),
              (gen_random_uuid(), 'Réparation logicielle', 'Réparation de problèmes logiciels', 35.00, NOW(), NOW()),
              (gen_random_uuid(), 'Récupération données', 'Récupération de données perdues', 50.00, NOW(), NOW());
        END IF;
        
        RAISE NOTICE 'Services créés avec succès';
    ELSE
        RAISE NOTICE 'Table services n''existe pas, ignorée';
    END IF;
END $$;

-- 3. Créer des modèles d'appareils de base (si la table existe)
DO $$
DECLARE
    admin_user_id UUID;
    table_exists BOOLEAN;
    user_id_exists BOOLEAN;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    -- Vérifier si la table device_models existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models'
    ) INTO table_exists;
    
    -- Créer des modèles si la table existe
    IF table_exists THEN
        -- Vérifier si la colonne user_id existe
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'user_id'
        ) INTO user_id_exists;
        
        IF user_id_exists THEN
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
        ELSE
            INSERT INTO device_models (id, name, brand, category, difficulty_level, estimated_repair_time, created_at, updated_at)
            VALUES 
              (gen_random_uuid(), 'iPhone 12', 'Apple', 'Smartphone', 'medium', 60, NOW(), NOW()),
              (gen_random_uuid(), 'iPhone 13', 'Apple', 'Smartphone', 'medium', 60, NOW(), NOW()),
              (gen_random_uuid(), 'iPhone 14', 'Apple', 'Smartphone', 'medium', 60, NOW(), NOW()),
              (gen_random_uuid(), 'Samsung Galaxy S21', 'Samsung', 'Smartphone', 'medium', 60, NOW(), NOW()),
              (gen_random_uuid(), 'Samsung Galaxy S22', 'Samsung', 'Smartphone', 'medium', 60, NOW(), NOW()),
              (gen_random_uuid(), 'MacBook Air M1', 'Apple', 'Ordinateur portable', 'hard', 120, NOW(), NOW()),
              (gen_random_uuid(), 'MacBook Pro M2', 'Apple', 'Ordinateur portable', 'hard', 120, NOW(), NOW()),
              (gen_random_uuid(), 'Dell XPS 13', 'Dell', 'Ordinateur portable', 'hard', 120, NOW(), NOW()),
              (gen_random_uuid(), 'iPad Air', 'Apple', 'Tablette', 'medium', 45, NOW(), NOW()),
              (gen_random_uuid(), 'iPad Pro', 'Apple', 'Tablette', 'medium', 45, NOW(), NOW());
        END IF;
        
        RAISE NOTICE 'Modèles d''appareils créés avec succès';
    ELSE
        RAISE NOTICE 'Table device_models n''existe pas, ignorée';
    END IF;
END $$;

-- 4. Créer des produits de base (si la table existe)
DO $$
DECLARE
    admin_user_id UUID;
    table_exists BOOLEAN;
    user_id_exists BOOLEAN;
    min_stock_exists BOOLEAN;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    -- Vérifier si la table products existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'products'
    ) INTO table_exists;
    
    -- Créer des produits si la table existe
    IF table_exists THEN
        -- Vérifier si la colonne user_id existe
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'user_id'
        ) INTO user_id_exists;
        
        -- Vérifier si la colonne min_stock_level existe
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'min_stock_level'
        ) INTO min_stock_exists;
        
        IF user_id_exists AND min_stock_exists THEN
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
        ELSIF user_id_exists THEN
            INSERT INTO products (id, user_id, name, description, price, stock_quantity, category, created_at, updated_at)
            VALUES 
              (gen_random_uuid(), admin_user_id, 'Écran iPhone 12', 'Écran de remplacement pour iPhone 12', 120.00, 10, 'Écrans', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Écran iPhone 13', 'Écran de remplacement pour iPhone 13', 130.00, 8, 'Écrans', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Batterie iPhone 12', 'Batterie de remplacement pour iPhone 12', 45.00, 15, 'Batteries', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Batterie iPhone 13', 'Batterie de remplacement pour iPhone 13', 50.00, 12, 'Batteries', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Câble Lightning', 'Câble Lightning original Apple', 15.00, 25, 'Câbles', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Chargeur USB-C', 'Chargeur USB-C 20W', 20.00, 20, 'Chargeurs', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Coque iPhone 12', 'Coque de protection iPhone 12', 25.00, 30, 'Protection', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Coque iPhone 13', 'Coque de protection iPhone 13', 25.00, 28, 'Protection', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Kit de réparation', 'Kit complet de réparation', 35.00, 15, 'Outils', NOW(), NOW()),
              (gen_random_uuid(), admin_user_id, 'Pâte thermique', 'Pâte thermique pour ordinateurs', 8.00, 40, 'Outils', NOW(), NOW());
        ELSE
            INSERT INTO products (id, name, description, price, stock_quantity, category, created_at, updated_at)
            VALUES 
              (gen_random_uuid(), 'Écran iPhone 12', 'Écran de remplacement pour iPhone 12', 120.00, 10, 'Écrans', NOW(), NOW()),
              (gen_random_uuid(), 'Écran iPhone 13', 'Écran de remplacement pour iPhone 13', 130.00, 8, 'Écrans', NOW(), NOW()),
              (gen_random_uuid(), 'Batterie iPhone 12', 'Batterie de remplacement pour iPhone 12', 45.00, 15, 'Batteries', NOW(), NOW()),
              (gen_random_uuid(), 'Batterie iPhone 13', 'Batterie de remplacement pour iPhone 13', 50.00, 12, 'Batteries', NOW(), NOW()),
              (gen_random_uuid(), 'Câble Lightning', 'Câble Lightning original Apple', 15.00, 25, 'Câbles', NOW(), NOW()),
              (gen_random_uuid(), 'Chargeur USB-C', 'Chargeur USB-C 20W', 20.00, 20, 'Chargeurs', NOW(), NOW()),
              (gen_random_uuid(), 'Coque iPhone 12', 'Coque de protection iPhone 12', 25.00, 30, 'Protection', NOW(), NOW()),
              (gen_random_uuid(), 'Coque iPhone 13', 'Coque de protection iPhone 13', 25.00, 28, 'Protection', NOW(), NOW()),
              (gen_random_uuid(), 'Kit de réparation', 'Kit complet de réparation', 35.00, 15, 'Outils', NOW(), NOW()),
              (gen_random_uuid(), 'Pâte thermique', 'Pâte thermique pour ordinateurs', 8.00, 40, 'Outils', NOW(), NOW());
        END IF;
        
        RAISE NOTICE 'Produits créés avec succès';
    ELSE
        RAISE NOTICE 'Table products n''existe pas, ignorée';
    END IF;
END $$;

-- 5. Afficher les statistiques des tables existantes
SELECT 'Statistiques des tables existantes:' as info;

-- Vérifier et compter les utilisateurs
SELECT 
  'Utilisateurs' as table_name,
  COUNT(*) as count
FROM users
UNION ALL
-- Vérifier et compter les paramètres système
SELECT 
  'Paramètres système' as table_name,
  COUNT(*) as count
FROM system_settings
UNION ALL
-- Vérifier et compter les services
SELECT 
  'Services' as table_name,
  COUNT(*) as count
FROM services
UNION ALL
-- Vérifier et compter les modèles d'appareils
SELECT 
  'Modèles d''appareils' as table_name,
  COUNT(*) as count
FROM device_models
UNION ALL
-- Vérifier et compter les produits
SELECT 
  'Produits' as table_name,
  COUNT(*) as count
FROM products;

SELECT 'Initialisation ultime terminée avec succès !' as status;
