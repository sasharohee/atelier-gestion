-- DIAGNOSTIC RÉCURSION INFINIE
-- Ce script diagnostique exactement ce qui cause le problème

-- 1. VÉRIFIER L'ÉTAT DE RLS
SELECT 
    'RLS Status' as check_type,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 2. LISTER TOUTES LES POLITIQUES EXISTANTES
SELECT 
    'Politiques existantes' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public'
ORDER BY policyname;

-- 3. COMPTER LES POLITIQUES
SELECT 
    'Nombre de politiques' as check_type,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 4. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT 
    'Structure table' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. TESTER UNE REQUÊTE SIMPLE
SELECT 
    'Test requête simple' as check_type,
    COUNT(*) as user_count
FROM public.users;

-- 6. VÉRIFIER LES PERMISSIONS
SELECT 
    'Permissions' as check_type,
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
AND table_schema = 'public';
