-- Diagnostic et correction de l'erreur 500 lors de l'inscription
-- Date: 2024-01-24

-- 1. DIAGNOSTIC DES PROBLÈMES

-- Vérifier les triggers sur la table users
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users';

-- Vérifier les contraintes sur la table users
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users';

-- Vérifier les politiques RLS sur auth.users
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'auth';

-- Vérifier les fonctions RPC existantes
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%user%' 
AND routine_schema = 'public';

-- 2. NETTOYAGE DES TRIGGERS PROBLÉMATIQUES

-- Supprimer tous les triggers sur la table users sauf update_users_updated_at
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_user_automatically ON users;

-- 3. CORRECTION DE LA FONCTION RPC

-- Recréer la fonction RPC avec une gestion d'erreur améliorée
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Vérifier que l'utilisateur existe dans auth.users
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé dans auth.users'
        );
    END IF;

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

        RETURN json_build_object(
            'success', true,
            'message', 'Données par défaut créées avec succès'
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'detail', SQLSTATE
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. PERMISSIONS

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;

-- 5. FONCTION DE TEST

-- Créer une fonction de test pour vérifier l'inscription
CREATE OR REPLACE FUNCTION test_signup_process()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Test 1: Vérifier que la fonction RPC existe
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'create_user_default_data') THEN
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'OK'::TEXT, 'La fonction create_user_default_data existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'ERREUR'::TEXT, 'La fonction create_user_default_data n''existe pas'::TEXT;
    END IF;

    -- Test 2: Vérifier les permissions
    IF EXISTS (SELECT 1 FROM information_schema.routine_privileges 
               WHERE routine_name = 'create_user_default_data' AND grantee = 'anon') THEN
        RETURN QUERY SELECT 'Permissions'::TEXT, 'OK'::TEXT, 'Permissions anon accordées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Permissions'::TEXT, 'ERREUR'::TEXT, 'Permissions anon manquantes'::TEXT;
    END IF;

    -- Test 3: Tester avec un utilisateur existant
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    IF test_user_id IS NOT NULL THEN
        rpc_result := create_user_default_data(test_user_id);
        IF (rpc_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Test RPC'::TEXT, 'OK'::TEXT, 'Fonction RPC exécutée avec succès'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Test RPC'::TEXT, 'ERREUR'::TEXT, (rpc_result->>'error')::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Test RPC'::TEXT, 'SKIP'::TEXT, 'Aucun utilisateur trouvé pour le test'::TEXT;
    END IF;

    -- Test 4: Vérifier les tables nécessaires
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
END;
$$ LANGUAGE plpgsql;

-- 6. EXÉCUTION DU DIAGNOSTIC

-- Exécuter le diagnostic
SELECT * FROM test_signup_process();

-- 7. RECOMMANDATIONS

-- Si des erreurs sont détectées, exécuter les corrections suivantes :

-- A. Si la table subscription_status n'existe pas :
/*
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
*/

-- B. Si la table system_settings n'existe pas :
/*
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
*/

-- C. Activer RLS si nécessaire :
/*
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Politiques pour subscription_status
CREATE POLICY "Users can view own subscription status" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription status" ON subscription_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiques pour system_settings
CREATE POLICY "Users can view own system settings" ON system_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own system settings" ON system_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);
*/
