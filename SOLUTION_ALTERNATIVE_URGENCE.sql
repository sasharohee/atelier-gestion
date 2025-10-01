-- 🚨 SOLUTION ALTERNATIVE D'URGENCE
-- Si l'erreur 500 persiste après la réparation, utilisez cette solution

-- 1. DÉSACTIVER TEMPORAIREMENT LE TRIGGER
SELECT 'URGENCE: Désactivation temporaire du trigger...' as info;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. CRÉER UNE FONCTION D'INSCRIPTION ALTERNATIVE
SELECT 'URGENCE: Création d''une fonction d''inscription alternative...' as info;
CREATE OR REPLACE FUNCTION public.signup_user_alternative(
    user_email TEXT,
    user_password TEXT,
    user_first_name TEXT DEFAULT 'Utilisateur',
    user_last_name TEXT DEFAULT '',
    user_role TEXT DEFAULT 'technician'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    result JSON;
BEGIN
    -- Générer un UUID
    new_user_id := gen_random_uuid();
    
    -- Insérer dans auth.users avec gestion d'erreur
    BEGIN
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            role,
            aud,
            confirmation_token,
            confirmation_sent_at
        ) VALUES (
            new_user_id,
            '00000000-0000-0000-0000-000000000000',
            user_email,
            crypt(user_password, gen_salt('bf')),
            NULL, -- Email non confirmé par défaut
            NOW(),
            NOW(),
            '{"provider": "email", "providers": ["email"]}',
            json_build_object('firstName', user_first_name, 'lastName', user_last_name, 'role', user_role),
            false,
            'authenticated',
            'authenticated',
            encode(gen_random_bytes(32), 'hex'),
            NOW()
        );
        
        -- Insérer dans public.users
        INSERT INTO public.users (
            id,
            first_name,
            last_name,
            email,
            role,
            created_at,
            updated_at
        ) VALUES (
            new_user_id,
            user_first_name,
            user_last_name,
            user_email,
            user_role,
            NOW(),
            NOW()
        );
        
        result := json_build_object(
            'success', true,
            'user_id', new_user_id,
            'email', user_email,
            'message', 'Utilisateur créé avec succès (méthode alternative)',
            'needs_email_confirmation', true
        );
        
    EXCEPTION
        WHEN unique_violation THEN
            result := json_build_object(
                'success', false,
                'error', 'Email déjà utilisé',
                'message', 'Un compte avec cet email existe déjà'
            );
        WHEN OTHERS THEN
            result := json_build_object(
                'success', false,
                'error', SQLERRM,
                'message', 'Erreur lors de la création: ' || SQLERRM
            );
    END;
    
    RETURN result;
END;
$$;

-- 3. CRÉER UNE FONCTION DE CONNEXION ALTERNATIVE
SELECT 'URGENCE: Création d''une fonction de connexion alternative...' as info;
CREATE OR REPLACE FUNCTION public.login_user_alternative(
    user_email TEXT,
    user_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
    result JSON;
BEGIN
    -- Vérifier les identifiants
    SELECT * INTO user_record
    FROM auth.users 
    WHERE email = user_email 
    AND encrypted_password = crypt(user_password, encrypted_password);
    
    IF NOT FOUND THEN
        result := json_build_object(
            'success', false,
            'error', 'Identifiants incorrects',
            'message', 'Email ou mot de passe incorrect'
        );
    ELSE
        result := json_build_object(
            'success', true,
            'user_id', user_record.id,
            'email', user_record.email,
            'message', 'Connexion réussie',
            'email_confirmed', user_record.email_confirmed_at IS NOT NULL
        );
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erreur lors de la connexion: ' || SQLERRM
        );
        RETURN result;
END;
$$;

-- 4. TEST DE LA FONCTION ALTERNATIVE
SELECT 'TEST: Test de la fonction d''inscription alternative...' as info;
SELECT public.signup_user_alternative(
    'test-alternative@example.com',
    'TestPass123!',
    'Test',
    'Alternative',
    'technician'
) as test_result;

-- 5. VÉRIFICATION QUE L'UTILISATEUR TEST A ÉTÉ CRÉÉ
SELECT 'VÉRIFICATION: Utilisateur test créé' as info;
SELECT 
    id,
    email,
    first_name,
    last_name,
    role,
    created_at
FROM public.users 
WHERE email = 'test-alternative@example.com';

-- 6. NETTOYAGE DU TEST
SELECT 'NETTOYAGE: Suppression de l''utilisateur test...' as info;
DELETE FROM auth.users WHERE email = 'test-alternative@example.com';
DELETE FROM public.users WHERE email = 'test-alternative@example.com';

-- 7. MESSAGE FINAL
SELECT '✅ SOLUTION ALTERNATIVE CRÉÉE' as status;
SELECT 'Vous pouvez maintenant utiliser les fonctions signup_user_alternative et login_user_alternative' as message;
SELECT 'Ces fonctions contournent les problèmes de trigger et utilisent une approche directe' as note;
