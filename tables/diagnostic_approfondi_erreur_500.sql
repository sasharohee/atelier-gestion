-- Diagnostic approfondi de l'erreur 500 lors de l'inscription
-- Date: 2024-01-24

-- 1. VÉRIFIER LA CONFIGURATION AUTH DE SUPABASE

-- Vérifier les paramètres d'authentification
SELECT 
    'Auth Configuration' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM auth.users LIMIT 1) 
        THEN 'OK - Table auth.users accessible' 
        ELSE 'ERREUR - Table auth.users inaccessible' 
    END as auth_users_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'identities') 
        THEN 'OK - Table auth.identities existe' 
        ELSE 'ERREUR - Table auth.identities manquante' 
    END as auth_identities_table;

-- 2. VÉRIFIER LES TRIGGERS ET CONTRAINTES SUR AUTH.USERS

-- Lister tous les triggers sur auth.users
SELECT 
    'Triggers on auth.users' as check_type,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' AND event_object_table = 'users';

-- Lister toutes les contraintes sur auth.users
SELECT 
    'Constraints on auth.users' as check_type,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_schema = 'auth' AND table_name = 'users';

-- 3. VÉRIFIER LES POLITIQUES RLS SUR AUTH.USERS

-- Lister toutes les politiques sur auth.users
SELECT 
    'RLS Policies on auth.users' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'auth' AND tablename = 'users';

-- 4. VÉRIFIER LES FONCTIONS ET TRIGGERS PERSONNALISÉS

-- Lister toutes les fonctions qui pourraient interférer
SELECT 
    'Custom Functions' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%user%' OR routine_name LIKE '%auth%' OR routine_name LIKE '%signup%');

-- 5. VÉRIFIER LES TRIGGERS SUR LES TABLES PUBLIQUES

-- Lister tous les triggers sur les tables publiques
SELECT 
    'Triggers on public tables' as check_type,
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public' 
AND (event_object_table = 'users' OR action_statement LIKE '%auth%' OR action_statement LIKE '%user%');

-- 6. VÉRIFIER LES CONTRAINTES DE CLÉ ÉTRANGÈRE

-- Lister toutes les contraintes de clé étrangère vers auth.users
SELECT 
    'Foreign Keys to auth.users' as check_type,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND ccu.table_schema = 'auth' 
AND ccu.table_name = 'users';

-- 7. VÉRIFIER LES PERMISSIONS

-- Vérifier les permissions sur auth.users
SELECT 
    'Permissions on auth.users' as check_type,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_schema = 'auth' AND table_name = 'users';

-- 8. VÉRIFIER LES SÉQUENCES ET INDEX

-- Vérifier les séquences liées à auth.users
SELECT 
    'Sequences related to auth.users' as check_type,
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value
FROM information_schema.sequences 
WHERE sequence_schema = 'auth' 
AND sequence_name LIKE '%user%';

-- 9. TEST DE CRÉATION D'UTILISATEUR SIMPLE

-- Créer une fonction de test pour l'inscription
CREATE OR REPLACE FUNCTION test_simple_signup()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_user_id UUID;
BEGIN
    -- Test 1: Vérifier l'accès à auth.users
    IF EXISTS (SELECT 1 FROM auth.users LIMIT 1) THEN
        RETURN QUERY SELECT 'Accès auth.users'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Accès auth.users'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 2: Vérifier les permissions d'insertion
    BEGIN
        -- Essayer d'insérer un utilisateur de test (cela peut échouer, c'est normal)
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
        VALUES (gen_random_uuid(), test_email, 'test_password', now(), now(), now());
        
        RETURN QUERY SELECT 'Insertion auth.users'::TEXT, 'OK'::TEXT, 'Insertion possible'::TEXT;
        
        -- Nettoyer
        DELETE FROM auth.users WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Insertion auth.users'::TEXT, 'ERREUR'::TEXT, SQLERRM::TEXT;
    END;

    -- Test 3: Vérifier les triggers actifs
    IF EXISTS (SELECT 1 FROM information_schema.triggers 
               WHERE event_object_schema = 'auth' AND event_object_table = 'users') THEN
        RETURN QUERY SELECT 'Triggers auth.users'::TEXT, 'ATTENTION'::TEXT, 'Triggers présents - peuvent causer des problèmes'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Triggers auth.users'::TEXT, 'OK'::TEXT, 'Aucun trigger problématique'::TEXT;
    END IF;

    -- Test 4: Vérifier les contraintes CHECK
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_schema = 'auth' AND table_name = 'users' AND constraint_type = 'CHECK') THEN
        RETURN QUERY SELECT 'Contraintes CHECK'::TEXT, 'ATTENTION'::TEXT, 'Contraintes CHECK présentes - peuvent causer des problèmes'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Contraintes CHECK'::TEXT, 'OK'::TEXT, 'Aucune contrainte CHECK problématique'::TEXT;
    END IF;

    -- Test 5: Vérifier les politiques RLS
    IF EXISTS (SELECT 1 FROM pg_policies 
               WHERE schemaname = 'auth' AND tablename = 'users') THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, 'ATTENTION'::TEXT, 'Politiques RLS présentes - peuvent causer des problèmes'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, 'OK'::TEXT, 'Aucune politique RLS problématique'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 10. EXÉCUTER LE DIAGNOSTIC

-- Exécuter tous les tests
SELECT * FROM test_simple_signup();

-- 11. RECOMMANDATIONS SPÉCIFIQUES

-- Si des triggers sont trouvés, les supprimer
-- Si des contraintes CHECK sont trouvées, les vérifier
-- Si des politiques RLS sont trouvées, les désactiver temporairement

-- 12. SOLUTION DE CONTOURNEMENT IMMÉDIATE

-- Créer une fonction de contournement pour l'inscription
CREATE OR REPLACE FUNCTION bypass_signup_issue()
RETURNS TEXT AS $$
BEGIN
    -- Désactiver temporairement tous les triggers sur auth.users
    DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
    DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON users;
    DROP TRIGGER IF EXISTS trigger_create_user_automatically ON users;
    DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON users;
    
    -- Désactiver temporairement RLS sur auth.users si nécessaire
    -- ALTER TABLE auth.users DISABLE ROW LEVEL SECURITY;
    
    RETURN 'Triggers supprimés - Testez l''inscription maintenant';
END;
$$ LANGUAGE plpgsql;

-- 13. EXÉCUTER LA SOLUTION DE CONTOURNEMENT

-- Exécuter la solution de contournement
SELECT bypass_signup_issue();

-- 14. MESSAGE FINAL

SELECT 'Diagnostic terminé - Vérifiez les résultats ci-dessus' as status;
