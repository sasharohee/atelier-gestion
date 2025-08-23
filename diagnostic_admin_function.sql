-- Script de diagnostic pour la fonction create_admin_user_auto
-- Exécutez ce script pour vérifier si la fonction existe et fonctionne

-- 1. Vérifier si la fonction existe
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'create_admin_user_auto';

-- 2. Vérifier les permissions de la fonction
SELECT 
    routine_name,
    routine_type,
    security_type,
    is_deterministic
FROM information_schema.routines 
WHERE routine_name = 'create_admin_user_auto';

-- 3. Vérifier si la table users existe et sa structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 4. Vérifier les politiques RLS sur la table users
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
WHERE tablename = 'users';

-- 5. Tester la fonction avec un email de test
-- (Commentez cette ligne si vous ne voulez pas créer d'utilisateur de test)
-- SELECT create_admin_user_auto('test.admin@example.com', 'Test', 'Admin');

-- 6. Vérifier les utilisateurs existants
SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at,
    updated_at
FROM users 
ORDER BY created_at DESC 
LIMIT 10;

-- 7. Vérifier les logs d'erreur récents (si disponibles)
-- Cette requête peut ne pas fonctionner selon les permissions
SELECT 
    log_time,
    user_name,
    database_name,
    session_id,
    command_tag,
    message
FROM pg_stat_activity 
WHERE state = 'active' 
AND query LIKE '%create_admin_user_auto%';

-- 8. Vérifier les fonctions RPC disponibles
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
AND routine_name LIKE '%admin%' OR routine_name LIKE '%user%'
ORDER BY routine_name;

-- 9. Vérifier les permissions de l'utilisateur actuel
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'users';

-- 10. Vérifier les permissions sur les fonctions
SELECT 
    grantee,
    routine_name,
    privilege_type
FROM information_schema.role_routine_grants 
WHERE routine_name = 'create_admin_user_auto';
