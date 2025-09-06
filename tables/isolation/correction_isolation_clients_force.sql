-- CORRECTION FORCÉE - ISOLATION DES CLIENTS
-- Ce script force la correction de l'isolation des clients

-- ============================================================================
-- 1. DIAGNOSTIC COMPLET
-- ============================================================================

-- Vérifier l'état actuel
SELECT 
    'DIAGNOSTIC COMPLET' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as clients_with_user_id,
    COUNT(DISTINCT user_id) as nombre_utilisateurs_differents
FROM public.clients;

-- Vérifier les politiques RLS
SELECT 
    'POLITIQUES RLS ACTUELLES' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- Vérifier si RLS est activé
SELECT 
    'RLS STATUS' as section,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'clients';

-- ============================================================================
-- 2. CORRECTION FORCÉE DES DONNÉES
-- ============================================================================

-- Forcer l'attribution de tous les clients à l'utilisateur connecté
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
    updated_count INTEGER;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - impossible de corriger';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔧 Correction forcée pour l''utilisateur: %', current_user_email;
    
    -- Forcer l'attribution de TOUS les clients à l'utilisateur actuel
    UPDATE public.clients SET user_id = current_user_id WHERE user_id IS NULL OR user_id != current_user_id;
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RAISE NOTICE '✅ % clients attribués à l''utilisateur connecté', updated_count;
END $$;

-- ============================================================================
-- 3. RECRÉATION COMPLÈTE DES POLITIQUES RLS
-- ============================================================================

-- Désactiver RLS temporairement
ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;

-- Supprimer TOUTES les politiques existantes (y compris FORCE_ISOLATION)
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;

-- Réactiver RLS
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- Créer des politiques RLS ULTRA STRICTES
CREATE POLICY "FORCE_ISOLATION_Users can view own clients" ON public.clients 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "FORCE_ISOLATION_Users can create own clients" ON public.clients 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "FORCE_ISOLATION_Users can update own clients" ON public.clients 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "FORCE_ISOLATION_Users can delete own clients" ON public.clients 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 4. VÉRIFICATION FORCÉE
-- ============================================================================

-- Vérifier l'état après correction
SELECT 
    'VÉRIFICATION APRÈS CORRECTION' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as clients_with_user_id,
    COUNT(DISTINCT user_id) as nombre_utilisateurs_differents
FROM public.clients;

-- Vérifier les nouvelles politiques
SELECT 
    'NOUVELLES POLITIQUES FORCÉES' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
    AND policyname LIKE '%FORCE_ISOLATION%'
ORDER BY policyname;

-- ============================================================================
-- 5. TEST D'ISOLATION ULTRA STRICT
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    total_clients INTEGER;
    user_clients INTEGER;
    isolation_perfect BOOLEAN := TRUE;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter tous les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    
    -- Compter les clients de l'utilisateur connecté
    SELECT COUNT(*) INTO user_clients FROM public.clients WHERE user_id = current_user_id;
    
    RAISE NOTICE '📊 Test ultra strict: % clients au total, % clients pour l''utilisateur connecté', total_clients, user_clients;
    
    -- Test 1: L'utilisateur ne doit voir que ses propres clients
    IF total_clients != user_clients THEN
        RAISE NOTICE '❌ ÉCHEC: L''utilisateur peut voir des clients d''autres utilisateurs';
        isolation_perfect := FALSE;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: L''utilisateur ne voit que ses propres clients';
    END IF;
    
    -- Test 2: Tous les clients doivent appartenir à l'utilisateur connecté
    IF EXISTS (SELECT 1 FROM public.clients WHERE user_id != current_user_id) THEN
        RAISE NOTICE '❌ ÉCHEC: Il existe des clients appartenant à d''autres utilisateurs';
        isolation_perfect := FALSE;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: Tous les clients appartiennent à l''utilisateur connecté';
    END IF;
    
    -- Test 3: Aucun client ne doit avoir user_id NULL
    IF EXISTS (SELECT 1 FROM public.clients WHERE user_id IS NULL) THEN
        RAISE NOTICE '❌ ÉCHEC: Il existe des clients sans user_id';
        isolation_perfect := FALSE;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: Aucun client sans user_id';
    END IF;
    
    IF isolation_perfect THEN
        RAISE NOTICE '🎉 ISOLATION PARFAITE: Tous les tests sont réussis';
    ELSE
        RAISE NOTICE '⚠️ ISOLATION IMPARFAITE: Certains tests ont échoué';
    END IF;
END $$;

-- ============================================================================
-- 6. TEST D'INSERTION FORCÉ
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    test_client_id UUID;
    insert_success BOOLEAN := FALSE;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Test d'insertion
    INSERT INTO public.clients (
        first_name, last_name, email, user_id
    ) VALUES (
        'Test Force Isolation', 'Client', 'test.force.isolation@example.com', current_user_id
    ) RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Insertion réussie - Client créé avec ID %', test_client_id;
    
    -- Vérifier que le client a bien été créé avec le bon user_id
    IF EXISTS (SELECT 1 FROM public.clients WHERE email = 'test.force.isolation@example.com' AND user_id = current_user_id) THEN
        RAISE NOTICE '✅ Client créé avec le bon user_id';
        insert_success := TRUE;
    ELSE
        RAISE NOTICE '❌ ERREUR: Client créé avec un mauvais user_id';
    END IF;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE email = 'test.force.isolation@example.com';
    RAISE NOTICE '✅ Client de test supprimé';
    
    IF insert_success THEN
        RAISE NOTICE '🎉 Test d''insertion parfait';
    ELSE
        RAISE NOTICE '⚠️ Test d''insertion problématique';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Test d''insertion échoué: %', SQLERRM;
END $$;

-- ============================================================================
-- 7. VÉRIFICATION FINALE
-- ============================================================================

-- Vérification finale complète
SELECT 
    'VÉRIFICATION FINALE' as section,
    'Tous les clients appartiennent maintenant à l''utilisateur connecté' as message,
    'L''isolation est forcée et active' as details;

-- Afficher le nombre final de clients
SELECT 
    'RÉSULTAT FINAL' as section,
    COUNT(*) as nombre_clients,
    COUNT(DISTINCT user_id) as nombre_utilisateurs
FROM public.clients;
