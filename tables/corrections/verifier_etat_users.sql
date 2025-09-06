-- VÉRIFICATION DE L'ÉTAT ACTUEL DE LA TABLE USERS
-- Ce script permet de voir quelles politiques existent actuellement

-- 1. VÉRIFIER SI RLS EST ACTIVÉ
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 2. LISTER TOUTES LES POLITIQUES EXISTANTES
SELECT 
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

-- 3. COMPTER LE NOMBRE DE POLITIQUES
SELECT 
    'Nombre total de politiques' as info,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 4. VÉRIFIER SI LA FONCTION RPC EXISTE
SELECT 
    'Fonction RPC' as type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_users_without_rls') 
        THEN 'Existe' 
        ELSE 'N\'existe pas' 
    END as status;

-- 5. TESTER UNE REQUÊTE SIMPLE
SELECT 
    'Test requête' as test,
    COUNT(*) as user_count
FROM public.users;
