-- Script de vérification des fonctions RPC
-- Ce script vérifie qu'il n'y a plus d'ambiguïté dans les fonctions

-- 1. Lister toutes les fonctions create_user_default_data
SELECT 
    routine_name,
    specific_name,
    routine_type,
    data_type as return_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'create_user_default_data'
AND routine_schema = 'public'
ORDER BY specific_name;

-- 2. Vérifier les permissions sur les fonctions
SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name = 'create_user_default_data'
AND routine_schema = 'public'
ORDER BY grantee, privilege_type;

-- 3. Tester l'appel de la fonction avec un utilisateur existant
DO $$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Récupérer un utilisateur existant
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Test avec l''utilisateur: %', test_user_id;
        
        -- Appeler la fonction avec un cast explicite
        rpc_result := create_user_default_data(test_user_id::UUID);
        
        RAISE NOTICE 'Résultat: %', rpc_result;
        
        IF (rpc_result->>'success')::boolean THEN
            RAISE NOTICE '✅ Test réussi: %', rpc_result->>'message';
        ELSE
            RAISE NOTICE '❌ Test échoué: %', rpc_result->>'error';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour le test';
    END IF;
END $$;

-- 4. Vérifier les tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('subscription_status', 'system_settings')
AND table_schema = 'public';

-- 5. Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('subscription_status', 'system_settings')
ORDER BY tablename, policyname;
