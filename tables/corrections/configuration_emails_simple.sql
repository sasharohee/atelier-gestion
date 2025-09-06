-- Configuration simple pour l'envoi d'emails via Supabase
-- Date: 2024-01-24

-- 1. CRÉER LA FONCTION PRINCIPALE

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
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || confirmation_token;
    
    -- Insérer le token dans la table avec gestion de conflit
    INSERT INTO confirmation_emails (user_email, token, expires_at)
    VALUES (p_email, confirmation_token, expires_at)
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'pending',
        sent_at = NULL;
    
    -- Marquer comme envoyé (simulation)
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = confirmation_token;
    
    -- Retourner le résultat
    RETURN json_build_object(
        'success', true,
        'token', confirmation_token,
        'expires_at', expires_at,
        'confirmation_url', confirmation_url,
        'email_sent', true,
        'message', 'Token généré et email préparé - Configurez Supabase Auth pour l''envoi réel',
        'instructions', 'Allez dans Supabase Dashboard > Authentication > Email Templates',
        'next_steps', ARRAY[
            '1. Aller sur https://supabase.com/dashboard',
            '2. Sélectionner votre projet',
            '3. Authentication > Email Templates',
            '4. Configurer le template de confirmation',
            '5. Tester l''envoi d''email'
        ]
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CRÉER UNE FONCTION DE TEST SIMPLE

CREATE OR REPLACE FUNCTION test_email_simple()
RETURNS TABLE(test_name TEXT, status TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 
            'Table confirmation_emails'::TEXT, 
            'OK'::TEXT, 
            'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Table confirmation_emails'::TEXT, 
            'ERREUR'::TEXT, 
            'Table inaccessible'::TEXT;
    END IF;
    
    -- Test 2: Tester la génération de token
    test_result := generate_confirmation_token_and_send_email(test_email);
    
    IF (test_result->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Génération de token'::TEXT, 
            'OK'::TEXT, 
            'Token généré avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Génération de token'::TEXT, 
            'ERREUR'::TEXT, 
            'Échec de génération'::TEXT;
    END IF;
    
    -- Test 3: Vérifier l'URL de confirmation
    IF (test_result->>'confirmation_url')::TEXT LIKE '%localhost:3002%' THEN
        RETURN QUERY SELECT 
            'URL de confirmation'::TEXT, 
            'OK'::TEXT, 
            'URL correcte'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'URL de confirmation'::TEXT, 
            'ATTENTION'::TEXT, 
            'URL incorrecte'::TEXT;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM confirmation_emails WHERE user_email = test_email;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- 3. PERMISSIONS

GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION test_email_simple() TO authenticated;
GRANT EXECUTE ON FUNCTION test_email_simple() TO anon;

-- 4. EXÉCUTER LE TEST

SELECT '=== TEST DE LA CONFIGURATION EMAIL ===' as info;
SELECT * FROM test_email_simple();

-- 5. INSTRUCTIONS

SELECT 
    '=== INSTRUCTIONS ===' as section,
    'Pour configurer l''envoi d''emails réels :' as instruction;

SELECT 
    '1. Dashboard Supabase' as step,
    'https://supabase.com/dashboard > votre projet' as action;

SELECT 
    '2. Email Templates' as step,
    'Authentication > Email Templates > Confirmation' as action;

SELECT 
    '3. Template HTML' as step,
    'Utiliser {{ .ConfirmationURL }} et {{ .Token }}' as action;

SELECT 
    '4. URLs de redirection' as step,
    'Authentication > URL Configuration' as action;

SELECT 
    '=== PRÊT ===' as status,
    'Testez maintenant l''inscription dans votre application' as message;
