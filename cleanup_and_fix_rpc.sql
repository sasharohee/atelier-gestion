-- Script de nettoyage complet et correction de la fonction RPC
-- Ce script résout définitivement l'erreur d'ambiguïté de fonction

-- 1. NETTOYAGE COMPLET - Supprimer toutes les fonctions existantes
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Lister toutes les fonctions create_user_default_data
    FOR func_record IN 
        SELECT routine_name, specific_name, routine_definition
        FROM information_schema.routines 
        WHERE routine_name = 'create_user_default_data'
        AND routine_schema = 'public'
    LOOP
        RAISE NOTICE 'Suppression de la fonction: %', func_record.specific_name;
    END LOOP;
END $$;

-- Supprimer toutes les fonctions avec CASCADE pour éviter les dépendances
DROP FUNCTION IF EXISTS create_user_default_data CASCADE;
DROP FUNCTION IF EXISTS public.create_user_default_data CASCADE;

-- 2. VÉRIFIER QUE LES TABLES EXISTENT
-- Créer subscription_status si elle n'existe pas
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

-- Créer system_settings si elle n'existe pas
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
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
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

-- 4. CRÉER LA FONCTION RPC UNIQUE ET ROBUSTE
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    user_exists BOOLEAN;
    user_email TEXT;
    user_metadata JSONB;
    first_name_val TEXT;
    last_name_val TEXT;
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

    -- Récupérer l'email et les métadonnées de l'utilisateur
    SELECT email, raw_user_meta_data INTO user_email, user_metadata
    FROM auth.users 
    WHERE id = p_user_id;

    -- Extraire les noms des métadonnées
    first_name_val := COALESCE(user_metadata->>'first_name', 'Utilisateur');
    last_name_val := COALESCE(user_metadata->>'last_name', '');

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
            first_name_val,
            last_name_val,
            COALESCE(user_email, ''),
            FALSE,
            'free',
            'Compte créé automatiquement - en attente d''activation'
        ) ON CONFLICT (user_id) DO UPDATE SET
            updated_at = NOW(),
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email;
        
        -- Créer les paramètres système par défaut
        INSERT INTO system_settings (user_id, category, key, value, description)
        VALUES 
            (p_user_id, 'general', 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
            (p_user_id, 'general', 'workshop_address', '', 'Adresse de l''atelier'),
            (p_user_id, 'general', 'workshop_phone', '', 'Téléphone de l''atelier'),
            (p_user_id, 'general', 'workshop_email', COALESCE(user_email, ''), 'Email de l''atelier'),
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
            'email', user_email,
            'first_name', first_name_val,
            'last_name', last_name_val
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

-- 5. PERMISSIONS
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO service_role;

-- 6. FONCTION DE TEST SIMPLIFIÉE
CREATE OR REPLACE FUNCTION test_signup_fix()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Test 1: Vérifier que la fonction existe et est unique
    IF (SELECT COUNT(*) FROM information_schema.routines 
        WHERE routine_name = 'create_user_default_data' AND routine_schema = 'public') = 1 THEN
        RETURN QUERY SELECT 'Fonction RPC unique'::TEXT, 'OK'::TEXT, 'Une seule fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction RPC unique'::TEXT, 'ERREUR'::TEXT, 'Plusieurs fonctions ou aucune fonction'::TEXT;
    END IF;

    -- Test 2: Vérifier les permissions
    IF EXISTS (SELECT 1 FROM information_schema.routine_privileges 
               WHERE routine_name = 'create_user_default_data' AND grantee = 'anon') THEN
        RETURN QUERY SELECT 'Permissions anon'::TEXT, 'OK'::TEXT, 'Permissions accordées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Permissions anon'::TEXT, 'ERREUR'::TEXT, 'Permissions manquantes'::TEXT;
    END IF;

    -- Test 3: Tester la fonction avec un utilisateur existant
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    IF test_user_id IS NOT NULL THEN
        -- Utiliser un cast explicite pour éviter l'ambiguïté
        rpc_result := create_user_default_data(test_user_id::UUID);
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

-- 7. EXÉCUTER LE TEST
SELECT * FROM test_signup_fix();

-- 8. MESSAGE DE CONFIRMATION
SELECT 'Nettoyage et correction terminés - L''inscription devrait maintenant fonctionner parfaitement' as status;
