-- Correction immédiate de l'erreur 500 lors de l'inscription
-- Date: 2024-01-24

-- 1. SUPPRIMER LES TRIGGERS PROBLÉMATIQUES

-- Supprimer tous les triggers qui pourraient interférer avec l'inscription
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON users;
DROP TRIGGER IF EXISTS trigger_create_user_automatically ON users;
DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON users;

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

-- 3. CONFIGURER RLS

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

-- Créer les nouvelles politiques
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

-- 4. CRÉER UNE FONCTION RPC SIMPLIFIÉE

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS create_user_default_data(UUID);

-- Créer une nouvelle fonction RPC simplifiée
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

-- 5. PERMISSIONS

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;

-- 6. VÉRIFIER LA CONFIGURATION

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
    END as anon_permissions;

-- 7. TEST DE LA FONCTION RPC

-- Tester la fonction avec un utilisateur existant
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

-- 8. MESSAGE DE CONFIRMATION

SELECT 'Correction terminée - L''inscription devrait maintenant fonctionner' as status;
