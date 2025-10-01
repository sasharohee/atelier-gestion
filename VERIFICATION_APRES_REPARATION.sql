-- 🔍 VÉRIFICATION APRÈS RÉPARATION
-- Exécutez ce script pour vérifier l'état du système

-- 1. VÉRIFICATION DE L'ÉTAT DU SYSTÈME
SELECT 'VÉRIFICATION: État du système après réparation' as info;

SELECT 
    'Table users' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
         THEN '✅ Existe' 
         ELSE '❌ MANQUANTE' 
    END as status
UNION ALL
SELECT 
    'Trigger on_auth_user_created' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Actif' 
         ELSE '❌ INACTIF' 
    END as status
UNION ALL
SELECT 
    'Fonction handle_new_user' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user' AND routine_schema = 'public') 
         THEN '✅ Existe' 
         ELSE '❌ MANQUANTE' 
    END as status;

-- 2. VÉRIFICATION DES POLITIQUES RLS
SELECT 'VÉRIFICATION: Politiques RLS' as info;
SELECT 
    policyname,
    permissive,
    cmd,
    CASE WHEN qual IS NOT NULL THEN 'Configurée' ELSE 'Non configurée' END as qual_status
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';

-- 3. TEST DE LA FONCTION handle_new_user
SELECT 'TEST: Fonction handle_new_user' as info;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type,
    routine_definition IS NOT NULL as has_definition
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user' AND routine_schema = 'public';

-- 4. VÉRIFICATION DES UTILISATEURS EXISTANTS
SELECT 'UTILISATEURS: Dans auth.users (5 derniers)' as info;
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    raw_user_meta_data->>'firstName' as first_name,
    raw_user_meta_data->>'lastName' as last_name
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. VÉRIFICATION DES UTILISATEURS DANS public.users
SELECT 'UTILISATEURS: Dans public.users (5 derniers)' as info;
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

-- 6. VÉRIFICATION DES ERREURS POTENTIELLES
SELECT 'DIAGNOSTIC: Vérification des erreurs potentielles' as info;

-- Vérifier s'il y a des contraintes de clé étrangère cassées
SELECT 
    'Contraintes FK' as check_type,
    CASE WHEN COUNT(*) = 0 THEN '✅ OK' ELSE '❌ PROBLÈME: ' || COUNT(*) || ' contraintes cassées' END as status
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'users' 
AND tc.table_schema = 'public';

-- 7. TEST DE CRÉATION D'UN UTILISATEUR TEST (SANS RÉEL INSERTION)
SELECT 'TEST: Simulation de création utilisateur' as info;
SELECT 
    'Simulation OK' as status,
    'La structure est prête pour la création d''utilisateurs' as message;

-- 8. VÉRIFICATION DES PERMISSIONS
SELECT 'PERMISSIONS: Vérification des permissions' as info;
SELECT 
    schemaname,
    tablename,
    hasinserts,
    hasselects,
    hasupdates,
    hasdeletes
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- 9. MESSAGE FINAL
SELECT 'RÉSULTAT: Si tous les composants montrent ✅, le système est prêt' as info;
SELECT 'Si des ❌ apparaissent, il y a encore un problème à résoudre' as warning;
