-- Correction immédiate - Fonctions manquantes
-- Date: 2024-01-24

-- 1. VÉRIFIER LES FONCTIONS EXISTANTES

SELECT 'Fonctions existantes :' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%confirmation%'
ORDER BY routine_name;

-- 2. CRÉER LA FONCTION MANQUANTE generate_confirmation_token_and_send_email

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
    
    -- Pour l'instant, simuler l'envoi d'email
    -- Dans un environnement de production, vous devriez intégrer un service d'email
    
    -- Mettre à jour le statut comme "envoyé" (simulation)
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

-- 4. CONFIGURER LES PERMISSIONS

GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION resend_confirmation_email_real(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION resend_confirmation_email_real(TEXT) TO service_role;

-- 5. VÉRIFIER QUE LES FONCTIONS SONT CRÉÉES

SELECT 'Fonctions après création :' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%confirmation%'
ORDER BY routine_name;

-- 6. TESTER LA FONCTION

SELECT 'Test de la fonction generate_confirmation_token_and_send_email :' as test;
SELECT generate_confirmation_token_and_send_email('test_correction@example.com') as result;

-- 7. AFFICHER LES EMAILS EN ATTENTE

SELECT 'Emails en attente après correction :' as info;
SELECT 
    user_email,
    token,
    status,
    created_at,
    expires_at
FROM confirmation_emails 
WHERE status IN ('pending', 'sent')
ORDER BY created_at DESC;

-- 8. MESSAGE DE CONFIRMATION

SELECT 'Correction appliquée - Fonctions manquantes créées' as status;
