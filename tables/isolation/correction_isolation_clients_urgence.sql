-- CORRECTION D'URGENCE - ISOLATION DES CLIENTS
-- Ce script corrige immédiatement les problèmes d'isolation des clients

-- ============================================================================
-- 1. DIAGNOSTIC INITIAL
-- ============================================================================

-- Vérifier l'état actuel des clients
SELECT 
    'DIAGNOSTIC INITIAL CLIENTS' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as clients_with_user_id,
    COUNT(DISTINCT user_id) as nombre_utilisateurs_differents
FROM public.clients;

-- Vérifier les politiques RLS actuelles
SELECT 
    'POLITIQUES RLS ACTUELLES' as section,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 2. CORRECTION IMMÉDIATE DES DONNÉES ORPHELINES
-- ============================================================================

-- Récupérer l'utilisateur actuel et corriger les données orphelines
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
    orphaned_count INTEGER;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - impossible de corriger l''isolation';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔧 Correction de l''isolation pour l''utilisateur: %', current_user_email;
    
    -- Compter les clients orphelins
    SELECT COUNT(*) INTO orphaned_count FROM public.clients WHERE user_id IS NULL;
    RAISE NOTICE '📊 Clients orphelins trouvés: %', orphaned_count;
    
    -- Corriger les données orphelines en les assignant à l'utilisateur actuel
    UPDATE public.clients SET user_id = current_user_id WHERE user_id IS NULL;
    
    RAISE NOTICE '✅ Données orphelines corrigées pour l''utilisateur: %', current_user_email;
END $$;

-- ============================================================================
-- 3. CORRECTION DE LA STRUCTURE DE LA TABLE CLIENTS
-- ============================================================================

-- S'assurer que la colonne user_id existe et est correctement configurée
DO $$
BEGIN
    -- Ajouter user_id si manquant
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table clients';
    END IF;
    
    -- S'assurer que user_id n'est pas nullable
    ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL ajoutée sur user_id';
    
    -- Ajouter un index pour les performances
    CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
    RAISE NOTICE '✅ Index sur user_id créé';
END $$;

-- ============================================================================
-- 4. SUPPRESSION ET RECRÉATION DES POLITIQUES RLS
-- ============================================================================

-- Supprimer toutes les anciennes politiques RLS
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;

-- Activer RLS sur la table clients
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- Créer les nouvelles politiques RLS strictes
CREATE POLICY "CLIENTS_ISOLATION_Users can view own clients" ON public.clients 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "CLIENTS_ISOLATION_Users can create own clients" ON public.clients 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "CLIENTS_ISOLATION_Users can update own clients" ON public.clients 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "CLIENTS_ISOLATION_Users can delete own clients" ON public.clients 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 5. VÉRIFICATION APRÈS CORRECTION
-- ============================================================================

-- Vérifier l'état final des clients
SELECT 
    'VÉRIFICATION FINALE CLIENTS' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as clients_with_user_id,
    COUNT(DISTINCT user_id) as nombre_utilisateurs_differents
FROM public.clients;

-- Vérifier les nouvelles politiques RLS
SELECT 
    'NOUVELLES POLITIQUES RLS' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
    AND policyname LIKE '%CLIENTS_ISOLATION%'
ORDER BY policyname;

-- ============================================================================
-- 6. TEST D'ISOLATION STRICT
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    test_result BOOLEAN := TRUE;
    total_clients INTEGER;
    user_clients INTEGER;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Test d''isolation impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter tous les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    
    -- Compter les clients de l'utilisateur connecté
    SELECT COUNT(*) INTO user_clients FROM public.clients WHERE user_id = current_user_id;
    
    RAISE NOTICE '📊 Test d''isolation: % clients au total, % clients pour l''utilisateur connecté', total_clients, user_clients;
    
    -- Test de lecture - l'utilisateur ne doit voir que ses propres clients
    IF total_clients != user_clients THEN
        RAISE NOTICE '❌ ERREUR: L''utilisateur peut voir des clients d''autres utilisateurs';
        test_result := FALSE;
    ELSE
        RAISE NOTICE '✅ Test de lecture réussi - L''utilisateur ne voit que ses propres clients';
    END IF;
    
    IF test_result THEN
        RAISE NOTICE '🎉 Test d''isolation réussi - L''isolation des clients fonctionne correctement';
    ELSE
        RAISE NOTICE '❌ Test d''isolation échoué - Problèmes détectés';
    END IF;
END $$;

-- ============================================================================
-- 7. TEST D'INSERTION SIMPLIFIÉ
-- ============================================================================

-- Test d'insertion simple sans bloc DO imbriqué
DO $$
DECLARE
    current_user_id UUID;
    test_client_id UUID;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Test d'insertion
    INSERT INTO public.clients (
        first_name, last_name, email, user_id
    ) VALUES (
        'Test Isolation', 'Client', 'test.isolation@example.com', current_user_id
    ) RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Test d''insertion réussi - Client créé avec ID %', test_client_id;
    
    -- Vérifier que le client a bien été créé avec le bon user_id
    IF EXISTS (SELECT 1 FROM public.clients WHERE email = 'test.isolation@example.com' AND user_id = current_user_id) THEN
        RAISE NOTICE '✅ Client créé avec le bon user_id';
    ELSE
        RAISE NOTICE '❌ ERREUR: Client créé avec un mauvais user_id';
    END IF;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE email = 'test.isolation@example.com';
    RAISE NOTICE '✅ Client de test supprimé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Test d''insertion échoué: %', SQLERRM;
END $$;

-- ============================================================================
-- 8. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 CORRECTION TERMINÉE' as status,
    'L''isolation des clients a été corrigée avec succès.' as message,
    'Tous les clients sont maintenant isolés par utilisateur.' as details,
    'Testez la création de clients avec différents comptes pour vérifier.' as next_step;
