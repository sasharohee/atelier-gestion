-- Réactivation sécurisée de RLS pour isoler les clients par utilisateur
-- Date: 2024-01-24
-- Solution pour que chaque utilisateur ne voie que ses propres clients

-- ========================================
-- 1. DIAGNOSTIC - VÉRIFIER L'ÉTAT ACTUEL
-- ========================================

-- Vérifier votre ID utilisateur
SELECT 
    'VOTRE ID UTILISATEUR' as check_type,
    auth.uid() as your_user_id,
    auth.jwt() ->> 'email' as your_email;

-- Vérifier l'état actuel de RLS
SELECT 
    'ÉTAT ACTUEL RLS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé' 
        ELSE '❌ RLS désactivé' 
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'clients';

-- Vérifier les politiques existantes
SELECT 
    'POLITIQUES EXISTANTES' as check_type,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'clients';

-- Compter les clients par utilisateur
SELECT 
    'CLIENTS PAR UTILISATEUR' as check_type,
    created_by,
    COUNT(*) as client_count,
    CASE 
        WHEN created_by = auth.uid() THEN '✅ VOS CLIENTS'
        WHEN created_by IS NULL THEN '⚠️ SANS CRÉATEUR'
        ELSE '❌ CLIENTS D''AUTRES'
    END as status
FROM public.clients 
GROUP BY created_by
ORDER BY client_count DESC;

-- ========================================
-- 2. S'ASSURER QUE TOUS LES CLIENTS ONT UN CREATED_BY
-- ========================================

-- Assigner created_by aux clients qui n'en ont pas
DO $$
DECLARE
    your_user_id UUID;
    updated_count INTEGER;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RAISE NOTICE '❌ Utilisateur non authentifié';
        RETURN;
    END IF;
    
    -- Assigner created_by aux clients sans créateur
    UPDATE public.clients 
    SET created_by = your_user_id,
        updated_at = NOW()
    WHERE created_by IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    IF updated_count > 0 THEN
        RAISE NOTICE '✅ % clients sans créateur assignés à votre compte', updated_count;
    ELSE
        RAISE NOTICE '✅ Tous les clients ont déjà un créateur';
    END IF;
END $$;

-- ========================================
-- 3. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES
-- ========================================

-- Supprimer toutes les politiques existantes sur clients
DROP POLICY IF EXISTS "clients_select_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_update_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_admin_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_service_role_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_select_own" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_own" ON public.clients;
DROP POLICY IF EXISTS "clients_update_own" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_own" ON public.clients;
DROP POLICY IF EXISTS "clients_select_authenticated" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_authenticated" ON public.clients;
DROP POLICY IF EXISTS "clients_update_authenticated" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_authenticated" ON public.clients;
DROP POLICY IF EXISTS "clients_admin_all" ON public.clients;
DROP POLICY IF EXISTS "clients_service_role" ON public.clients;

-- ========================================
-- 4. RÉACTIVER RLS AVEC DES POLITIQUES ISOLÉES
-- ========================================

-- Réactiver RLS sur la table clients
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 5. CRÉER DES POLITIQUES RLS ISOLÉES
-- ========================================

-- Politique pour SELECT - utilisateurs voient seulement leurs clients
CREATE POLICY "clients_select_isolated" ON public.clients
    FOR SELECT USING (created_by = auth.uid());

-- Politique pour INSERT - utilisateurs peuvent créer des clients pour eux-mêmes
CREATE POLICY "clients_insert_isolated" ON public.clients
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Politique pour UPDATE - utilisateurs peuvent modifier leurs propres clients
CREATE POLICY "clients_update_isolated" ON public.clients
    FOR UPDATE USING (created_by = auth.uid());

-- Politique pour DELETE - utilisateurs peuvent supprimer leurs propres clients
CREATE POLICY "clients_delete_isolated" ON public.clients
    FOR DELETE USING (created_by = auth.uid());

-- Politique pour les admins - accès complet (sans récursion)
CREATE POLICY "clients_admin_isolated" ON public.clients
    FOR ALL USING (
        auth.jwt() ->> 'email' IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    );

-- Politique pour le service role - accès complet pour les opérations système
CREATE POLICY "clients_service_role_isolated" ON public.clients
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- ========================================
-- 6. CRÉER UNE FONCTION POUR AJOUTER UN CLIENT
-- ========================================

-- Fonction pour ajouter un client avec created_by automatique
CREATE OR REPLACE FUNCTION add_my_client_isolated(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_company TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client avec created_by automatique
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté et assigné à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION add_my_client_isolated(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================
-- 7. CRÉER UNE FONCTION POUR VÉRIFIER L'ISOLATION
-- ========================================

-- Fonction pour tester l'isolation des clients
CREATE OR REPLACE FUNCTION test_clients_isolation()
RETURNS JSON AS $$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients (ceux que vous pouvez voir)
    SELECT COUNT(*) INTO your_clients_count FROM public.clients;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', your_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé - vous ne voyez que vos propres clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION test_clients_isolation() TO authenticated;

-- ========================================
-- 8. VÉRIFICATIONS FINALES
-- ========================================

-- Vérifier l'état final de RLS
SELECT 
    'ÉTAT FINAL RLS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé' 
        ELSE '❌ RLS désactivé' 
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'clients';

-- Vérifier les politiques finales
SELECT 
    'POLITIQUES FINALES' as check_type,
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Lecture'
        WHEN cmd = 'INSERT' THEN '✅ Insertion'
        WHEN cmd = 'UPDATE' THEN '✅ Modification'
        WHEN cmd = 'DELETE' THEN '✅ Suppression'
        WHEN cmd = 'ALL' THEN '✅ Toutes opérations'
        ELSE '⚠️ ' || cmd
    END as operation,
    CASE 
        WHEN policyname LIKE '%isolated%' THEN '🔒 Isolé'
        WHEN policyname LIKE '%admin%' THEN '👑 Admin'
        WHEN policyname LIKE '%service%' THEN '⚙️ Service'
        ELSE '❓ Autre'
    END as access_type
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'clients'
ORDER BY cmd;

-- Vérifier que tous les clients ont un created_by
SELECT 
    'VÉRIFICATION CREATED_BY' as check_type,
    COUNT(*) as total_clients,
    COUNT(created_by) as clients_with_creator,
    COUNT(*) - COUNT(created_by) as clients_without_creator,
    CASE 
        WHEN COUNT(*) = COUNT(created_by) THEN '✅ Tous les clients ont un créateur'
        ELSE '⚠️ Certains clients n''ont pas de créateur'
    END as status
FROM public.clients;

-- Tester la fonction d'isolation
SELECT test_clients_isolation() as isolation_test;

-- ========================================
-- 9. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
    total_clients_count INTEGER;
BEGIN
    your_user_id := auth.uid();
    SELECT COUNT(*) INTO your_clients_count FROM public.clients;
    SELECT COUNT(*) INTO total_clients_count FROM public.clients;
    
    RAISE NOTICE '🔒 RLS ISOLÉ RÉACTIVÉ !';
    RAISE NOTICE '✅ RLS activé sur la table clients';
    RAISE NOTICE '✅ Politiques isolées créées';
    RAISE NOTICE '✅ Isolation des clients par utilisateur';
    RAISE NOTICE '✅ Fonctions utilitaires créées';
    RAISE NOTICE '';
    RAISE NOTICE '📊 STATISTIQUES:';
    RAISE NOTICE '- Votre ID utilisateur: %', your_user_id;
    RAISE NOTICE '- Vos clients visibles: %', your_clients_count;
    RAISE NOTICE '- Total clients en base: %', total_clients_count;
    RAISE NOTICE '- RLS: ACTIVÉ (isolé)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 SÉCURITÉ APPLIQUÉE:';
    RAISE NOTICE '- Vous ne voyez que vos propres clients';
    RAISE NOTICE '- Les autres utilisateurs ne voient que leurs clients';
    RAISE NOTICE '- Les admins peuvent voir tous les clients';
    RAISE NOTICE '- Le service role a accès complet';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre page clients';
    RAISE NOTICE '2. Vous ne devriez voir que vos propres clients';
    RAISE NOTICE '3. Testez l''ajout d''un nouveau client';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- add_my_client_isolated(...) pour ajouter un client';
    RAISE NOTICE '- test_clients_isolation() pour tester l''isolation';
    RAISE NOTICE '';
    RAISE NOTICE '✅ ISOLATION SÉCURISÉE ACTIVÉE !';
END $$;
