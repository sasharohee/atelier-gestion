-- Correction ciblée de la fonction RPC create_user_default_data
-- Ce script corrige spécifiquement l'erreur 500 lors de l'inscription

-- 1. Supprimer TOUTES les anciennes fonctions pour éviter les conflits
DROP FUNCTION IF EXISTS create_user_default_data(UUID);
DROP FUNCTION IF EXISTS create_user_default_data(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_user_default_data(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_user_default_data(UUID, JSONB);
DROP FUNCTION IF EXISTS create_user_default_data(UUID, TEXT);
DROP FUNCTION IF EXISTS create_user_default_data CASCADE;

-- 2. Créer une nouvelle fonction RPC robuste avec gestion d'erreur
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    user_exists BOOLEAN;
    user_email TEXT;
    user_metadata JSONB;
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
            COALESCE(user_metadata->>'first_name', 'Utilisateur'),
            COALESCE(user_metadata->>'last_name', ''),
            COALESCE(user_email, ''),
            FALSE,
            'free',
            'Compte créé automatiquement - en attente d''activation'
        ) ON CONFLICT (user_id) DO UPDATE SET
            updated_at = NOW();
        
        -- Créer les paramètres système par défaut avec gestion d'erreur
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
            'email', user_email
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

-- 3. Donner les permissions d'exécution à tous les rôles nécessaires
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO service_role;

-- 4. Créer une fonction de test simple
CREATE OR REPLACE FUNCTION test_signup_fix()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Test 1: Vérifier que la fonction existe
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'create_user_default_data') THEN
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
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

-- 5. Exécuter le test
SELECT * FROM test_signup_fix();

-- 6. Message de confirmation
SELECT 'Correction de la fonction RPC terminée - L''inscription devrait maintenant fonctionner' as status;
