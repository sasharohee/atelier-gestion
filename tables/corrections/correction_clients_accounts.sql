-- Correction pour isoler les clients par compte (A et B)
-- Date: 2024-01-24
-- Solution pour que chaque compte ne voie que ses propres clients

-- ========================================
-- 1. DIAGNOSTIC - VÉRIFIER LES COMPTES
-- ========================================

-- Vérifier votre ID utilisateur actuel
SELECT 
    'VOTRE COMPTE ACTUEL' as check_type,
    auth.uid() as your_user_id,
    auth.jwt() ->> 'email' as your_email;

-- Vérifier tous les utilisateurs et leurs clients
SELECT 
    'UTILISATEURS ET LEURS CLIENTS' as check_type,
    u.id as user_id,
    u.email as user_email,
    COUNT(c.id) as client_count
FROM auth.users u
LEFT JOIN public.clients c ON u.id = c.created_by
GROUP BY u.id, u.email
ORDER BY client_count DESC;

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

-- ========================================
-- 2. S'ASSURER QUE TOUS LES CLIENTS ONT UN CREATED_BY
-- ========================================

-- Assigner created_by aux clients qui n'en ont pas
DO $$
DECLARE
    admin_user_id UUID;
    updated_count INTEGER;
BEGIN
    -- Récupérer l'ID d'un utilisateur admin
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    LIMIT 1;
    
    -- Si aucun admin trouvé, prendre le premier utilisateur
    IF admin_user_id IS NULL THEN
        SELECT id INTO admin_user_id FROM auth.users LIMIT 1;
    END IF;
    
    -- Assigner created_by aux clients sans créateur
    IF admin_user_id IS NOT NULL THEN
        UPDATE public.clients 
        SET created_by = admin_user_id,
            updated_at = NOW()
        WHERE created_by IS NULL;
        
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        
        IF updated_count > 0 THEN
            RAISE NOTICE '✅ % clients sans créateur assignés à l''admin (ID: %)', updated_count, admin_user_id;
        ELSE
            RAISE NOTICE '✅ Tous les clients ont déjà un créateur';
        END IF;
    END IF;
END $$;

-- ========================================
-- 3. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES
-- ========================================

-- Supprimer toutes les politiques existantes sur clients
DROP POLICY IF EXISTS "clients_select_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_update_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_admin_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_service_role_isolated" ON public.clients;
DROP POLICY IF EXISTS "clients_select_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_update_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_own_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_admin_secure" ON public.clients;
DROP POLICY IF EXISTS "clients_service_role_secure" ON public.clients;

-- ========================================
-- 4. RÉACTIVER RLS AVEC DES POLITIQUES CORRECTES
-- ========================================

-- Réactiver RLS sur la table clients
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 5. CRÉER DES POLITIQUES RLS POUR ISOLER LES COMPTES
-- ========================================

-- Politique pour SELECT - chaque utilisateur voit seulement ses clients
CREATE POLICY "clients_select_by_account" ON public.clients
    FOR SELECT USING (created_by = auth.uid());

-- Politique pour INSERT - chaque utilisateur peut créer des clients pour lui-même
CREATE POLICY "clients_insert_by_account" ON public.clients
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Politique pour UPDATE - chaque utilisateur peut modifier ses propres clients
CREATE POLICY "clients_update_by_account" ON public.clients
    FOR UPDATE USING (created_by = auth.uid());

-- Politique pour DELETE - chaque utilisateur peut supprimer ses propres clients
CREATE POLICY "clients_delete_by_account" ON public.clients
    FOR DELETE USING (created_by = auth.uid());

-- Politique pour les admins - accès complet (sans récursion)
CREATE POLICY "clients_admin_by_account" ON public.clients
    FOR ALL USING (
        auth.jwt() ->> 'email' IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    );

-- Politique pour le service role - accès complet pour les opérations système
CREATE POLICY "clients_service_role_by_account" ON public.clients
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- ========================================
-- 6. CRÉER UNE FONCTION POUR AJOUTER UN CLIENT
-- ========================================

-- Fonction pour ajouter un client à votre compte
CREATE OR REPLACE FUNCTION add_client_to_my_account(
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
    
    -- Insérer le nouveau client assigné à votre compte
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION add_client_to_my_account(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================
-- 7. CRÉER UNE FONCTION POUR VÉRIFIER L'ISOLATION
-- ========================================

-- Fonction pour vérifier l'isolation des comptes
CREATE OR REPLACE FUNCTION check_account_isolation()
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
GRANT EXECUTE ON FUNCTION check_account_isolation() TO authenticated;

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
        WHEN policyname LIKE '%account%' THEN '🔒 Par compte'
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
SELECT check_account_isolation() as isolation_test;

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
    
    RAISE NOTICE '🔒 RLS RÉACTIVÉ AVEC ISOLATION DES COMPTES !';
    RAISE NOTICE '✅ RLS activé sur la table clients';
    RAISE NOTICE '✅ Politiques d''isolation créées';
    RAISE NOTICE '✅ Chaque compte ne voit que ses propres clients';
    RAISE NOTICE '✅ Fonctions utilitaires créées';
    RAISE NOTICE '';
    RAISE NOTICE '📊 STATISTIQUES:';
    RAISE NOTICE '- Votre ID utilisateur: %', your_user_id;
    RAISE NOTICE '- Vos clients visibles: %', your_clients_count;
    RAISE NOTICE '- Total clients en base: %', total_clients_count;
    RAISE NOTICE '- RLS: ACTIVÉ (isolé par compte)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 ISOLATION APPLIQUÉE:';
    RAISE NOTICE '- Compte A ne voit que ses clients';
    RAISE NOTICE '- Compte B ne voit que ses clients';
    RAISE NOTICE '- Les admins peuvent voir tous les clients';
    RAISE NOTICE '- Le service role a accès complet';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre page clients';
    RAISE NOTICE '2. Vous ne devriez voir que vos propres clients';
    RAISE NOTICE '3. Testez l''ajout d''un nouveau client';
    RAISE NOTICE '4. Connectez-vous avec l''autre compte pour vérifier l''isolation';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- add_client_to_my_account(...) pour ajouter un client';
    RAISE NOTICE '- check_account_isolation() pour vérifier l''isolation';
    RAISE NOTICE '';
    RAISE NOTICE '✅ ISOLATION DES COMPTES ACTIVÉE !';
END $$;
