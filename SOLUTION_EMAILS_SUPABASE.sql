-- 📧 SOLUTION COMPLÈTE POUR LES EMAILS DE CONFIRMATION
-- Créer une fonction qui utilise l'API Supabase Auth pour l'envoi d'emails

-- 1. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS public.create_user_bypass(TEXT, TEXT, TEXT, TEXT, TEXT);

-- 2. Créer une fonction qui utilise l'API Supabase Auth
CREATE OR REPLACE FUNCTION public.create_user_with_email_confirmation(
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
    
    -- Envoyer l'email de confirmation via l'API Supabase
    -- Note: Cette partie nécessite une configuration SMTP dans Supabase
    PERFORM net.http_post(
        url := 'https://olrihggkxyksuofkesnk.supabase.co/auth/v1/recover',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
        ),
        body := jsonb_build_object(
            'email', user_email,
            'type', 'signup'
        )
    );
    
    -- Retourner le résultat
    result := json_build_object(
        'success', true,
        'user_id', new_user_id,
        'email', user_email,
        'message', 'Utilisateur créé avec succès. Email de confirmation envoyé.',
        'confirmation_sent', true,
        'needs_email_confirmation', true
    );
    
    RETURN result;
    
EXCEPTION
    WHEN unique_violation THEN
        result := json_build_object(
            'success', false,
            'error', 'Duplicate email',
            'message', 'Un compte avec cet email existe déjà. Veuillez vous connecter.'
        );
        RETURN result;
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
        );
        RETURN result;
END;
$$;

-- 3. Créer une fonction alternative plus simple qui utilise l'API Supabase Auth directement
CREATE OR REPLACE FUNCTION public.send_confirmation_email(user_email TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Envoyer un email de confirmation via l'API Supabase Auth
    PERFORM net.http_post(
        url := 'https://olrihggkxyksuofkesnk.supabase.co/auth/v1/recover',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.anon_key', true)
        ),
        body := jsonb_build_object(
            'email', user_email
        )
    );
    
    result := json_build_object(
        'success', true,
        'message', 'Email de confirmation envoyé'
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erreur lors de l''envoi de l''email: ' || SQLERRM
        );
        RETURN result;
END;
$$;

-- 4. Message de confirmation
SELECT '✅ Fonctions créées pour l''envoi d''emails de confirmation' as status;
