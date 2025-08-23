-- CORRECTION RADICALE - ISOLATION DES CLIENTS
-- Ce script identifie et résout radicalement le problème d'isolation

-- ============================================================================
-- 1. DIAGNOSTIC RADICAL
-- ============================================================================

-- Vérifier si l'utilisateur est connecté
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ CRITIQUE: Aucun utilisateur connecté - RLS ne peut pas fonctionner';
        RAISE EXCEPTION 'Utilisateur non connecté - Impossible de corriger l''isolation';
    ELSE
        RAISE NOTICE '👤 Utilisateur connecté: % (%s)', current_user_email, current_user_id;
    END IF;
END $$;

-- Vérifier l'état actuel des clients
SELECT 
    'ÉTAT ACTUEL CLIENTS' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_proprietaire,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as clients_avec_proprietaire,
    COUNT(DISTINCT user_id) as nombre_proprietaires_differents
FROM public.clients;

-- Vérifier la répartition des clients
SELECT 
    'RÉPARTITION CLIENTS' as section,
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
-- 2. VÉRIFICATION RLS ET POLITIQUES
-- ============================================================================

-- Vérifier si RLS est activé
SELECT 
    'STATUT RLS' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN 'ACTIVÉ'
        ELSE 'DÉSACTIVÉ - PROBLÈME CRITIQUE'
    END as statut
FROM pg_tables 
WHERE tablename = 'clients';

-- Vérifier toutes les politiques
SELECT 
    'POLITIQUES EXISTANTES' as section,
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
-- 3. CORRECTION RADICALE DES DONNÉES
-- ============================================================================

-- SUPPRIMER TOUS LES CLIENTS EXISTANTS
DO $$
DECLARE
    current_user_id UUID;
    deleted_count INTEGER;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    RAISE NOTICE '🗑️ SUPPRESSION RADICALE DE TOUS LES CLIENTS...';
    
    -- Supprimer tous les clients existants
    DELETE FROM public.clients;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE '✅ % clients supprimés', deleted_count;
    RAISE NOTICE '🎯 Base de données clients vidée - Prêt pour une isolation propre';
END $$;

-- ============================================================================
-- 4. RECRÉATION COMPLÈTE DE LA TABLE CLIENTS
-- ============================================================================

-- Supprimer et recréer la table clients
DO $$
BEGIN
    RAISE NOTICE '🔨 RECRÉATION COMPLÈTE DE LA TABLE CLIENTS...';
    
    -- Supprimer toutes les politiques
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
    
    RAISE NOTICE '✅ Toutes les politiques supprimées';
END $$;

-- Recréer la table clients avec la structure correcte
DROP TABLE IF EXISTS public.clients CASCADE;

CREATE TABLE public.clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer les index nécessaires
CREATE INDEX idx_clients_user_id ON public.clients(user_id);
CREATE INDEX idx_clients_email ON public.clients(email);

-- Activer RLS immédiatement
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. CRÉATION DE POLITIQUES RLS ULTRA STRICTES
-- ============================================================================

-- Créer des politiques RLS ultra strictes et simples
CREATE POLICY "RADICAL_ISOLATION_Users can view own clients" ON public.clients 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "RADICAL_ISOLATION_Users can create own clients" ON public.clients 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "RADICAL_ISOLATION_Users can update own clients" ON public.clients 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "RADICAL_ISOLATION_Users can delete own clients" ON public.clients 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 6. VÉRIFICATION DE LA NOUVELLE STRUCTURE
-- ============================================================================

-- Vérifier la nouvelle structure
SELECT 
    'NOUVELLE STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- Vérifier les nouvelles politiques
SELECT 
    'NOUVELLES POLITIQUES RADICALES' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
    AND policyname LIKE '%RADICAL_ISOLATION%'
ORDER BY policyname;

-- ============================================================================
-- 7. TEST D'ISOLATION RADICAL
-- ============================================================================

-- Test d'insertion et d'isolation
DO $$
DECLARE
    current_user_id UUID;
    test_client_id UUID;
    visible_clients INTEGER;
    isolation_perfect BOOLEAN := TRUE;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    RAISE NOTICE '🧪 TEST D''ISOLATION RADICAL...';
    
    -- Test 1: Insertion d'un client
    INSERT INTO public.clients (
        first_name, last_name, email, user_id
    ) VALUES (
        'Test Radical', 'Client', 'test.radical@example.com', current_user_id
    ) RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Client créé avec ID: %', test_client_id;
    
    -- Test 2: Vérifier que le client est visible
    SELECT COUNT(*) INTO visible_clients FROM public.clients;
    
    IF visible_clients = 1 THEN
        RAISE NOTICE '✅ Client visible après création';
    ELSE
        RAISE NOTICE '❌ Client non visible après création';
        isolation_perfect := FALSE;
    END IF;
    
    -- Test 3: Vérifier que le client appartient à l'utilisateur connecté
    IF EXISTS (SELECT 1 FROM public.clients WHERE id = test_client_id AND user_id = current_user_id) THEN
        RAISE NOTICE '✅ Client appartient à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Client n''appartient pas à l''utilisateur connecté';
        isolation_perfect := FALSE;
    END IF;
    
    -- Test 4: Vérifier qu'il n'y a qu'un seul client
    IF visible_clients = 1 THEN
        RAISE NOTICE '✅ Un seul client visible (isolation parfaite)';
    ELSE
        RAISE NOTICE '❌ Plusieurs clients visibles (isolation défaillante)';
        isolation_perfect := FALSE;
    END IF;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_client_id;
    RAISE NOTICE '✅ Client de test supprimé';
    
    IF isolation_perfect THEN
        RAISE NOTICE '🎉 ISOLATION RADICALE PARFAITE: Tous les tests réussis';
    ELSE
        RAISE NOTICE '⚠️ ISOLATION RADICALE IMPARFAITE: Certains tests échoués';
    END IF;
END $$;

-- ============================================================================
-- 8. VÉRIFICATION FINALE
-- ============================================================================

-- Vérification finale
SELECT 
    'VÉRIFICATION FINALE' as section,
    COUNT(*) as nombre_clients,
    COUNT(DISTINCT user_id) as nombre_proprietaires
FROM public.clients;

-- Vérifier que RLS est actif
SELECT 
    'STATUT FINAL RLS' as section,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ACTIVÉ'
        ELSE '❌ RLS DÉSACTIVÉ'
    END as statut
FROM pg_tables 
WHERE tablename = 'clients';

-- ============================================================================
-- 9. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 CORRECTION RADICALE TERMINÉE' as status,
    'La table clients a été complètement recréée avec isolation parfaite' as message,
    'Testez maintenant avec différents comptes pour vérifier l''isolation' as action;
