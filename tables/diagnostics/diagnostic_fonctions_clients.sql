-- =====================================================
-- DIAGNOSTIC FONCTIONS CLIENTS
-- =====================================================
-- Script pour diagnostiquer l'état des fonctions liées aux clients
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier les fonctions existantes
SELECT '=== FONCTIONS EXISTANTES ===' as etape;

SELECT 
    routine_name as nom_fonction,
    routine_type as type,
    data_type as type_retour,
    routine_definition as definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%client%'
ORDER BY routine_name;

-- 2. Vérifier les signatures des fonctions create_client_smart
SELECT '=== SIGNATURES FONCTION create_client_smart ===' as etape;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_identity_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as type_retour,
    p.prosrc as source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'create_client_smart'
ORDER BY p.oid;

-- 3. Vérifier les triggers sur la table clients
SELECT '=== TRIGGERS TABLE CLIENTS ===' as etape;

SELECT 
    trigger_name as nom_trigger,
    event_manipulation as evenement,
    action_timing as moment,
    action_statement as action,
    action_orientation as orientation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'clients'
ORDER BY trigger_name;

-- 4. Vérifier les fonctions utilisées par les triggers
SELECT '=== FONCTIONS DES TRIGGERS ===' as etape;

SELECT 
    t.trigger_name as nom_trigger,
    t.action_statement as action,
    p.proname as nom_fonction,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM information_schema.triggers t
JOIN pg_proc p ON t.action_statement LIKE '%' || p.proname || '%'
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE t.event_object_schema = 'public'
AND t.event_object_table = 'clients'
AND n.nspname = 'public'
ORDER BY t.trigger_name;

-- 5. Test de la fonction create_client_smart si elle existe
SELECT '=== TEST FONCTION create_client_smart ===' as etape;

DO $$
DECLARE
    v_function_exists BOOLEAN;
    v_test_result JSON;
    v_user_id UUID;
BEGIN
    -- Vérifier si la fonction existe
    SELECT EXISTS(
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'create_client_smart'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RAISE NOTICE '✅ Fonction create_client_smart existe';
        
        -- Obtenir l'utilisateur actuel
        v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
        
        -- Tester la fonction
        BEGIN
            SELECT create_client_smart(
                'Test', 'Fonction', 'test.fonction@example.com',
                '0123456789', '123 Test Street', 'Test de la fonction',
                v_user_id
            ) INTO v_test_result;
            
            RAISE NOTICE '✅ Test de la fonction réussi: %', v_test_result;
            
            -- Nettoyer le test si un client a été créé
            IF (v_test_result->>'action') = 'client_created' THEN
                DELETE FROM clients WHERE id = (v_test_result->>'client_id')::UUID;
                RAISE NOTICE '✅ Test nettoyé';
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors du test de la fonction: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '❌ Fonction create_client_smart n''existe pas';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
END $$;

-- 6. Recommandations
SELECT '=== RECOMMANDATIONS ===' as etape;

DO $$
DECLARE
    v_function_count INTEGER;
    v_trigger_count INTEGER;
BEGIN
    -- Compter les fonctions create_client_smart
    SELECT COUNT(*) INTO v_function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname = 'create_client_smart';
    
    -- Compter les triggers sur la table clients
    SELECT COUNT(*) INTO v_trigger_count
    FROM information_schema.triggers 
    WHERE event_object_schema = 'public'
    AND event_object_table = 'clients';
    
    RAISE NOTICE '📊 État actuel:';
    RAISE NOTICE '  - Fonctions create_client_smart: %', v_function_count;
    RAISE NOTICE '  - Triggers sur table clients: %', v_trigger_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions recommandées:';
    
    IF v_function_count > 1 THEN
        RAISE NOTICE '  1. Supprimer les fonctions en double:';
        RAISE NOTICE '     DROP FUNCTION IF EXISTS create_client_smart(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID);';
    END IF;
    
    IF v_function_count = 0 THEN
        RAISE NOTICE '  1. Créer la fonction create_client_smart';
    END IF;
    
    IF v_trigger_count = 0 THEN
        RAISE NOTICE '  2. Créer le trigger set_client_user_id_trigger';
    END IF;
    
    IF v_function_count = 1 AND v_trigger_count > 0 THEN
        RAISE NOTICE '  ✅ Configuration semble correcte';
    END IF;
    
END $$;
