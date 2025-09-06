-- Correction de l'erreur 500 lors de l'inscription avec RLS sécurisé
-- Date: 2024-01-24
-- Cette solution maintient RLS activé et corrige les politiques pour permettre l'inscription

-- 1. SUPPRIMER LES TRIGGERS PROBLÉMATIQUES
-- Supprimer tous les triggers qui pourraient interférer avec l'inscription
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_user_automatically ON users;
DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_subscription_status ON users;
DROP TRIGGER IF EXISTS trigger_create_user_settings ON users;
DROP TRIGGER IF EXISTS trigger_create_system_settings ON users;

-- 2. VÉRIFIER ET CRÉER LES TABLES NÉCESSAIRES

-- Créer la table subscription_status si elle n'existe pas
CREATE TABLE IF NOT EXISTS subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium', 'enterprise')),
    status TEXT DEFAULT 'INACTIF' CHECK (status IN ('ACTIF', 'INACTIF', 'SUSPENDU')),
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

-- 3. CONFIGURER RLS AVEC POLITIQUES SÉCURISÉES

-- Activer RLS sur les tables
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Supprimer toutes les anciennes politiques pour éviter les conflits
DROP POLICY IF EXISTS "Users can view their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can create their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admins can delete all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admin page full access" ON subscription_status;
DROP POLICY IF EXISTS "Service role can manage subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can view own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can insert own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can update own system settings" ON system_settings;
DROP POLICY IF EXISTS "Service role can manage system settings" ON system_settings;

-- 4. CRÉER DES POLITIQUES RLS SÉCURISÉES

-- Politiques pour subscription_status
-- Permettre aux utilisateurs authentifiés de voir leur propre statut
CREATE POLICY "Users can view their own subscription status" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

-- Permettre aux utilisateurs authentifiés de créer leur propre statut
CREATE POLICY "Users can create their own subscription status" ON subscription_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Permettre aux utilisateurs authentifiés de modifier leur propre statut
CREATE POLICY "Users can update their own subscription status" ON subscription_status
    FOR UPDATE USING (auth.uid() = user_id);

-- Permettre au service role de gérer tous les statuts (pour l'inscription)
CREATE POLICY "Service role can manage subscription status" ON subscription_status
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Politiques pour system_settings
-- Permettre aux utilisateurs authentifiés de voir leurs propres paramètres
CREATE POLICY "Users can view own system settings" ON system_settings
    FOR SELECT USING (auth.uid() = user_id);

-- Permettre aux utilisateurs authentifiés de créer leurs propres paramètres
CREATE POLICY "Users can insert own system settings" ON system_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Permettre aux utilisateurs authentifiés de modifier leurs propres paramètres
CREATE POLICY "Users can update own system settings" ON system_settings
    FOR UPDATE USING (auth.uid() = user_id);

-- Permettre au service role de gérer tous les paramètres (pour l'inscription)
CREATE POLICY "Service role can manage system settings" ON system_settings
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- 5. CRÉER UNE FONCTION RPC SÉCURISÉE POUR L'INSCRIPTION

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS create_user_default_data(UUID);

-- Créer une nouvelle fonction RPC sécurisée
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    user_email TEXT;
    user_first_name TEXT;
    user_last_name TEXT;
    is_admin BOOLEAN;
BEGIN
    -- Vérifier que l'utilisateur existe dans auth.users
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé dans auth.users'
        );
    END IF;

    -- Récupérer les informations de l'utilisateur
    SELECT email, raw_user_meta_data->>'first_name', raw_user_meta_data->>'last_name'
    INTO user_email, user_first_name, user_last_name
    FROM auth.users 
    WHERE id = p_user_id;

    -- Déterminer si c'est un admin
    is_admin := (user_email = 'srohee32@gmail.com' OR user_email = 'repphonereparation@gmail.com');

    BEGIN
        -- Créer le statut d'abonnement
        INSERT INTO subscription_status (
            user_id,
            first_name,
            last_name,
            email,
            is_active,
            subscription_type,
            status,
            notes
        ) VALUES (
            p_user_id,
            COALESCE(user_first_name, 'Utilisateur'),
            COALESCE(user_last_name, ''),
            COALESCE(user_email, ''),
            is_admin,
            CASE WHEN is_admin THEN 'premium' ELSE 'free' END,
            CASE WHEN is_admin THEN 'ACTIF' ELSE 'INACTIF' END,
            'Compte créé lors de l''inscription'
        ) ON CONFLICT (user_id) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            updated_at = NOW();
        
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
            'message', 'Données par défaut créées avec succès',
            'user_id', p_user_id,
            'is_admin', is_admin
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

-- 6. PERMISSIONS

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO service_role;

-- 7. MODIFIER LE CODE FRONTEND POUR UTILISER LA FONCTION RPC

-- Créer une fonction RPC pour l'inscription complète
CREATE OR REPLACE FUNCTION signup_user_with_default_data(
    p_email TEXT,
    p_password TEXT,
    p_first_name TEXT DEFAULT 'Utilisateur',
    p_last_name TEXT DEFAULT 'Test',
    p_role TEXT DEFAULT 'technician'
)
RETURNS JSON AS $$
DECLARE
    new_user_id UUID;
    result JSON;
BEGIN
    -- Cette fonction sera appelée depuis le frontend après l'inscription Supabase Auth
    -- Elle crée les données par défaut pour le nouvel utilisateur
    
    -- Récupérer l'ID de l'utilisateur actuellement authentifié
    new_user_id := auth.uid();
    
    IF new_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Créer les données par défaut
    result := create_user_default_data(new_user_id);
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction d'inscription
GRANT EXECUTE ON FUNCTION signup_user_with_default_data(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION signup_user_with_default_data(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;

-- 8. VÉRIFIER LA CONFIGURATION

-- Vérifier que tout est en place
SELECT 
    'Configuration' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_status') 
        THEN 'OK' ELSE 'ERREUR' 
    END as subscription_status_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings') 
        THEN 'OK' ELSE 'ERREUR' 
    END as system_settings_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'create_user_default_data') 
        THEN 'OK' ELSE 'ERREUR' 
    END as rpc_function,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routine_privileges 
                    WHERE routine_name = 'create_user_default_data' AND grantee = 'anon') 
        THEN 'OK' ELSE 'ERREUR' 
    END as anon_permissions,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscription_status' AND policyname = 'Service role can manage subscription status') 
        THEN 'OK' ELSE 'ERREUR' 
    END as service_role_policy;

-- 9. TEST DE LA CONFIGURATION

-- Tester avec un utilisateur existant
DO $$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Récupérer le premier utilisateur existant
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        rpc_result := create_user_default_data(test_user_id);
        RAISE NOTICE 'Test RPC avec utilisateur %: %', test_user_id, rpc_result;
    ELSE
        RAISE NOTICE 'Aucun utilisateur trouvé pour le test';
    END IF;
END;
$$;

-- 10. MESSAGE DE CONFIRMATION

SELECT 'Correction terminée - L''inscription devrait maintenant fonctionner avec RLS sécurisé' as status;
