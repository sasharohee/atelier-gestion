-- 📧 DIAGNOSTIC SIMPLE DES EMAILS SUPABASE
-- Script simplifié sans références à des tables inexistantes

-- 1. DIAGNOSTIC - Vérifier les utilisateurs non confirmés
SELECT 'DIAGNOSTIC: Utilisateurs non confirmés' as info;
SELECT 
    id,
    email,
    email_confirmed_at,
    confirmation_sent_at,
    created_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- 2. DIAGNOSTIC - Vérifier tous les utilisateurs récents
SELECT 'DIAGNOSTIC: Utilisateurs récents' as info;
SELECT 
    id,
    email,
    email_confirmed_at,
    confirmation_sent_at,
    created_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmé automatiquement'
        WHEN confirmation_sent_at IS NOT NULL THEN 'Email envoyé, en attente de confirmation'
        ELSE 'Pas d''email envoyé'
    END as status_email
FROM auth.users 
ORDER BY created_at DESC
LIMIT 10;

-- 3. CRÉER UNE FONCTION QUI NE CONFIRME PAS AUTOMATIQUEMENT
CREATE OR REPLACE FUNCTION public.create_user_with_email_required(
    user_email TEXT,
    user_password TEXT,
    first_name TEXT DEFAULT 'Utilisateur',
    last_name TEXT DEFAULT '',
    user_role TEXT DEFAULT 'technician'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    result JSON;
    confirmation_token TEXT;
BEGIN
    -- Vérifier que l'email n'existe pas déjà
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = user_email) THEN
        result := json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un compte avec cet email existe déjà. Veuillez vous connecter.'
        );
        RETURN result;
    END IF;
    
    -- Générer un UUID pour l'utilisateur
    new_user_id := gen_random_uuid();
    
    -- Générer un token de confirmation
    confirmation_token := encode(gen_random_bytes(32), 'hex');
    
    -- Insérer dans auth.users SANS confirmer l'email
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
        NULL, -- Email PAS confirmé - nécessitera validation
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        json_build_object('firstName', first_name, 'lastName', last_name, 'role', user_role),
        false,
        'authenticated',
        'authenticated',
        confirmation_token,
        NOW()
    );
    
    -- Créer l'utilisateur dans public.users
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
        first_name,
        last_name,
        user_email,
        user_role,
        NOW(),
        NOW()
    );
    
    -- Retourner le résultat
    result := json_build_object(
        'success', true,
        'user_id', new_user_id,
        'email', user_email,
        'message', 'Utilisateur créé avec succès. Email de confirmation requis.',
        'confirmation_sent', false,
        'needs_email_confirmation', true,
        'confirmation_token', confirmation_token
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
        );
        RETURN result;
END;
$$;

-- 4. TEST DE LA NOUVELLE FONCTION
SELECT 'TEST: Test de la fonction avec email requis' as info;
SELECT public.create_user_with_email_required(
    'test-email@yopmail.com',
    'motdepasse123',
    'Test',
    'Email',
    'technician'
) as test_result;

-- 5. VÉRIFICATION - L'utilisateur test doit être non confirmé
SELECT 'VÉRIFICATION: Utilisateur test non confirmé' as info;
SELECT 
    id,
    email,
    email_confirmed_at,
    confirmation_sent_at,
    created_at
FROM auth.users 
WHERE email = 'test-email@yopmail.com';

-- 6. NETTOYAGE - Supprimer l'utilisateur test
DELETE FROM auth.users WHERE email = 'test-email@yopmail.com';
DELETE FROM public.users WHERE email = 'test-email@yopmail.com';

-- 7. MESSAGE FINAL
SELECT '✅ Diagnostic terminé - Fonction avec email requis créée' as status;
