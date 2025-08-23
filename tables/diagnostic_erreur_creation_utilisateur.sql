-- Diagnostic de l'erreur "Database error saving new user"
-- Ce script aide à identifier la cause exacte du problème

-- 1. Vérifier l'état des triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 2. Vérifier les fonctions existantes
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%user%';

-- 3. Vérifier la structure de la table users
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Vérifier les contraintes sur la table users
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users' 
AND table_schema = 'public';

-- 5. Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 6. Vérifier les permissions
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
AND table_schema = 'public';

-- 7. Vérifier les sessions actives (si disponibles)
-- Note: Cette requête peut ne pas fonctionner selon les permissions
SELECT 
    pid,
    usename as user_name,
    datname as database_name,
    state,
    query_start,
    query
FROM pg_stat_activity 
WHERE state = 'active' 
AND query LIKE '%users%'
ORDER BY query_start DESC
LIMIT 10;

-- 8. Test de création d'utilisateur manuel
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
BEGIN
    RAISE NOTICE '🧪 Test de création d''utilisateur avec ID: %', test_user_id;
    RAISE NOTICE '📧 Email de test: %', test_email;
    
    -- Essayer d'insérer directement dans auth.users
    BEGIN
        INSERT INTO auth.users (
            id, 
            email, 
            encrypted_password, 
            email_confirmed_at, 
            created_at, 
            updated_at, 
            raw_user_meta_data
        ) VALUES (
            test_user_id,
            test_email,
            'encrypted_password',
            NOW(),
            NOW(),
            NOW(),
            '{"firstName": "Test", "lastName": "User", "role": "technician"}'::jsonb
        );
        RAISE NOTICE '✅ Insertion dans auth.users réussie';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de l''insertion dans auth.users: %', SQLERRM;
    END;
    
    -- Vérifier si l'utilisateur a été créé dans public.users
    IF EXISTS (SELECT 1 FROM public.users WHERE id = test_user_id) THEN
        RAISE NOTICE '✅ Utilisateur créé dans public.users';
    ELSE
        RAISE NOTICE '❌ Utilisateur non créé dans public.users';
    END IF;
    
    -- Vérifier si le profil a été créé
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = test_user_id) THEN
        RAISE NOTICE '✅ Profil créé dans public.user_profiles';
    ELSE
        RAISE NOTICE '❌ Profil non créé dans public.user_profiles';
    END IF;
    
    -- Vérifier si les préférences ont été créées
    IF EXISTS (SELECT 1 FROM public.user_preferences WHERE user_id = test_user_id) THEN
        RAISE NOTICE '✅ Préférences créées dans public.user_preferences';
    ELSE
        RAISE NOTICE '❌ Préférences non créées dans public.user_preferences';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM auth.users WHERE id = test_user_id;
    DELETE FROM public.users WHERE id = test_user_id;
    DELETE FROM public.user_profiles WHERE user_id = test_user_id;
    DELETE FROM public.user_preferences WHERE user_id = test_user_id;
    
    RAISE NOTICE '🧹 Test nettoyé';
END $$;

-- 9. Vérifier l'état final
SELECT 
    'Diagnostic terminé' as status,
    COUNT(*) as total_users_auth,
    (SELECT COUNT(*) FROM public.users) as total_users_public,
    (SELECT COUNT(*) FROM public.user_profiles) as total_profiles,
    (SELECT COUNT(*) FROM public.user_preferences) as total_preferences
FROM auth.users;
