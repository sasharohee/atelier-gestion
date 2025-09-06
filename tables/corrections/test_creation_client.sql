-- TEST DE CRÉATION DE CLIENTS
-- Ce script teste la création de clients pour vérifier que tout fonctionne

-- ============================================================================
-- 1. VÉRIFICATION DE L'UTILISATEUR CONNECTÉ
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - Test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '👤 Test avec l''utilisateur: %', current_user_email;
END $$;

-- ============================================================================
-- 2. VÉRIFICATION DE LA STRUCTURE DE LA TABLE CLIENTS
-- ============================================================================

SELECT 
    'STRUCTURE CLIENTS' as verification,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT 
    'POLITIQUES RLS CLIENTS' as verification,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 4. TEST D'INSERTION DE CLIENTS
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    test_client_id UUID;
    test_result BOOLEAN := TRUE;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test d''insertion de clients...';
    
    -- Test 1: Client avec tous les champs
    BEGIN
        INSERT INTO public.clients (
            first_name, last_name, email, phone, address, notes, user_id
        ) VALUES (
            'Test', 'Client', 'test@example.com', '0123456789', '123 Test Street', 'Client de test', current_user_id
        ) RETURNING id INTO test_client_id;
        
        RAISE NOTICE '✅ Test 1 réussi: Client créé avec ID %', test_client_id;
        
        -- Vérifier que le client est bien visible
        IF EXISTS (SELECT 1 FROM public.clients WHERE id = test_client_id AND user_id = current_user_id) THEN
            RAISE NOTICE '✅ Client visible pour l''utilisateur connecté';
        ELSE
            RAISE NOTICE '❌ Client non visible pour l''utilisateur connecté';
            test_result := FALSE;
        END IF;
        
        -- Nettoyer
        DELETE FROM public.clients WHERE id = test_client_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Test 1 échoué: %', SQLERRM;
        test_result := FALSE;
    END;
    
    -- Test 2: Client avec champs minimaux
    BEGIN
        INSERT INTO public.clients (
            first_name, last_name, email, user_id
        ) VALUES (
            'Minimal', 'Client', 'minimal@example.com', current_user_id
        ) RETURNING id INTO test_client_id;
        
        RAISE NOTICE '✅ Test 2 réussi: Client minimal créé avec ID %', test_client_id;
        
        -- Nettoyer
        DELETE FROM public.clients WHERE id = test_client_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Test 2 échoué: %', SQLERRM;
        test_result := FALSE;
    END;
    
    -- Test 3: Client avec email dupliqué (doit échouer si contrainte unique)
    BEGIN
        INSERT INTO public.clients (
            first_name, last_name, email, user_id
        ) VALUES (
            'Duplicate', 'Client', 'duplicate@example.com', current_user_id
        );
        
        INSERT INTO public.clients (
            first_name, last_name, email, user_id
        ) VALUES (
            'Duplicate2', 'Client', 'duplicate@example.com', current_user_id
        );
        
        RAISE NOTICE '⚠️ Test 3: Email dupliqué autorisé (pas de contrainte unique)';
        
        -- Nettoyer
        DELETE FROM public.clients WHERE email = 'duplicate@example.com';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '✅ Test 3: Contrainte unique sur email active - %', SQLERRM;
    END;
    
    IF test_result THEN
        RAISE NOTICE '🎉 Tous les tests d''insertion réussis';
    ELSE
        RAISE NOTICE '⚠️ Certains tests ont échoué';
    END IF;
END $$;

-- ============================================================================
-- 5. VÉRIFICATION DE L'ISOLATION
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    other_user_id UUID;
    isolation_check BOOLEAN := TRUE;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''isolation impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Créer un client de test
    INSERT INTO public.clients (
        first_name, last_name, email, user_id
    ) VALUES (
        'Isolation', 'Test', 'isolation@test.com', current_user_id
    );
    
    -- Vérifier que l'utilisateur connecté peut voir son client
    IF EXISTS (SELECT 1 FROM public.clients WHERE email = 'isolation@test.com' AND user_id = current_user_id) THEN
        RAISE NOTICE '✅ Utilisateur peut voir son propre client';
    ELSE
        RAISE NOTICE '❌ Utilisateur ne peut pas voir son propre client';
        isolation_check := FALSE;
    END IF;
    
    -- Vérifier qu'il n'y a pas de clients d'autres utilisateurs visibles
    SELECT COUNT(*) INTO other_user_id FROM public.clients WHERE user_id != current_user_id;
    IF other_user_id > 0 THEN
        RAISE NOTICE '⚠️ % clients d''autres utilisateurs visibles', other_user_id;
    ELSE
        RAISE NOTICE '✅ Aucun client d''autre utilisateur visible';
    END IF;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE email = 'isolation@test.com';
    
    IF isolation_check THEN
        RAISE NOTICE '🎉 Test d''isolation réussi';
    ELSE
        RAISE NOTICE '❌ Test d''isolation échoué';
    END IF;
END $$;

-- ============================================================================
-- 6. RÉSULTAT FINAL
-- ============================================================================

SELECT 
    '🎉 TEST TERMINÉ' as status,
    'Les tests de création de clients sont terminés.' as message,
    'Vérifiez les logs ci-dessus pour les résultats détaillés.' as details;
