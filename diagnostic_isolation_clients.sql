-- DIAGNOSTIC COMPLET - ISOLATION DES CLIENTS
-- Ce script diagnostique pourquoi l'isolation ne fonctionne pas

-- ============================================================================
-- 1. VÉRIFICATION DE L'UTILISATEUR CONNECTÉ
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté';
    ELSE
        RAISE NOTICE '👤 Utilisateur connecté: % (%s)', current_user_email, current_user_id;
    END IF;
END $$;

-- ============================================================================
-- 2. VÉRIFICATION DE LA STRUCTURE DE LA TABLE
-- ============================================================================

SELECT 
    'STRUCTURE TABLE CLIENTS' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. VÉRIFICATION DU STATUT RLS
-- ============================================================================

SELECT 
    'STATUT RLS' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients';

-- ============================================================================
-- 4. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT 
    'POLITIQUES RLS' as section,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 5. ANALYSE DES DONNÉES
-- ============================================================================

-- Compter les clients par utilisateur
SELECT 
    'RÉPARTITION DES CLIENTS' as section,
    user_id,
    COUNT(*) as nombre_clients,
    CASE 
        WHEN user_id IS NULL THEN 'Sans propriétaire'
        WHEN user_id = auth.uid() THEN 'Utilisateur connecté'
        ELSE 'Autre utilisateur'
    END as proprietaire
FROM public.clients
GROUP BY user_id
ORDER BY nombre_clients DESC;

-- ============================================================================
-- 6. TEST D'ACCÈS DIRECT
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    total_clients INTEGER;
    user_clients INTEGER;
    other_clients INTEGER;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter tous les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    
    -- Compter les clients de l'utilisateur connecté
    SELECT COUNT(*) INTO user_clients FROM public.clients WHERE user_id = current_user_id;
    
    -- Compter les clients d'autres utilisateurs
    SELECT COUNT(*) INTO other_clients FROM public.clients WHERE user_id != current_user_id AND user_id IS NOT NULL;
    
    RAISE NOTICE '📊 Analyse des accès:';
    RAISE NOTICE '   - Total clients: %', total_clients;
    RAISE NOTICE '   - Clients de l''utilisateur connecté: %', user_clients;
    RAISE NOTICE '   - Clients d''autres utilisateurs: %', other_clients;
    RAISE NOTICE '   - Clients sans propriétaire: %', (total_clients - user_clients - other_clients);
    
    IF other_clients > 0 THEN
        RAISE NOTICE '❌ PROBLÈME: L''utilisateur peut voir % clients d''autres utilisateurs', other_clients;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: L''utilisateur ne voit que ses propres clients';
    END IF;
END $$;

-- ============================================================================
-- 7. TEST DES POLITIQUES RLS
-- ============================================================================

-- Test de lecture avec politique RLS
DO $$
DECLARE
    current_user_id UUID;
    visible_clients INTEGER;
    expected_clients INTEGER;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test des politiques impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter les clients visibles (avec RLS actif)
    SELECT COUNT(*) INTO visible_clients FROM public.clients;
    
    -- Compter les clients attendus (de l'utilisateur connecté)
    SELECT COUNT(*) INTO expected_clients FROM public.clients WHERE user_id = current_user_id;
    
    RAISE NOTICE '🔍 Test des politiques RLS:';
    RAISE NOTICE '   - Clients visibles (avec RLS): %', visible_clients;
    RAISE NOTICE '   - Clients attendus (de l''utilisateur): %', expected_clients;
    
    IF visible_clients = expected_clients THEN
        RAISE NOTICE '✅ Politiques RLS fonctionnent correctement';
    ELSE
        RAISE NOTICE '❌ Politiques RLS ne fonctionnent pas - % clients visibles au lieu de %', visible_clients, expected_clients;
    END IF;
END $$;

-- ============================================================================
-- 8. VÉRIFICATION DES PERMISSIONS
-- ============================================================================

-- Vérifier les permissions de l'utilisateur
SELECT 
    'PERMISSIONS UTILISATEUR' as section,
    grantee,
    table_name,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_name = 'clients'
    AND grantee = current_user
ORDER BY privilege_type;

-- ============================================================================
-- 9. TEST DE CRÉATION
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    test_client_id UUID;
    creation_success BOOLEAN := FALSE;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test de création impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Test de création
    BEGIN
        INSERT INTO public.clients (
            first_name, last_name, email, user_id
        ) VALUES (
            'Test Diagnostic', 'Client', 'test.diagnostic@example.com', current_user_id
        ) RETURNING id INTO test_client_id;
        
        RAISE NOTICE '✅ Création réussie - Client ID: %', test_client_id;
        creation_success := TRUE;
        
        -- Vérifier que le client est visible
        IF EXISTS (SELECT 1 FROM public.clients WHERE id = test_client_id) THEN
            RAISE NOTICE '✅ Client visible après création';
        ELSE
            RAISE NOTICE '❌ Client non visible après création';
        END IF;
        
        -- Nettoyer
        DELETE FROM public.clients WHERE id = test_client_id;
        RAISE NOTICE '✅ Client de test supprimé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la création: %', SQLERRM;
    END;
    
    IF creation_success THEN
        RAISE NOTICE '🎉 Test de création réussi';
    ELSE
        RAISE NOTICE '⚠️ Test de création échoué';
    END IF;
END $$;

-- ============================================================================
-- 10. RÉSUMÉ DU DIAGNOSTIC
-- ============================================================================

SELECT 
    'DIAGNOSTIC TERMINÉ' as section,
    'Vérifiez les résultats ci-dessus pour identifier les problèmes' as message,
    'Exécutez correction_isolation_clients_force.sql si nécessaire' as action;
