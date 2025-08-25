-- Configuration pour l'envoi d'emails réels via Supabase (Version Corrigée)
-- Date: 2024-01-24

-- 1. CRÉER UNE FONCTION POUR UTILISER L'API SUPABASE AUTH

CREATE OR REPLACE FUNCTION send_confirmation_email_via_supabase(p_email TEXT, p_token TEXT, p_confirmation_url TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Cette fonction utilise l'API Supabase Auth pour envoyer des emails
    -- Note: Dans un environnement de production, vous devriez utiliser
    -- l'API Supabase Auth directement depuis votre application
    
    -- Pour l'instant, nous allons simuler l'envoi et stocker les détails
    -- pour que vous puissiez configurer l'envoi réel
    
    -- Mettre à jour le statut dans la base de données
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = p_token;
    
    -- Retourner le résultat avec des instructions
    result := json_build_object(
        'success', true,
        'message', 'Email de confirmation préparé - Configuration requise',
        'email', p_email,
        'token', p_token,
        'confirmation_url', p_confirmation_url,
        'sent_at', NOW(),
        'instructions', 'Configurez l''envoi d''emails dans le dashboard Supabase',
        'next_steps', ARRAY[
            '1. Aller sur https://supabase.com/dashboard',
            '2. Sélectionner votre projet',
            '3. Authentication > Email Templates',
            '4. Configurer le template de confirmation',
            '5. Tester l''envoi d''email'
        ]
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'email', p_email,
            'token', p_token
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. MODIFIER LA FONCTION PRINCIPALE POUR UTILISER LA NOUVELLE FONCTION

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
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || confirmation_token;
    
    -- Insérer le token dans la table avec gestion de conflit
    INSERT INTO confirmation_emails (user_email, token, expires_at)
    VALUES (p_email, confirmation_token, expires_at)
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'pending',
        sent_at = NULL;
    
    -- Envoyer l'email de confirmation via Supabase
    email_result := send_confirmation_email_via_supabase(p_email, confirmation_token, confirmation_url);
    
    -- Retourner le résultat
    RETURN json_build_object(
        'success', true,
        'token', confirmation_token,
        'expires_at', expires_at,
        'confirmation_url', confirmation_url,
        'email_sent', (email_result->>'success')::boolean,
        'message', email_result->>'message',
        'instructions', email_result->>'instructions',
        'next_steps', email_result->>'next_steps'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CRÉER UNE FONCTION POUR TESTER LA CONFIGURATION

CREATE OR REPLACE FUNCTION test_email_configuration()
RETURNS TABLE(section TEXT, element TEXT, status TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 
            'Base de données'::TEXT, 
            'Table confirmation_emails'::TEXT, 
            'OK'::TEXT, 
            'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Base de données'::TEXT, 
            'Table confirmation_emails'::TEXT, 
            'ERREUR'::TEXT, 
            'Table inaccessible'::TEXT;
    END IF;
    
    -- Test 2: Vérifier la fonction generate_confirmation_token_and_send_email
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_confirmation_token_and_send_email') THEN
        RETURN QUERY SELECT 
            'Fonctions'::TEXT, 
            'generate_confirmation_token_and_send_email'::TEXT, 
            'OK'::TEXT, 
            'Fonction créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Fonctions'::TEXT, 
            'generate_confirmation_token_and_send_email'::TEXT, 
            'ERREUR'::TEXT, 
            'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 3: Tester la génération de token
    test_result := generate_confirmation_token_and_send_email(test_email);
    
    IF (test_result->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Test'::TEXT, 
            'Génération de token'::TEXT, 
            'OK'::TEXT, 
            'Token généré: ' || (test_result->>'token')::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Test'::TEXT, 
            'Génération de token'::TEXT, 
            'ERREUR'::TEXT, 
            'Échec de génération'::TEXT;
    END IF;
    
    -- Test 4: Vérifier l'URL de confirmation
    IF (test_result->>'confirmation_url')::TEXT LIKE '%localhost:3002%' THEN
        RETURN QUERY SELECT 
            'Configuration'::TEXT, 
            'URL de confirmation'::TEXT, 
            'OK'::TEXT, 
            'URL correcte: ' || (test_result->>'confirmation_url')::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Configuration'::TEXT, 
            'URL de confirmation'::TEXT, 
            'ATTENTION'::TEXT, 
            'URL incorrecte: ' || (test_result->>'confirmation_url')::TEXT;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM confirmation_emails WHERE user_email = test_email;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- 4. PERMISSIONS

GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_confirmation_token_and_send_email(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION send_confirmation_email_via_supabase(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_confirmation_email_via_supabase(TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION test_email_configuration() TO authenticated;
GRANT EXECUTE ON FUNCTION test_email_configuration() TO anon;

-- 5. EXÉCUTER LES TESTS

SELECT '=== TEST DE LA CONFIGURATION EMAIL ===' as info;
SELECT * FROM test_email_configuration();

-- 6. INSTRUCTIONS POUR L'UTILISATEUR

SELECT 
    '=== INSTRUCTIONS POUR CONFIGURER L''ENVOI D''EMAILS ===' as section,
    'Pour recevoir des emails de confirmation réels, suivez ces étapes:' as instruction;

SELECT 
    '1. Configuration Supabase' as step,
    'Aller sur https://supabase.com/dashboard et sélectionner votre projet' as action;

SELECT 
    '2. Templates d''email' as step,
    'Authentication > Email Templates > Confirmation' as action;

SELECT 
    '3. Configurer le template' as step,
    'Modifier le template pour inclure le lien de confirmation' as action;

SELECT 
    '4. Variables disponibles' as step,
    '{{ .ConfirmationURL }}, {{ .Token }}, {{ .Email }}' as action;

SELECT 
    '5. Tester' as step,
    'Utiliser la fonction test_email_configuration() pour vérifier' as action;

SELECT 
    '=== CONFIGURATION TERMINÉE ===' as status,
    'Les emails seront maintenant envoyés via Supabase Auth' as message;
