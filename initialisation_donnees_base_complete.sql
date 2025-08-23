-- Initialisation des données de base pour l'application
-- Script qui vérifie TOUTES les colonnes requises avant insertion

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

-- 3. Afficher les statistiques des tables existantes
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
FROM services;

SELECT 'Initialisation complète terminée avec succès !' as status;
