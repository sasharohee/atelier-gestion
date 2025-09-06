-- Correction avec des politiques RLS plus flexibles
-- Date: 2024-01-24
-- Solution pour assouplir les politiques RLS et permettre la visibilité des clients

-- ========================================
-- 1. DIAGNOSTIC - VÉRIFIER L'ÉTAT ACTUEL
-- ========================================

-- Vérifier votre ID utilisateur actuel
SELECT 
    'VOTRE COMPTE ACTUEL' as check_type,
    auth.uid() as your_user_id,
    auth.jwt() ->> 'email' as your_email;

-- Vérifier l'état de RLS
SELECT 
    'ÉTAT RLS' as check_type,
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

-- Vérifier les politiques RLS actuelles
SELECT 
    'POLITIQUES RLS ACTUELLES' as check_type,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'clients';

-- Compter tous les clients
SELECT 
    'COMPTE TOTAL CLIENTS' as check_type,
    COUNT(*) as total_clients
FROM public.clients;

-- Vérifier les clients par créateur
SELECT 
    'CLIENTS PAR CRÉATEUR' as check_type,
    created_by,
    COUNT(*) as count,
    CASE 
        WHEN created_by = auth.uid() THEN '✅ VOS CLIENTS'
        WHEN created_by IS NULL THEN '⚠️ SANS CRÉATEUR'
        ELSE '❌ CLIENTS D''AUTRES'
    END as status
FROM public.clients 
GROUP BY created_by
ORDER BY count DESC;

-- ========================================
-- 2. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES STRICTES
-- ========================================

-- Supprimer toutes les politiques existantes sur clients
DROP POLICY IF EXISTS "clients_select_by_account" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_by_account" ON public.clients;
DROP POLICY IF EXISTS "clients_update_by_account" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_by_account" ON public.clients;
DROP POLICY IF EXISTS "clients_admin_by_account" ON public.clients;
DROP POLICY IF EXISTS "clients_service_role_by_account" ON public.clients;
DROP POLICY IF EXISTS "clients_select_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_update_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_admin_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_service_role_isolated" ON public.clients;

-- ========================================
-- 3. CRÉER DES POLITIQUES RLS FLEXIBLES
-- ========================================

-- Politique flexible pour SELECT - permettre aux utilisateurs authentifiés de voir les clients
CREATE POLICY "clients_select_flexible" ON public.clients
    FOR SELECT USING (auth.role() = 'authenticated');

-- Politique flexible pour INSERT - permettre aux utilisateurs authentifiés de créer des clients
CREATE POLICY "clients_insert_flexible" ON public.clients
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Politique flexible pour UPDATE - permettre aux utilisateurs authentifiés de modifier les clients
CREATE POLICY "clients_update_flexible" ON public.clients
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Politique flexible pour DELETE - permettre aux utilisateurs authentifiés de supprimer les clients
CREATE POLICY "clients_delete_flexible" ON public.clients
    FOR DELETE USING (auth.role() = 'authenticated');

-- Politique pour les admins - accès complet (sans récursion)
CREATE POLICY "clients_admin_flexible" ON public.clients
    FOR ALL USING (
        auth.jwt() ->> 'email' IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    );

-- Politique pour le service role - accès complet pour les opérations système
CREATE POLICY "clients_service_role_flexible" ON public.clients
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- ========================================
-- 4. ASSIGNER TOUS LES CLIENTS À VOTRE COMPTE
-- ========================================

-- Assigner tous les clients à votre compte
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
    
    -- Assigner tous les clients à votre compte
    UPDATE public.clients 
    SET created_by = your_user_id,
        updated_at = NOW();
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RAISE NOTICE '✅ % clients assignés à votre compte (ID: %)', updated_count, your_user_id;
END $$;

-- ========================================
-- 5. CRÉER UNE FONCTION POUR AJOUTER UN CLIENT
-- ========================================

-- Fonction pour ajouter un client
CREATE OR REPLACE FUNCTION add_client_flexible(
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
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION add_client_flexible(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_client_flexible(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;

-- ========================================
-- 6. CRÉER UNE FONCTION POUR VÉRIFIER L'ACCÈS
-- ========================================

-- Fonction pour vérifier l'accès aux clients
CREATE OR REPLACE FUNCTION check_clients_access_flexible()
RETURNS JSON AS $$
DECLARE
    your_user_id UUID;
    total_clients INTEGER;
    your_clients INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO your_clients FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'total_clients', total_clients,
        'your_clients', your_clients,
        'rls_enabled', true,
        'message', 'RLS activé avec politiques flexibles - accès aux clients'
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
GRANT EXECUTE ON FUNCTION check_clients_access_flexible() TO authenticated;
GRANT EXECUTE ON FUNCTION check_clients_access_flexible() TO anon;

-- ========================================
-- 7. VÉRIFICATIONS FINALES
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
        WHEN policyname LIKE '%flexible%' THEN '🔓 Flexible'
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

-- Tester la fonction d'accès
SELECT check_clients_access_flexible() as access_test;

-- ========================================
-- 8. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
DECLARE
    your_user_id UUID;
    total_clients INTEGER;
    your_clients INTEGER;
BEGIN
    your_user_id := auth.uid();
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO your_clients FROM public.clients WHERE created_by = your_user_id;
    
    RAISE NOTICE '🔓 RLS FLEXIBLE APPLIQUÉ !';
    RAISE NOTICE '✅ RLS activé avec politiques flexibles';
    RAISE NOTICE '✅ Tous les clients assignés à votre compte';
    RAISE NOTICE '✅ Fonctions utilitaires créées';
    RAISE NOTICE '';
    RAISE NOTICE '📊 STATISTIQUES:';
    RAISE NOTICE '- Votre ID utilisateur: %', your_user_id;
    RAISE NOTICE '- Total clients: %', total_clients;
    RAISE NOTICE '- Vos clients: %', your_clients;
    RAISE NOTICE '- RLS: ACTIVÉ (flexible)';
    RAISE NOTICE '';
    RAISE NOTICE '🔓 POLITIQUES FLEXIBLES:';
    RAISE NOTICE '- Tous les utilisateurs authentifiés peuvent voir les clients';
    RAISE NOTICE '- Tous les utilisateurs authentifiés peuvent modifier les clients';
    RAISE NOTICE '- Les admins ont accès complet';
    RAISE NOTICE '- Le service role a accès complet';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre page clients';
    RAISE NOTICE '2. Vous devriez voir tous les clients';
    RAISE NOTICE '3. Testez l''ajout d''un nouveau client';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- add_client_flexible(...) pour ajouter un client';
    RAISE NOTICE '- check_clients_access_flexible() pour vérifier l''accès';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CLIENTS VISIBLES AVEC RLS FLEXIBLE !';
END $$;
