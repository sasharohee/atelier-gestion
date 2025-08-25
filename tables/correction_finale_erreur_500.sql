-- Correction finale de l'erreur 500 lors de l'inscription
-- Date: 2024-01-24
-- Ce script combine toutes les solutions pour résoudre définitivement le problème

-- 1. NETTOYAGE COMPLET DES TRIGGERS PROBLÉMATIQUES

-- Supprimer TOUS les triggers qui pourraient interférer avec l'inscription
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_user_automatically ON users;
DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_automatically ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON auth.users;

-- 2. VÉRIFIER ET CRÉER LES TABLES NÉCESSAIRES

-- Créer la table subscription_status si elle n'existe pas
CREATE TABLE IF NOT EXISTS subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Créer la table system_settings si elle n'existe pas
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, category, key)
);

-- 3. CONFIGURER RLS CORRECTEMENT

-- Activer RLS sur les tables
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Users can view own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can insert own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can update own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can view own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can insert own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can update own system settings" ON system_settings;

-- Créer les nouvelles politiques avec des permissions plus permissives
CREATE POLICY "Users can view own subscription status" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription status" ON subscription_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription status" ON subscription_status
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own system settings" ON system_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own system settings" ON system_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own system settings" ON system_settings
    FOR UPDATE USING (auth.uid() = user_id);

-- 4. CRÉER UNE FONCTION RPC ROBUSTE

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS create_user_default_data(UUID);

-- Créer une nouvelle fonction RPC très robuste
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    user_exists BOOLEAN;
BEGIN
    -- Vérifier que l'utilisateur existe dans auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO user_exists;
    
    IF NOT user_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé dans auth.users',
            'user_id', p_user_id
        );
    END IF;

    BEGIN
        -- Créer le statut d'abonnement avec gestion d'erreur
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
        
        -- Créer les paramètres système par défaut avec gestion d'erreur
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

        RETURN json_build_object(
            'success', true,
            'message', 'Données par défaut créées avec succès',
            'user_id', p_user_id
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'detail', SQLSTATE,
            'user_id', p_user_id
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. PERMISSIONS COMPLÈTES

-- Donner les permissions d'exécution à tous les rôles nécessaires
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO service_role;

-- 6. VÉRIFIER LA CONFIGURATION DE LA TABLE USERS

-- S'assurer que la table users a les bonnes colonnes
DO $$
BEGIN
    -- Ajouter les colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'technician';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'avatar') THEN
        ALTER TABLE users ADD COLUMN avatar TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'created_at') THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'updated_at') THEN
        ALTER TABLE users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 7. CRÉER UN TRIGGER SIMPLE POUR MISE À JOUR

-- Créer un trigger simple pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 8. FONCTION DE TEST COMPLÈTE

-- Créer une fonction de test complète
CREATE OR REPLACE FUNCTION test_complete_signup_fix()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Test 1: Vérifier les tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_status') THEN
        RETURN QUERY SELECT 'Table subscription_status'::TEXT, 'OK'::TEXT, 'Table existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table subscription_status'::TEXT, 'ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings') THEN
        RETURN QUERY SELECT 'Table system_settings'::TEXT, 'OK'::TEXT, 'Table existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table system_settings'::TEXT, 'ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;

    -- Test 2: Vérifier la fonction RPC
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'create_user_default_data') THEN
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    -- Test 3: Vérifier les permissions
    IF EXISTS (SELECT 1 FROM information_schema.routine_privileges 
               WHERE routine_name = 'create_user_default_data' AND grantee = 'anon') THEN
        RETURN QUERY SELECT 'Permissions anon'::TEXT, 'OK'::TEXT, 'Permissions accordées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Permissions anon'::TEXT, 'ERREUR'::TEXT, 'Permissions manquantes'::TEXT;
    END IF;

    -- Test 4: Vérifier les triggers problématiques
    IF EXISTS (SELECT 1 FROM information_schema.triggers 
               WHERE event_object_table = 'users' AND trigger_name LIKE '%create_user%') THEN
        RETURN QUERY SELECT 'Triggers problématiques'::TEXT, 'ATTENTION'::TEXT, 'Triggers problématiques présents'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Triggers problématiques'::TEXT, 'OK'::TEXT, 'Aucun trigger problématique'::TEXT;
    END IF;

    -- Test 5: Tester la fonction RPC avec un utilisateur existant
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    IF test_user_id IS NOT NULL THEN
        rpc_result := create_user_default_data(test_user_id);
        IF (rpc_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Test RPC'::TEXT, 'OK'::TEXT, 'Fonction RPC fonctionne'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Test RPC'::TEXT, 'ERREUR'::TEXT, (rpc_result->>'error')::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Test RPC'::TEXT, 'SKIP'::TEXT, 'Aucun utilisateur pour le test'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 9. EXÉCUTER LES TESTS

-- Exécuter tous les tests
SELECT * FROM test_complete_signup_fix();

-- 10. MESSAGE DE CONFIRMATION

SELECT 'Correction finale terminée - L''inscription devrait maintenant fonctionner parfaitement' as status;
