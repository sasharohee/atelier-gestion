-- Solution de contournement pour l'inscription
-- Date: 2024-01-24
-- Si l'inscription Supabase Auth ne fonctionne pas, cette solution permet de créer des utilisateurs manuellement

-- ========================================
-- 1. CRÉER UNE FONCTION POUR CRÉER DES UTILISATEURS MANUELLEMENT
-- ========================================

CREATE OR REPLACE FUNCTION create_user_manually(
    p_email TEXT,
    p_password TEXT,
    p_first_name TEXT DEFAULT 'Utilisateur',
    p_last_name TEXT DEFAULT 'Test',
    p_role TEXT DEFAULT 'technician'
)
RETURNS JSON AS $$
DECLARE
    user_id UUID;
    is_admin BOOLEAN;
    user_role TEXT;
    result JSON;
BEGIN
    -- Vérifier si l'email existe déjà
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un utilisateur avec cet email existe déjà'
        );
    END IF;
    
    -- Déterminer le rôle
    is_admin := (p_email = 'srohee32@gmail.com' OR p_email = 'repphonereparation@gmail.com');
    user_role := CASE WHEN is_admin THEN 'admin' ELSE p_role END;
    
    -- Créer l'utilisateur dans auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        p_email,
        crypt(p_password, gen_salt('bf')),
        NOW(),
        NULL,
        NULL,
        '{"provider": "email", "providers": ["email"]}',
        '{"first_name": "' || p_first_name || '", "last_name": "' || p_last_name || '"}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    ) RETURNING id INTO user_id;
    
    -- Créer l'entrée dans public.users
    INSERT INTO public.users (id, email, role)
    VALUES (user_id, p_email, user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Créer l'entrée dans subscription_status
    INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, role)
    VALUES (user_id, p_first_name, p_last_name, p_email, true, user_role)
    ON CONFLICT (user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        is_active = EXCLUDED.is_active,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'message', 'Utilisateur créé avec succès',
        'user_id', user_id,
        'email', p_email,
        'role', user_role,
        'is_admin', is_admin
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 2. CRÉER UNE FONCTION POUR TESTER L'INSCRIPTION
-- ========================================

CREATE OR REPLACE FUNCTION test_signup_process()
RETURNS JSON AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now()) || '@example.com';
    result JSON;
BEGIN
    -- Tester la création d'un utilisateur
    SELECT create_user_manually(
        test_email,
        'password123',
        'Test',
        'User',
        'technician'
    ) INTO result;
    
    RETURN json_build_object(
        'test_email', test_email,
        'result', result
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 3. CRÉER UNE FONCTION POUR LISTER LES UTILISATEURS
-- ========================================

CREATE OR REPLACE FUNCTION list_all_users()
RETURNS JSON AS $$
DECLARE
    users_data JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', u.id,
            'email', u.email,
            'role', u.role,
            'created_at', u.created_at,
            'subscription_status', ss.is_active,
            'subscription_role', ss.role
        )
    ) INTO users_data
    FROM public.users u
    LEFT JOIN subscription_status ss ON u.id = ss.user_id
    ORDER BY u.created_at DESC;
    
    RETURN json_build_object(
        'success', true,
        'users', COALESCE(users_data, '[]'::json),
        'count', (SELECT COUNT(*) FROM public.users)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 4. CRÉER UNE FONCTION POUR SUPPRIMER UN UTILISATEUR
-- ========================================

CREATE OR REPLACE FUNCTION delete_user_manually(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    user_email TEXT;
BEGIN
    -- Récupérer l'email avant suppression
    SELECT email INTO user_email FROM public.users WHERE id = p_user_id;
    
    IF user_email IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé'
        );
    END IF;
    
    -- Supprimer de auth.users (cascade supprimera les autres tables)
    DELETE FROM auth.users WHERE id = p_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Utilisateur supprimé avec succès',
        'deleted_email', user_email
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la suppression: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 5. TESTER LE SYSTÈME
-- ========================================

-- Tester la création d'un utilisateur
SELECT test_signup_process() as test_result;

-- Lister tous les utilisateurs
SELECT list_all_users() as users_list;

-- ========================================
-- 6. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 SOLUTION DE CONTOURNEMENT CRÉÉE !';
    RAISE NOTICE '✅ Fonction create_user_manually créée';
    RAISE NOTICE '✅ Fonction test_signup_process créée';
    RAISE NOTICE '✅ Fonction list_all_users créée';
    RAISE NOTICE '✅ Fonction delete_user_manually créée';
    RAISE NOTICE '';
    RAISE NOTICE '📋 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- create_user_manually(email, password, first_name, last_name, role)';
    RAISE NOTICE '- test_signup_process()';
    RAISE NOTICE '- list_all_users()';
    RAISE NOTICE '- delete_user_manually(user_id)';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 UTILISATION:';
    RAISE NOTICE '1. Utilisez create_user_manually pour créer des utilisateurs';
    RAISE NOTICE '2. Utilisez test_signup_process pour tester le système';
    RAISE NOTICE '3. Utilisez list_all_users pour voir tous les utilisateurs';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ NOTE: Cette solution contourne Supabase Auth';
    RAISE NOTICE '   Les utilisateurs créés pourront se connecter normalement.';
END $$;
