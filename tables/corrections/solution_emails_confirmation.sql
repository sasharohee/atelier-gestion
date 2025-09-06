-- Solution pour les emails de confirmation
-- Date: 2024-01-24
-- Ce script configure l'envoi d'emails de confirmation pour le nouveau système

-- 1. CRÉER UNE TABLE POUR LES EMAILS DE CONFIRMATION

CREATE TABLE IF NOT EXISTS confirmation_emails (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_email TEXT NOT NULL UNIQUE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending',
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CRÉER UNE FONCTION POUR GÉNÉRER UN TOKEN DE CONFIRMATION

CREATE OR REPLACE FUNCTION generate_confirmation_token(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    confirmation_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Générer un token unique
    confirmation_token := encode(gen_random_bytes(32), 'hex');
    expires_at := NOW() + INTERVAL '24 hours';
    
    -- Insérer le token dans la table
    INSERT INTO confirmation_emails (user_email, token, expires_at)
    VALUES (p_email, confirmation_token, expires_at)
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'pending',
        sent_at = NULL;
    
    RETURN json_build_object(
        'success', true,
        'token', confirmation_token,
        'expires_at', expires_at,
        'confirmation_url', 'http://localhost:3001/auth?tab=confirm&token=' || confirmation_token
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CRÉER UNE FONCTION POUR VALIDER UN TOKEN

CREATE OR REPLACE FUNCTION validate_confirmation_token(p_token TEXT)
RETURNS JSON AS $$
DECLARE
    email_record RECORD;
BEGIN
    -- Récupérer le token
    SELECT * INTO email_record FROM confirmation_emails 
    WHERE token = p_token AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Token invalide ou déjà utilisé'
        );
    END IF;
    
    -- Vérifier l'expiration
    IF email_record.expires_at < NOW() THEN
        UPDATE confirmation_emails SET status = 'expired' WHERE token = p_token;
        RETURN json_build_object(
            'success', false,
            'error', 'Token expiré'
        );
    END IF;
    
    -- Marquer comme utilisé
    UPDATE confirmation_emails SET status = 'used' WHERE token = p_token;
    
    RETURN json_build_object(
        'success', true,
        'email', email_record.user_email,
        'message', 'Token validé avec succès'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. CRÉER UNE FONCTION POUR MARQUER UN EMAIL COMME ENVOYÉ

CREATE OR REPLACE FUNCTION mark_email_sent(p_email TEXT)
RETURNS JSON AS $$
BEGIN
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND status = 'pending';
    
    IF FOUND THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Email marqué comme envoyé'
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'error', 'Aucun email en attente trouvé'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. CRÉER UNE FONCTION POUR LISTER LES EMAILS EN ATTENTE

CREATE OR REPLACE FUNCTION list_pending_emails()
RETURNS TABLE(
    id UUID,
    user_email TEXT,
    token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id,
        ce.user_email,
        ce.token,
        ce.expires_at,
        ce.status,
        ce.created_at
    FROM confirmation_emails ce
    WHERE ce.status IN ('pending', 'sent')
    ORDER BY ce.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRÉER UNE FONCTION POUR RENVOYER UN EMAIL

CREATE OR REPLACE FUNCTION resend_confirmation_email(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    new_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    expires_at := NOW() + INTERVAL '24 hours';
    
    -- Mettre à jour le token
    UPDATE confirmation_emails 
    SET token = new_token, expires_at = expires_at, status = 'pending', sent_at = NULL
    WHERE user_email = p_email;
    
    IF FOUND THEN
        RETURN json_build_object(
            'success', true,
            'token', new_token,
            'expires_at', expires_at,
            'confirmation_url', 'http://localhost:3001/auth?tab=confirm&token=' || new_token,
            'message', 'Nouveau token généré'
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. CONFIGURER LES PERMISSIONS

-- Permissions sur la table confirmation_emails
GRANT ALL PRIVILEGES ON TABLE confirmation_emails TO authenticated;
GRANT ALL PRIVILEGES ON TABLE confirmation_emails TO anon;
GRANT ALL PRIVILEGES ON TABLE confirmation_emails TO service_role;

-- Permissions sur les fonctions
GRANT EXECUTE ON FUNCTION generate_confirmation_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_confirmation_token(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION validate_confirmation_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_confirmation_token(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION mark_email_sent(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_email_sent(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION list_pending_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION list_pending_emails() TO service_role;
GRANT EXECUTE ON FUNCTION resend_confirmation_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION resend_confirmation_email(TEXT) TO service_role;

-- 8. FONCTION DE TEST

CREATE OR REPLACE FUNCTION test_email_system()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    token_result JSON;
    validation_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 'Table confirmation_emails'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table confirmation_emails'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 2: Tester la génération de token
    token_result := generate_confirmation_token(test_email);
    IF (token_result->>'success')::boolean THEN
        RETURN QUERY SELECT 'Génération token'::TEXT, 'OK'::TEXT, 'Token généré avec succès'::TEXT;
        
        -- Test 3: Tester la validation de token
        validation_result := validate_confirmation_token(token_result->>'token');
        IF (validation_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Validation token'::TEXT, 'OK'::TEXT, 'Token validé avec succès'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Validation token'::TEXT, 'ERREUR'::TEXT, (validation_result->>'error')::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Génération token'::TEXT, 'ERREUR'::TEXT, (token_result->>'error')::TEXT;
    END IF;

    -- Test 4: Vérifier les fonctions
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_confirmation_token') THEN
        RETURN QUERY SELECT 'Fonction generate_confirmation_token'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction generate_confirmation_token'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'validate_confirmation_token') THEN
        RETURN QUERY SELECT 'Fonction validate_confirmation_token'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction validate_confirmation_token'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    -- Nettoyer
    DELETE FROM confirmation_emails WHERE user_email = test_email;
END;
$$ LANGUAGE plpgsql;

-- 9. EXÉCUTER LES TESTS

SELECT * FROM test_email_system();

-- 10. MESSAGE DE CONFIRMATION

SELECT 'Système d''emails de confirmation configuré - Prêt à utiliser' as status;
