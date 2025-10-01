-- 🚨 DIAGNOSTIC RAPIDE - Erreur 500 Signup
-- Exécutez ce script dans la console SQL Supabase pour diagnostiquer le problème

-- 1. VÉRIFICATION DE BASE
SELECT 'DIAGNOSTIC RAPIDE - Système d''authentification' as info;

-- Vérifier l'état des composants
SELECT 
    'Table users' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
         THEN '✅ Existe' 
         ELSE '❌ MANQUANTE - C''est le problème !' 
    END as status
UNION ALL
SELECT 
    'Trigger on_auth_user_created' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Actif' 
         ELSE '❌ INACTIF - C''est le problème !' 
    END as status
UNION ALL
SELECT 
    'Fonction handle_new_user' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user' AND routine_schema = 'public') 
         THEN '✅ Existe' 
         ELSE '❌ MANQUANTE - C''est le problème !' 
    END as status;

-- 2. VÉRIFICATION DES UTILISATEURS EXISTANTS
SELECT 'Utilisateurs dans auth.users (5 derniers)' as info;
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. VÉRIFICATION DES UTILISATEURS DANS public.users
SELECT 'Utilisateurs dans public.users (5 derniers)' as info;
SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. VÉRIFICATION DES POLITIQUES RLS
SELECT 'Politiques RLS sur la table users' as info;
SELECT 
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';

-- 5. VÉRIFICATION DES ERREURS RÉCENTES
SELECT 'Erreurs récentes dans les logs (si disponibles)' as info;
-- Note: Les logs détaillés ne sont pas toujours accessibles via SQL

-- 6. SOLUTION IMMÉDIATE SI PROBLÈME DÉTECTÉ
-- Si la table users ou le trigger manque, exécutez le script de réparation :

SELECT 'SOLUTION: Si des composants manquent, exécutez CREATE_AUTH_SYSTEM_CLEAN.sql' as action;
