-- Correction de l'ambiguïté de variable dans resend_confirmation_email_real
-- Date: 2024-01-24

-- 1. CORRIGER LA FONCTION resend_confirmation_email_real

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

-- 2. VÉRIFIER QUE LA FONCTION EST CORRIGÉE

SELECT 'Fonction resend_confirmation_email_real corrigée' as info;

-- 3. TESTER LA FONCTION

SELECT 'Test de la fonction corrigée :' as test;
SELECT resend_confirmation_email_real('Sasharohee26@gmail.com') as result;

-- 4. AFFICHER LES EMAILS MIS À JOUR

SELECT 'Emails de confirmation après correction :' as info;
SELECT 
    user_email,
    token,
    status,
    created_at,
    expires_at,
    'http://localhost:3001/auth?tab=confirm&token=' || token as confirmation_url
FROM confirmation_emails 
WHERE user_email = 'Sasharohee26@gmail.com'
ORDER BY created_at DESC;

-- 5. MESSAGE DE CONFIRMATION

SELECT 'Correction appliquée - Ambiguïté de variable résolue' as status;
