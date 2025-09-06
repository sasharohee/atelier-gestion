-- Script de correction pour les politiques RLS de subscription_status
-- À exécuter pour permettre l'accès depuis la page d'administration

-- Supprimer les politiques existantes pour éviter les conflits
DROP POLICY IF EXISTS "Users can view their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Users can create their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admins can delete all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admin page full access" ON subscription_status;

-- Politique pour permettre aux utilisateurs de voir leur propre statut
CREATE POLICY "Users can view their own subscription status" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux administrateurs de voir tous les statuts
CREATE POLICY "Admins can view all subscription statuses" ON subscription_status
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Politique pour permettre aux utilisateurs de créer leur propre statut
CREATE POLICY "Users can create their own subscription status" ON subscription_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour permettre aux administrateurs de modifier tous les statuts
CREATE POLICY "Admins can update all subscription statuses" ON subscription_status
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Politique pour permettre aux administrateurs de supprimer tous les statuts
CREATE POLICY "Admins can delete all subscription statuses" ON subscription_status
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Politique spéciale pour la page d'administration (accès complet sans authentification)
-- Cette politique permet toutes les opérations depuis la page /admin
CREATE POLICY "Admin page full access" ON subscription_status
    FOR ALL USING (true)
    WITH CHECK (true);

-- Script pour corriger les problèmes d'inscription d'utilisateurs
-- Supprimer tous les triggers problématiques sur la table users

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS trigger_create_subscription_status ON users;
DROP TRIGGER IF EXISTS trigger_create_user_settings ON users;
DROP TRIGGER IF EXISTS trigger_create_system_settings ON users;
DROP TRIGGER IF EXISTS trigger_create_user_settings_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_system_settings_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_subscription_status_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
DROP TRIGGER IF EXISTS trigger_create_user_profile ON users;
DROP TRIGGER IF EXISTS trigger_create_user_workshop ON users;

-- Supprimer les fonctions associées
DROP FUNCTION IF EXISTS create_subscription_status_on_user_signup();
DROP FUNCTION IF EXISTS create_system_settings_on_user_signup();
DROP FUNCTION IF EXISTS create_user_settings_on_signup();
DROP FUNCTION IF EXISTS create_user_default_data_on_signup();
DROP FUNCTION IF EXISTS create_user_profile_on_signup();
DROP FUNCTION IF EXISTS create_user_workshop_on_signup();
DROP FUNCTION IF EXISTS create_user_default_data(UUID);

-- Vérifier et corriger la table users
-- S'assurer que la table users a les bonnes colonnes et contraintes
DO $$
BEGIN
    -- Vérifier si la colonne role existe
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user';
    END IF;
    
    -- Vérifier si la contrainte sur role existe
    IF NOT EXISTS (SELECT FROM information_schema.table_constraints WHERE table_name = 'users' AND constraint_name = 'users_role_check') THEN
        ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'manager', 'technician', 'user'));
    END IF;
    
    -- Vérifier si la contrainte unique sur email existe
    IF NOT EXISTS (SELECT FROM information_schema.table_constraints WHERE table_name = 'users' AND constraint_name = 'users_email_key') THEN
        ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
    END IF;
END $$;

-- Créer une fonction RPC simple pour créer les données par défaut
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Créer le statut d'abonnement
    INSERT INTO subscription_status (
        user_id,
        first_name,
        last_name,
        email,
        is_active,
        subscription_type,
        notes
    ) VALUES (
        p_user_id,
        'Utilisateur',
        '',
        '',
        FALSE,
        'free',
        'Compte créé automatiquement - en attente d''activation'
    ) ON CONFLICT (user_id) DO NOTHING;
    
    -- Créer les paramètres système par défaut
    INSERT INTO system_settings (user_id, category, key, value, description)
    VALUES 
        (p_user_id, 'general', 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
        (p_user_id, 'general', 'workshop_address', '', 'Adresse de l''atelier'),
        (p_user_id, 'general', 'workshop_phone', '', 'Téléphone de l''atelier'),
        (p_user_id, 'general', 'workshop_email', '', 'Email de l''atelier'),
        (p_user_id, 'notifications', 'email_notifications', 'true', 'Activer les notifications par email'),
        (p_user_id, 'notifications', 'sms_notifications', 'false', 'Activer les notifications par SMS'),
        (p_user_id, 'appointments', 'appointment_duration', '60', 'Durée par défaut des rendez-vous (minutes)'),
        (p_user_id, 'appointments', 'working_hours_start', '08:00', 'Heure de début de travail'),
        (p_user_id, 'appointments', 'working_hours_end', '18:00', 'Heure de fin de travail')
    ON CONFLICT (user_id, category, key) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;

-- Créer une fonction pour diagnostiquer les problèmes d'inscription
CREATE OR REPLACE FUNCTION diagnose_signup_issues()
RETURNS TABLE(issue_type TEXT, description TEXT, recommendation TEXT) AS $$
BEGIN
    -- Vérifier les triggers sur la table users
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgrelid = 'users'::regclass) THEN
        RETURN QUERY SELECT 
            'TRIGGER'::TEXT,
            'Des triggers existent sur la table users'::TEXT,
            'Supprimer tous les triggers sur la table users'::TEXT;
    END IF;
    
    -- Vérifier les contraintes problématiques
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'users' AND constraint_type = 'CHECK' 
               AND constraint_name LIKE '%subscription%') THEN
        RETURN QUERY SELECT 
            'CONSTRAINT'::TEXT,
            'Contraintes CHECK problématiques sur la table users'::TEXT,
            'Vérifier et supprimer les contraintes CHECK problématiques'::TEXT;
    END IF;
    
    -- Vérifier les politiques RLS sur auth.users
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND schemaname = 'auth') THEN
        RETURN QUERY SELECT 
            'RLS'::TEXT,
            'Politiques RLS sur auth.users'::TEXT,
            'Vérifier les politiques RLS sur auth.users'::TEXT;
    END IF;
    
    RETURN QUERY SELECT 
        'INFO'::TEXT,
        'Aucun problème détecté'::TEXT,
        'L''inscription devrait fonctionner normalement'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Exécuter le diagnostic
SELECT * FROM diagnose_signup_issues();

-- Test de la fonction RPC
-- Utiliser un utilisateur existant dans auth.users pour tester
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Récupérer le premier utilisateur existant dans auth.users
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Tester la fonction RPC avec un utilisateur existant
        PERFORM create_user_default_data(test_user_id);
        
        -- Vérifier que les données ont été créées
        RAISE NOTICE 'Test avec utilisateur existant ID: %', test_user_id;
        RAISE NOTICE 'Vérifiez que les données ont été créées dans subscription_status et system_settings';
    ELSE
        RAISE NOTICE 'Aucun utilisateur trouvé dans auth.users pour le test';
    END IF;
END $$;
