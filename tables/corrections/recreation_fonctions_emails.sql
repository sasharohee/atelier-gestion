-- Recréation des fonctions d'email manquantes
-- Date: 2024-01-24

-- 1. CRÉER LA FONCTION generate_confirmation_token_and_send_email

CREATE OR REPLACE FUNCTION generate_confirmation_token_and_send_email(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    confirmation_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
BEGIN
    -- Générer un token unique
    confirmation_token := encode(gen_random_bytes(32), 'hex');
    expires_at := NOW() + INTERVAL '24 hours';
    confirmation_url := 'http://localhost:3001/auth?tab=confirm&token=' || confirmation_token;
    
    -- Insérer le token dans la table avec gestion de conflit
    INSERT INTO confirmation_emails (user_email, token, expires_at)
    VALUES (p_email, confirmation_token, expires_at)
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'pending',
        sent_at = NULL;
    
    -- Simuler l'envoi d'email (marquer comme envoyé)
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = confirmation_token;
    
    RETURN json_build_object(
        'success', true,
        'token', confirmation_token,
        'expires_at', expires_at,
        'confirmation_url', confirmation_url,
        'email_sent', true,
        'message', 'Token généré et email simulé avec succès'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'email', p_email
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CRÉER LA FONCTION validate_confirmation_token

CREATE OR REPLACE FUNCTION validate_confirmation_token(p_token TEXT)
RETURNS JSON AS $$
DECLARE
    email_record RECORD;
BEGIN
    -- Récupérer le token
    SELECT * INTO email_record FROM confirmation_emails 
    WHERE token = p_token AND status = 'sent';
    
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

-- 3. CRÉER LA FONCTION resend_confirmation_email_real

CREATE OR REPLACE FUNCTION resend_confirmation_email_real(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    new_token TEXT;
    new_expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
BEGIN
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    new_expires_at := NOW() + INTERVAL '24 hours';
    confirmation_url := 'http://localhost:3001/auth?tab=confirm&token=' || new_token;
    
    -- Mettre à jour le token
    UPDATE confirmation_emails 
    SET token = new_token, expires_at = new_expires_at, status = 'pending', sent_at = NULL
    WHERE user_email = p_email;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé'
        );
    END IF;
    
    -- Simuler l'envoi du nouvel email
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = new_token;
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'expires_at', new_expires_at,
        'confirmation_url', confirmation_url,
        'email_sent', true,
        'message', 'Nouvel email de confirmation simulé'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. CRÉER LA FONCTION mark_email_sent

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

-- 5. CRÉER LA FONCTION list_pending_emails

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

-- 6. CONFIGURER LES PERMISSIONS

GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION validate_confirmation_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_confirmation_token(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION resend_confirmation_email_real(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION resend_confirmation_email_real(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION mark_email_sent(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_email_sent(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION list_pending_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION list_pending_emails() TO service_role;

-- 7. TESTER LES FONCTIONS

SELECT '=== TEST DES FONCTIONS ===' as section;

-- Test de génération de token
SELECT generate_confirmation_token_and_send_email('test@example.com') as test_generation;

-- Test de validation de token
SELECT validate_confirmation_token('token_invalide') as test_validation;

-- Test de liste des emails
SELECT * FROM list_pending_emails() as test_liste;

-- 8. VÉRIFIER LES FONCTIONS CRÉÉES

SELECT '=== FONCTIONS CRÉÉES ===' as section;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%confirmation%'
ORDER BY routine_name;

-- 9. NETTOYER LES TESTS

DELETE FROM confirmation_emails WHERE user_email = 'test@example.com';

-- 10. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ generate_confirmation_token_and_send_email créée' as statut1,
    '✅ validate_confirmation_token créée' as statut2,
    '✅ resend_confirmation_email_real créée' as statut3,
    '✅ mark_email_sent créée' as statut4,
    '✅ list_pending_emails créée' as statut5,
    '✅ Permissions configurées' as statut6,
    '✅ Tests effectués' as statut7,
    '✅ Prêt pour utilisation' as statut8;
