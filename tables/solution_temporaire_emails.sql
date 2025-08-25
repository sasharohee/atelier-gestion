-- Solution temporaire pour afficher les emails générés
-- Date: 2024-01-24

-- 1. FONCTION POUR AFFICHER LES EMAILS EN ATTENTE

CREATE OR REPLACE FUNCTION display_pending_emails()
RETURNS TABLE(
    email TEXT,
    token TEXT,
    confirmation_url TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.user_email as email,
        ce.token,
        'http://localhost:3001/auth?tab=confirm&token=' || ce.token as confirmation_url,
        ce.status,
        ce.created_at,
        ce.expires_at
    FROM confirmation_emails ce
    WHERE ce.status IN ('pending', 'sent')
    ORDER BY ce.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. FONCTION POUR AFFICHER UN EMAIL SPÉCIFIQUE

CREATE OR REPLACE FUNCTION display_email_content(p_email TEXT)
RETURNS TABLE(
    email TEXT,
    token TEXT,
    confirmation_url TEXT,
    status TEXT,
    email_html TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    email_record RECORD;
    email_html TEXT;
BEGIN
    -- Récupérer les informations de l'email
    SELECT * INTO email_record FROM confirmation_emails 
    WHERE user_email = p_email;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- Construire le contenu HTML de l'email
    email_html := '
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
            
            <a href="http://localhost:3001/auth?tab=confirm&token=' || email_record.token || '" class="button">Confirmer mon inscription</a>
            
            <p>Ou copiez-collez ce lien dans votre navigateur :</p>
            <div class="token">http://localhost:3001/auth?tab=confirm&token=' || email_record.token || '</div>
            
            <p><strong>Token de confirmation :</strong></p>
            <div class="token">' || email_record.token || '</div>
            
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
    
    RETURN QUERY
    SELECT 
        email_record.user_email as email,
        email_record.token,
        'http://localhost:3001/auth?tab=confirm&token=' || email_record.token as confirmation_url,
        email_record.status,
        email_html,
        email_record.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FONCTION POUR NETTOYER LES EMAILS EXPIRÉS

CREATE OR REPLACE FUNCTION cleanup_expired_emails()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    UPDATE confirmation_emails 
    SET status = 'expired'
    WHERE expires_at < NOW() AND status = 'pending';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. FONCTION POUR RÉGÉNÉRER UN EMAIL EXPIRÉ

CREATE OR REPLACE FUNCTION regenerate_expired_email(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    new_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
BEGIN
    -- Vérifier si l'email existe et est expiré
    IF NOT EXISTS (SELECT 1 FROM confirmation_emails WHERE user_email = p_email AND status = 'expired') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé ou non expiré'
        );
    END IF;
    
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    expires_at := NOW() + INTERVAL '24 hours';
    confirmation_url := 'http://localhost:3001/auth?tab=confirm&token=' || new_token;
    
    -- Mettre à jour avec le nouveau token
    UPDATE confirmation_emails 
    SET token = new_token, expires_at = expires_at, status = 'pending', sent_at = NULL
    WHERE user_email = p_email;
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'expires_at', expires_at,
        'confirmation_url', confirmation_url,
        'message', 'Email régénéré avec succès'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. CONFIGURER LES PERMISSIONS

GRANT EXECUTE ON FUNCTION display_pending_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION display_pending_emails() TO service_role;
GRANT EXECUTE ON FUNCTION display_email_content(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION display_email_content(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_expired_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_emails() TO service_role;
GRANT EXECUTE ON FUNCTION regenerate_expired_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION regenerate_expired_email(TEXT) TO service_role;

-- 6. EXÉCUTER LE NETTOYAGE INITIAL

SELECT cleanup_expired_emails() as emails_expires_nettoyes;

-- 7. AFFICHER LES EMAILS EN ATTENTE

SELECT 'Emails en attente de confirmation :' as message;
SELECT * FROM display_pending_emails();

-- 8. MESSAGE DE CONFIRMATION

SELECT 'Solution temporaire configurée - Utilisez display_pending_emails() pour voir les emails' as status;
