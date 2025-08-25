-- Diagnostic des permissions pour l'erreur 500
-- Date: 2024-01-24

-- 1. DIAGNOSTIC DES PERMISSIONS SUR AUTH.USERS

-- Vérifier les permissions sur auth.users
SELECT 
    'Permissions auth.users' as check_type,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_schema = 'auth' 
AND table_name = 'users'
ORDER BY grantee, privilege_type;

-- 2. VÉRIFIER LES TRIGGERS SUR AUTH.USERS

-- Lister tous les triggers sur auth.users
SELECT 
    'Triggers auth.users' as check_type,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users';

-- 3. VÉRIFIER LES CONTRAINTES SUR AUTH.USERS

-- Lister toutes les contraintes sur auth.users
SELECT 
    'Contraintes auth.users' as check_type,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_schema = 'auth' 
AND table_name = 'users';

-- 4. VÉRIFIER LES POLITIQUES RLS SUR AUTH.USERS

-- Lister toutes les politiques sur auth.users
SELECT 
    'Politiques RLS auth.users' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'auth' 
AND tablename = 'users';

-- 5. VÉRIFIER LES FONCTIONS QUI PEUVENT INTERFÉRER

-- Lister toutes les fonctions qui pourraient interférer avec l'inscription
SELECT 
    'Fonctions interférentes' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%user%' 
     OR routine_name LIKE '%auth%' 
     OR routine_name LIKE '%signup%'
     OR routine_name LIKE '%insert%'
     OR routine_name LIKE '%create%')
ORDER BY routine_name;

-- 6. VÉRIFIER LES TRIGGERS SUR LES TABLES PUBLIQUES

-- Lister tous les triggers sur les tables publiques qui pourraient interférer
SELECT 
    'Triggers publics interférents' as check_type,
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public' 
AND (event_object_table = 'users' 
     OR action_statement LIKE '%auth%' 
     OR action_statement LIKE '%user%'
     OR action_statement LIKE '%insert%');

-- 7. VÉRIFIER LES CONTRAINTES DE CLÉ ÉTRANGÈRE

-- Lister toutes les contraintes de clé étrangère vers auth.users
SELECT 
    'Clés étrangères vers auth.users' as check_type,
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

-- 8. VÉRIFIER LES SÉQUENCES ET INDEX

-- Vérifier les séquences liées à auth.users
SELECT 
    'Séquences auth.users' as check_type,
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
CREATE OR REPLACE FUNCTION test_auth_insert_permissions()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_user_id UUID := gen_random_uuid();
BEGIN
    -- Test 1: Vérifier l'accès en lecture à auth.users
    IF EXISTS (SELECT 1 FROM auth.users LIMIT 1) THEN
        RETURN QUERY SELECT 'Lecture auth.users'::TEXT, 'OK'::TEXT, 'Lecture possible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Lecture auth.users'::TEXT, 'ERREUR'::TEXT, 'Lecture impossible'::TEXT;
    END IF;

    -- Test 2: Vérifier les permissions d'insertion (cela peut échouer, c'est normal)
    BEGIN
        -- Essayer d'insérer dans auth.users (cela va probablement échouer)
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
        VALUES (test_user_id, test_email, 'test_password', now(), now(), now());
        
        RETURN QUERY SELECT 'Insertion auth.users'::TEXT, 'OK'::TEXT, 'Insertion possible (inattendu)'::TEXT;
        
        -- Nettoyer si l'insertion a réussi
        DELETE FROM auth.users WHERE id = test_user_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Insertion auth.users'::TEXT, 'ATTENDU'::TEXT, 'Insertion bloquée: ' || SQLERRM::TEXT;
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

    -- Test 6: Vérifier les fonctions personnalisées
    IF EXISTS (SELECT 1 FROM information_schema.routines 
               WHERE routine_schema = 'public' 
               AND (routine_name LIKE '%user%' OR routine_name LIKE '%auth%' OR routine_name LIKE '%signup%')) THEN
        RETURN QUERY SELECT 'Fonctions personnalisées'::TEXT, 'ATTENTION'::TEXT, 'Fonctions personnalisées présentes - peuvent interférer'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonctions personnalisées'::TEXT, 'OK'::TEXT, 'Aucune fonction personnalisée problématique'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 10. EXÉCUTER LE DIAGNOSTIC

-- Exécuter tous les tests
SELECT * FROM test_auth_insert_permissions();

-- 11. RÉSUMÉ DES PROBLÈMES POTENTIELS

-- Créer un résumé des problèmes identifiés
SELECT 
    'RÉSUMÉ' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers 
                    WHERE event_object_schema = 'auth' AND event_object_table = 'users') 
        THEN 'Triggers sur auth.users détectés'
        ELSE 'Aucun trigger sur auth.users'
    END as triggers_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.table_constraints 
                    WHERE table_schema = 'auth' AND table_name = 'users' AND constraint_type = 'CHECK') 
        THEN 'Contraintes CHECK sur auth.users détectées'
        ELSE 'Aucune contrainte CHECK sur auth.users'
    END as constraints_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies 
                    WHERE schemaname = 'auth' AND tablename = 'users') 
        THEN 'Politiques RLS sur auth.users détectées'
        ELSE 'Aucune politique RLS sur auth.users'
    END as rls_status;

-- 12. MESSAGE DE CONFIRMATION

SELECT 'Diagnostic des permissions terminé - Vérifiez les résultats ci-dessus' as status;
