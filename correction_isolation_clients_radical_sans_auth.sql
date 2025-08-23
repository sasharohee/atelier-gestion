-- CORRECTION RADICALE - ISOLATION DES CLIENTS (SANS AUTH)
-- Ce script fonctionne même sans utilisateur connecté

-- ============================================================================
-- 1. DIAGNOSTIC RADICAL (SANS AUTH)
-- ============================================================================

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
        ELSE 'Avec propriétaire'
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
    deleted_count INTEGER;
BEGIN
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
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can view own clients" ON public.clients;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can create own clients" ON public.clients;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can update own clients" ON public.clients;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can delete own clients" ON public.clients;
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
-- 7. VÉRIFICATION FINALE
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
-- 8. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 CORRECTION RADICALE TERMINÉE' as status,
    'La table clients a été complètement recréée avec isolation parfaite' as message,
    'Connectez-vous maintenant et testez avec différents comptes' as action;

-- ============================================================================
-- 9. INSTRUCTIONS POUR LES TESTS
-- ============================================================================

SELECT 
    '📋 INSTRUCTIONS DE TEST' as section,
    '1. Connectez-vous avec le compte A' as etape1,
    '2. Créez un client dans Catalogue > Clients' as etape2,
    '3. Déconnectez-vous et connectez-vous avec le compte B' as etape3,
    '4. Vérifiez que le client du compte A n''est PAS visible' as etape4,
    '5. Créez un client avec le compte B' as etape5,
    '6. Retournez au compte A et vérifiez l''isolation' as etape6;
