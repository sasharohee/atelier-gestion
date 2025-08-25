-- Solution alternative sans Supabase Auth
-- Date: 2024-01-24

-- 1. CRÉER UNE TABLE D'AUTHENTIFICATION SIMPLE

CREATE TABLE IF NOT EXISTS simple_auth (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    role TEXT DEFAULT 'technician',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CRÉER L'UTILISATEUR DANS CETTE TABLE

INSERT INTO simple_auth (
    email,
    password_hash,
    first_name,
    last_name,
    role,
    is_active
) VALUES (
    'Sasharohee26@gmail.com',
    'password123', -- Mot de passe simple pour test
    'Sasha',
    'Rohee',
    'technician',
    true
) ON CONFLICT (email) DO UPDATE SET
    updated_at = NOW();

-- 3. CRÉER L'UTILISATEUR DANS LA TABLE USERS

INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'Sasha',
    'Rohee',
    'Sasharohee26@gmail.com',
    'technician',
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    updated_at = NOW();

-- 4. ACTIVER LA DEMANDE D'INSCRIPTION

UPDATE pending_signups 
SET status = 'approved', updated_at = NOW()
WHERE email = 'Sasharohee26@gmail.com';

-- 5. MARQUER L'EMAIL COMME UTILISÉ

UPDATE confirmation_emails 
SET status = 'used', sent_at = NOW()
WHERE user_email = 'Sasharohee26@gmail.com';

-- 6. VÉRIFIER LA CRÉATION

SELECT '=== UTILISATEUR CRÉÉ ===' as section;
SELECT 
    id,
    email,
    first_name,
    last_name,
    role,
    is_active,
    created_at
FROM simple_auth 
WHERE email = 'Sasharohee26@gmail.com';

-- 7. INSTRUCTIONS POUR L'UTILISATEUR

SELECT '=== INSTRUCTIONS DE CONNEXION ===' as section;
SELECT 
    '1. Votre compte est créé dans la table simple_auth' as etape1,
    '2. Email: Sasharohee26@gmail.com' as email,
    '3. Mot de passe: password123' as password,
    '4. Vous pouvez maintenant vous connecter' as etape4;

-- 8. FONCTION DE CONNEXION SIMPLE

CREATE OR REPLACE FUNCTION simple_login(p_email TEXT, p_password TEXT)
RETURNS JSON AS $$
DECLARE
    user_record RECORD;
BEGIN
    -- Vérifier les identifiants
    SELECT * INTO user_record FROM simple_auth 
    WHERE email = p_email AND password_hash = p_password AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Identifiants invalides'
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'user', json_build_object(
            'id', user_record.id,
            'email', user_record.email,
            'first_name', user_record.first_name,
            'last_name', user_record.last_name,
            'role', user_record.role
        ),
        'message', 'Connexion réussie'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. TESTER LA CONNEXION

SELECT '=== TEST DE CONNEXION ===' as section;
SELECT simple_login('Sasharohee26@gmail.com', 'password123') as result;

-- 10. CONFIGURER LES PERMISSIONS

GRANT ALL PRIVILEGES ON TABLE simple_auth TO authenticated;
GRANT ALL PRIVILEGES ON TABLE simple_auth TO anon;
GRANT ALL PRIVILEGES ON TABLE simple_auth TO service_role;
GRANT EXECUTE ON FUNCTION simple_login(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION simple_login(TEXT, TEXT) TO anon;

-- 11. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Table simple_auth créée' as statut1,
    '✅ Utilisateur créé dans simple_auth' as statut2,
    '✅ Utilisateur créé dans users' as statut3,
    '✅ Demande d''inscription approuvée' as statut4,
    '✅ Fonction de connexion créée' as statut5,
    '✅ Prêt pour connexion simple' as statut6;

-- 12. INSTRUCTIONS FINALES

SELECT '=== UTILISATION ===' as section;
SELECT 
    'Pour vous connecter, utilisez :' as instruction,
    'Email: Sasharohee26@gmail.com' as email,
    'Mot de passe: password123' as password,
    'Ou testez avec : SELECT simple_login(''Sasharohee26@gmail.com'', ''password123'');' as test;
