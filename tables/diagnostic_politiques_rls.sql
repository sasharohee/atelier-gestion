-- Diagnostic des politiques RLS existantes
-- Ce script aide à identifier les politiques qui existent déjà

-- 1. Vérifier les politiques existantes pour clients
SELECT 
    'Politiques clients existantes' as type,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
AND schemaname = 'public'
ORDER BY policyname;

-- 2. Vérifier les politiques existantes pour devices
SELECT 
    'Politiques devices existantes' as type,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'devices'
AND schemaname = 'public'
ORDER BY policyname;

-- 3. Vérifier toutes les politiques RLS
SELECT 
    'Toutes les politiques RLS' as type,
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4. Vérifier l'état des tables
SELECT 
    'État des tables' as type,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('clients', 'devices', 'repairs', 'users')
ORDER BY table_name;
