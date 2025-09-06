-- Solution immédiate pour gérer les doublons d'email
-- Date: 2024-01-24

-- 1. CRÉER UNE FONCTION SIMPLE POUR GÉRER LES DOUBLONS

CREATE OR REPLACE FUNCTION handle_duplicate_signup(p_email TEXT)
RETURNS JSON AS $$
DECLARE
    existing_record RECORD;
    new_token TEXT;
    confirmation_url TEXT;
BEGIN
    -- Vérifier si l'email existe déjà
    SELECT * INTO existing_record 
    FROM pending_signups 
    WHERE email = p_email;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé'
        );
    END IF;
    
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || new_token;
    
    -- Mettre à jour le token existant
    UPDATE pending_signups 
    SET token = new_token, 
        updated_at = NOW()
    WHERE email = p_email;
    
    -- Insérer ou mettre à jour dans confirmation_emails
    INSERT INTO confirmation_emails (user_email, token, expires_at, status, sent_at)
    VALUES (p_email, new_token, NOW() + INTERVAL '24 hours', 'sent', NOW())
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'sent',
        sent_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'confirmation_url', confirmation_url,
        'message', 'Nouveau token généré pour l''email existant',
        'status', existing_record.status,
        'data', row_to_json(existing_record)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CRÉER UNE FONCTION POUR GÉRER L'INSCRIPTION AVEC GESTION DE DOUBLON

CREATE OR REPLACE FUNCTION signup_with_duplicate_handling(
    p_email TEXT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_role TEXT DEFAULT 'technician'
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    new_token TEXT;
    confirmation_url TEXT;
BEGIN
    -- Essayer d'insérer une nouvelle demande
    INSERT INTO pending_signups (email, first_name, last_name, role, status)
    VALUES (p_email, p_first_name, p_last_name, p_role, 'pending')
    RETURNING * INTO result;
    
    -- Si l'insertion réussit, générer un token
    new_token := encode(gen_random_bytes(32), 'hex');
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || new_token;
    
    -- Insérer dans confirmation_emails
    INSERT INTO confirmation_emails (user_email, token, expires_at, status, sent_at)
    VALUES (p_email, new_token, NOW() + INTERVAL '24 hours', 'sent', NOW())
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'sent',
        sent_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'confirmation_url', confirmation_url,
        'message', 'Nouvelle demande d''inscription créée',
        'status', 'pending',
        'data', result
    );
    
EXCEPTION
    WHEN unique_violation THEN
        -- Gérer le doublon
        RETURN handle_duplicate_signup(p_email);
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CRÉER UNE FONCTION DE TEST

CREATE OR REPLACE FUNCTION test_duplicate_handling()
RETURNS TABLE(test_name TEXT, status TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_duplicate_' || extract(epoch from now())::text || '@example.com';
    result1 JSON;
    result2 JSON;
BEGIN
    -- Test 1: Première inscription
    result1 := signup_with_duplicate_handling(test_email, 'Test', 'User', 'technician');
    
    IF (result1->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Première inscription'::TEXT, 
            'OK'::TEXT, 
            'Inscription créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Première inscription'::TEXT, 
            'ERREUR'::TEXT, 
            (result1->>'error')::TEXT;
    END IF;
    
    -- Test 2: Tentative de doublon
    result2 := signup_with_duplicate_handling(test_email, 'Test', 'User', 'technician');
    
    IF (result2->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Gestion du doublon'::TEXT, 
            'OK'::TEXT, 
            'Doublon géré avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Gestion du doublon'::TEXT, 
            'ERREUR'::TEXT, 
            (result2->>'error')::TEXT;
    END IF;
    
    -- Nettoyer
    DELETE FROM pending_signups WHERE email = test_email;
    DELETE FROM confirmation_emails WHERE user_email = test_email;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- 4. PERMISSIONS

GRANT EXECUTE ON FUNCTION handle_duplicate_signup(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION handle_duplicate_signup(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION signup_with_duplicate_handling(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION signup_with_duplicate_handling(TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION test_duplicate_handling() TO authenticated;
GRANT EXECUTE ON FUNCTION test_duplicate_handling() TO anon;

-- 5. EXÉCUTER LE TEST

SELECT '=== TEST DE LA GESTION DES DOUBLONS ===' as info;
SELECT * FROM test_duplicate_handling();

-- 6. INSTRUCTIONS

SELECT 
    '=== INSTRUCTIONS ===' as section,
    'Pour utiliser cette solution :' as instruction;

SELECT 
    '1. Utiliser la fonction' as step,
    'signup_with_duplicate_handling(email, first_name, last_name, role)' as action;

SELECT 
    '2. Gestion automatique' as step,
    'Les doublons sont gérés automatiquement' as action;

SELECT 
    '3. Token généré' as step,
    'Un nouveau token est généré pour les doublons' as action;

SELECT 
    '=== PRÊT ===' as status,
    'Testez maintenant l''inscription avec un email existant' as message;
