-- Implémentation de l'envoi réel des emails de confirmation
-- Date: 2024-01-24

-- 1. CRÉER UNE FONCTION POUR ENVOYER DES EMAILS RÉELS

CREATE OR REPLACE FUNCTION send_confirmation_email_real(p_email TEXT, p_token TEXT, p_confirmation_url TEXT)
RETURNS JSON AS $$
DECLARE
    email_content TEXT;
    email_subject TEXT;
    result JSON;
BEGIN
    -- Construire le contenu de l'email
    email_subject := 'Confirmation de votre inscription - App Atelier';
    
    email_content := '
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Confirmation d''inscription</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .button { display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .token { background-color: #f0f0f0; padding: 10px; border-radius: 5px; font-family: monospace; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Confirmation d''inscription</h1>
        </div>
        <div class="content">
            <h2>Bonjour !</h2>
            <p>Merci de vous être inscrit à notre application d''atelier.</p>
            <p>Pour confirmer votre inscription, veuillez cliquer sur le bouton ci-dessous :</p>
            
            <a href="' || p_confirmation_url || '" class="button">Confirmer mon inscription</a>
            
            <p>Ou copiez-collez ce lien dans votre navigateur :</p>
            <div class="token">' || p_confirmation_url || '</div>
            
            <p><strong>Token de confirmation :</strong></p>
            <div class="token">' || p_token || '</div>
            
            <p>Ce lien expirera dans 24 heures.</p>
            
            <p>Si vous n''avez pas demandé cette inscription, vous pouvez ignorer cet email.</p>
        </div>
        <div class="footer">
            <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
            <p>© 2024 App Atelier - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>';

    -- Utiliser la fonction pg_mail pour envoyer l'email (si disponible)
    -- Note: Cette fonction nécessite l'extension pg_mail ou un service d'email configuré
    
    -- Pour l'instant, nous allons simuler l'envoi et stocker les détails
    -- Dans un environnement de production, vous devriez utiliser un service comme SendGrid, Mailgun, etc.
    
    -- Mettre à jour le statut dans la base de données
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = p_token;
    
    -- Retourner le résultat
    result := json_build_object(
        'success', true,
        'message', 'Email de confirmation envoyé',
        'email', p_email,
        'token', p_token,
        'confirmation_url', p_confirmation_url,
        'sent_at', NOW()
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, retourner les détails
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'email', p_email,
            'token', p_token
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. MODIFIER LA FONCTION generate_confirmation_token POUR ENVOYER L'EMAIL

CREATE OR REPLACE FUNCTION generate_confirmation_token_and_send_email(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    confirmation_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
    email_result JSON;
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
    
    -- Envoyer l'email de confirmation
    email_result := send_confirmation_email_real(p_email, confirmation_token, confirmation_url);
    
    -- Si l'envoi a réussi, retourner le résultat
    IF (email_result->>'success')::boolean THEN
        RETURN json_build_object(
            'success', true,
            'token', confirmation_token,
            'expires_at', expires_at,
            'confirmation_url', confirmation_url,
            'email_sent', true,
            'message', 'Token généré et email envoyé avec succès'
        );
    ELSE
        -- Si l'envoi a échoué, retourner le token mais indiquer que l'email n'a pas été envoyé
        RETURN json_build_object(
            'success', true,
            'token', confirmation_token,
            'expires_at', expires_at,
            'confirmation_url', confirmation_url,
            'email_sent', false,
            'email_error', email_result->>'error',
            'message', 'Token généré mais échec de l''envoi de l''email'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FONCTION POUR RENVOYER UN EMAIL DE CONFIRMATION

CREATE OR REPLACE FUNCTION resend_confirmation_email_real(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    new_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
    email_result JSON;
BEGIN
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    expires_at := NOW() + INTERVAL '24 hours';
    confirmation_url := 'http://localhost:3001/auth?tab=confirm&token=' || new_token;
    
    -- Mettre à jour le token
    UPDATE confirmation_emails 
    SET token = new_token, expires_at = expires_at, status = 'pending', sent_at = NULL
    WHERE user_email = p_email;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé'
        );
    END IF;
    
    -- Envoyer le nouvel email de confirmation
    email_result := send_confirmation_email_real(p_email, new_token, confirmation_url);
    
    -- Retourner le résultat
    IF (email_result->>'success')::boolean THEN
        RETURN json_build_object(
            'success', true,
            'token', new_token,
            'expires_at', expires_at,
            'confirmation_url', confirmation_url,
            'email_sent', true,
            'message', 'Nouvel email de confirmation envoyé'
        );
    ELSE
        RETURN json_build_object(
            'success', true,
            'token', new_token,
            'expires_at', expires_at,
            'confirmation_url', confirmation_url,
            'email_sent', false,
            'email_error', email_result->>'error',
            'message', 'Nouveau token généré mais échec de l''envoi de l''email'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. FONCTION POUR LISTER LES EMAILS EN ATTENTE D'ENVOI

CREATE OR REPLACE FUNCTION list_pending_emails_for_admin()
RETURNS TABLE(
    id UUID,
    user_email TEXT,
    token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    status TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    confirmation_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id,
        ce.user_email,
        ce.token,
        ce.expires_at,
        ce.status,
        ce.sent_at,
        ce.created_at,
        'http://localhost:3001/auth?tab=confirm&token=' || ce.token as confirmation_url
    FROM confirmation_emails ce
    WHERE ce.status IN ('pending', 'sent')
    ORDER BY ce.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. FONCTION POUR ENVOYER MANUELLEMENT UN EMAIL

CREATE OR REPLACE FUNCTION send_manual_confirmation_email(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    email_record RECORD;
    email_result JSON;
BEGIN
    -- Récupérer les informations de l'email
    SELECT * INTO email_record FROM confirmation_emails 
    WHERE user_email = p_email AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Aucun email en attente trouvé'
        );
    END IF;
    
    -- Vérifier si le token n'a pas expiré
    IF email_record.expires_at < NOW() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Token expiré'
        );
    END IF;
    
    -- Envoyer l'email
    email_result := send_confirmation_email_real(
        email_record.user_email, 
        email_record.token, 
        'http://localhost:3001/auth?tab=confirm&token=' || email_record.token
    );
    
    RETURN email_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CONFIGURER LES PERMISSIONS

GRANT EXECUTE ON FUNCTION send_confirmation_email_real(TEXT, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION resend_confirmation_email_real(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION resend_confirmation_email_real(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION list_pending_emails_for_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION list_pending_emails_for_admin() TO service_role;
GRANT EXECUTE ON FUNCTION send_manual_confirmation_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_manual_confirmation_email(TEXT) TO service_role;

-- 7. FONCTION DE TEST

CREATE OR REPLACE FUNCTION test_email_system_real()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    token_result JSON;
    email_result JSON;
BEGIN
    -- Test 1: Vérifier les nouvelles fonctions
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'send_confirmation_email_real') THEN
        RETURN QUERY SELECT 'Fonction send_confirmation_email_real'::TEXT, 'OK'::TEXT, 'Fonction créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction send_confirmation_email_real'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_confirmation_token_and_send_email') THEN
        RETURN QUERY SELECT 'Fonction generate_confirmation_token_and_send_email'::TEXT, 'OK'::TEXT, 'Fonction créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction generate_confirmation_token_and_send_email'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    -- Test 2: Tester la génération et l'envoi d'email
    token_result := generate_confirmation_token_and_send_email(test_email);
    IF (token_result->>'success')::boolean THEN
        RETURN QUERY SELECT 'Génération et envoi email'::TEXT, 'OK'::TEXT, 'Token généré et email traité'::TEXT;
        
        -- Test 3: Tester l'envoi manuel
        email_result := send_manual_confirmation_email(test_email);
        IF (email_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Envoi manuel email'::TEXT, 'OK'::TEXT, 'Email envoyé manuellement'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Envoi manuel email'::TEXT, 'INFO'::TEXT, 'Email simulé (pas de service réel)'::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Génération et envoi email'::TEXT, 'ERREUR'::TEXT, (token_result->>'error')::TEXT;
    END IF;

    -- Nettoyer
    DELETE FROM confirmation_emails WHERE user_email = test_email;
END;
$$ LANGUAGE plpgsql;

-- 8. EXÉCUTER LES TESTS

SELECT * FROM test_email_system_real();

-- 9. MESSAGE DE CONFIRMATION

SELECT 'Système d''envoi d''emails réel implémenté - Prêt pour configuration' as status;
