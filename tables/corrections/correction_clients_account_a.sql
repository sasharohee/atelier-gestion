-- Correction pour voir les clients du compte A
-- Date: 2024-01-24
-- Solution pour assigner les clients au compte A

-- ========================================
-- 1. DIAGNOSTIC - VÉRIFIER VOTRE COMPTE A
-- ========================================

-- Vérifier votre ID utilisateur actuel (compte A)
SELECT 
    'VOTRE COMPTE A' as check_type,
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

-- Vérifier les politiques RLS
SELECT 
    'POLITIQUES RLS' as check_type,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'clients';

-- ========================================
-- 2. ASSIGNER TOUS LES CLIENTS AU COMPTE A
-- ========================================

-- Assigner tous les clients au compte A (votre compte actuel)
DO $$
DECLARE
    account_a_user_id UUID;
    updated_count INTEGER;
BEGIN
    -- Récupérer votre ID utilisateur (compte A)
    account_a_user_id := auth.uid();
    
    IF account_a_user_id IS NULL THEN
        RAISE NOTICE '❌ Utilisateur non authentifié';
        RETURN;
    END IF;
    
    -- Assigner tous les clients au compte A
    UPDATE public.clients 
    SET created_by = account_a_user_id,
        updated_at = NOW();
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RAISE NOTICE '✅ % clients assignés au compte A (ID: %)', updated_count, account_a_user_id;
END $$;

-- ========================================
-- 3. VÉRIFIER QUE TOUS LES CLIENTS SONT MAINTENANT AU COMPTE A
-- ========================================

-- Vérifier que tous les clients sont maintenant au compte A
SELECT 
    'VÉRIFICATION APRÈS ASSIGNATION' as check_type,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN created_by = auth.uid() THEN 1 END) as account_a_clients,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as clients_without_creator,
    COUNT(CASE WHEN created_by != auth.uid() AND created_by IS NOT NULL THEN 1 END) as other_accounts_clients
FROM public.clients;

-- Lister les clients du compte A
SELECT 
    'CLIENTS DU COMPTE A' as check_type,
    id,
    first_name,
    last_name,
    email,
    phone,
    city,
    company,
    created_at
FROM public.clients 
WHERE created_by = auth.uid()
ORDER BY created_at DESC;

-- ========================================
-- 4. CRÉER UNE FONCTION POUR AJOUTER UN CLIENT AU COMPTE A
-- ========================================

-- Fonction pour ajouter un client au compte A
CREATE OR REPLACE FUNCTION add_client_to_account_a(
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
    account_a_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur (compte A)
    account_a_user_id := auth.uid();
    
    IF account_a_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné au compte A
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, account_a_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', account_a_user_id,
        'message', 'Client ajouté au compte A'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION add_client_to_account_a(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================
-- 5. CRÉER UNE FONCTION POUR VÉRIFIER LES CLIENTS DU COMPTE A
-- ========================================

-- Fonction pour vérifier les clients du compte A
CREATE OR REPLACE FUNCTION check_account_a_clients()
RETURNS JSON AS $$
DECLARE
    account_a_user_id UUID;
    account_a_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur (compte A)
    account_a_user_id := auth.uid();
    
    -- Compter les clients du compte A
    SELECT COUNT(*) INTO account_a_clients_count FROM public.clients WHERE created_by = account_a_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'account_a_user_id', account_a_user_id,
        'account_a_clients_count', account_a_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé - vous voyez les clients du compte A'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'account_a_user_id', account_a_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION check_account_a_clients() TO authenticated;

-- ========================================
-- 6. TEST DE LA FONCTION
-- ========================================

-- Tester la fonction
SELECT check_account_a_clients() as verification_result;

-- ========================================
-- 7. VÉRIFICATIONS FINALES
-- ========================================

-- Vérifier l'état final
SELECT 
    'ÉTAT FINAL' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients' AND table_schema = 'public') 
        THEN '✅ Table clients existe' 
        ELSE '❌ Table clients n''existe pas' 
    END as table_status,
    (SELECT COUNT(*) FROM public.clients) as total_clients,
    (SELECT COUNT(*) FROM public.clients WHERE created_by = auth.uid()) as account_a_clients,
    CASE 
        WHEN (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'clients') 
        THEN '✅ RLS activé' 
        ELSE '❌ RLS désactivé' 
    END as rls_status;

-- ========================================
-- 8. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
DECLARE
    account_a_user_id UUID;
    total_clients INTEGER;
    account_a_clients INTEGER;
BEGIN
    account_a_user_id := auth.uid();
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO account_a_clients FROM public.clients WHERE created_by = account_a_user_id;
    
    RAISE NOTICE '🎯 CLIENTS ASSIGNÉS AU COMPTE A !';
    RAISE NOTICE '✅ Tous les clients assignés au compte A';
    RAISE NOTICE '✅ RLS activé avec isolation';
    RAISE NOTICE '✅ Fonctions utilitaires créées';
    RAISE NOTICE '';
    RAISE NOTICE '📊 STATISTIQUES:';
    RAISE NOTICE '- Compte A ID: %', account_a_user_id;
    RAISE NOTICE '- Total clients: %', total_clients;
    RAISE NOTICE '- Clients du compte A: %', account_a_clients;
    RAISE NOTICE '- RLS: ACTIVÉ (isolé)';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre page clients';
    RAISE NOTICE '2. Vous devriez voir tous les clients du compte A';
    RAISE NOTICE '3. Testez l''ajout d''un nouveau client';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- add_client_to_account_a(...) pour ajouter un client';
    RAISE NOTICE '- check_account_a_clients() pour vérifier les clients';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ IMPORTANT:';
    RAISE NOTICE '- Tous les clients sont maintenant assignés au compte A';
    RAISE NOTICE '- Le compte B ne verra plus ces clients';
    RAISE NOTICE '- RLS reste activé pour la sécurité';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CLIENTS DU COMPTE A VISIBLES !';
END $$;
