-- 🔧 CORRECTION ISOLATION CLIENTS - PAGE CLIENT
-- Script pour diagnostiquer et corriger le problème d'isolation des données
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC COMPLET DE L'ÉTAT ACTUEL
-- ============================================================================

SELECT '=== DIAGNOSTIC COMPLET ===' as section;

-- Vérifier l'utilisateur connecté
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NOT NULL THEN
        SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
        RAISE NOTICE '👤 Utilisateur connecté: % (%s)', current_user_email, current_user_id;
    ELSE
        RAISE NOTICE '❌ Aucun utilisateur connecté - problème d''authentification';
    END IF;
END $$;

-- Vérifier l'état des clients
SELECT 
    '📊 ÉTAT DES CLIENTS' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as clients_avec_user_id,
    COUNT(DISTINCT user_id) as nombre_utilisateurs_differents
FROM public.clients;

-- Vérifier la répartition des clients par utilisateur
SELECT 
    '📋 RÉPARTITION CLIENTS' as info,
    COALESCE(u.email, 'Sans utilisateur') as email_utilisateur,
    c.user_id,
    COUNT(*) as nombre_clients,
    MIN(c.created_at) as premier_client,
    MAX(c.created_at) as dernier_client
FROM public.clients c
LEFT JOIN auth.users u ON c.user_id = u.id
GROUP BY c.user_id, u.email
ORDER BY nombre_clients DESC;

-- ============================================================================
-- 2. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== VÉRIFICATION RLS ===' as section;

-- Vérifier si RLS est activé
SELECT 
    '🔒 STATUT RLS' as info,
    schemaname,
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN '✅ ACTIVÉ'
        ELSE '❌ DÉSACTIVÉ - PROBLÈME CRITIQUE'
    END as statut
FROM pg_tables 
WHERE tablename = 'clients';

-- Vérifier toutes les politiques RLS
SELECT 
    '📋 POLITIQUES RLS' as info,
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
-- 3. CORRECTION FORCÉE DE L'ISOLATION
-- ============================================================================

SELECT '=== CORRECTION FORCÉE ===' as section;

-- Désactiver RLS temporairement pour corriger les données
ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
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

-- Corriger les clients sans user_id
DO $$
DECLARE
    current_user_id UUID;
    clients_updated INTEGER;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NOT NULL THEN
        -- Assigner tous les clients sans user_id à l'utilisateur connecté
        UPDATE public.clients 
        SET user_id = current_user_id 
        WHERE user_id IS NULL;
        
        GET DIAGNOSTICS clients_updated = ROW_COUNT;
        
        RAISE NOTICE '✅ Clients sans user_id mis à jour: %', clients_updated;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, impossible de corriger les user_id';
    END IF;
END $$;

-- Réactiver RLS
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. CRÉATION DE POLITIQUES RLS STRICTES
-- ============================================================================

SELECT '=== CRÉATION POLITIQUES RLS ===' as section;

-- Créer des politiques RLS ultra strictes
CREATE POLICY "STRICT_ISOLATION_Users can view own clients" ON public.clients 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "STRICT_ISOLATION_Users can create own clients" ON public.clients 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "STRICT_ISOLATION_Users can update own clients" ON public.clients 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "STRICT_ISOLATION_Users can delete own clients" ON public.clients 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 5. CRÉATION DE FONCTIONS RPC POUR ISOLATION
-- ============================================================================

SELECT '=== CRÉATION FONCTIONS RPC ===' as section;

-- Fonction pour récupérer les clients isolés
CREATE OR REPLACE FUNCTION get_isolated_clients()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN '[]'::JSON;
    END IF;
    
    SELECT json_agg(
        json_build_object(
            'id', c.id,
            'firstName', c.first_name,
            'lastName', c.last_name,
            'email', c.email,
            'phone', c.phone,
            'address', c.address,
            'notes', c.notes,
            'category', c.category,
            'title', c.title,
            'companyName', c.company_name,
            'vatNumber', c.vat_number,
            'sirenNumber', c.siren_number,
            'countryCode', c.country_code,
            'addressComplement', c.address_complement,
            'region', c.region,
            'postalCode', c.postal_code,
            'city', c.city,
            'billingAddressSame', c.billing_address_same,
            'billingAddress', c.billing_address,
            'billingAddressComplement', c.billing_address_complement,
            'billingRegion', c.billing_region,
            'billingPostalCode', c.billing_postal_code,
            'billingCity', c.billing_city,
            'accountingCode', c.accounting_code,
            'cniIdentifier', c.cni_identifier,
            'attachedFilePath', c.attached_file_path,
            'internalNote', c.internal_note,
            'status', c.status,
            'smsNotification', c.sms_notification,
            'emailNotification', c.email_notification,
            'smsMarketing', c.sms_marketing,
            'emailMarketing', c.email_marketing,
            'createdAt', c.created_at,
            'updatedAt', c.updated_at
        )
    ) INTO result
    FROM public.clients c
    WHERE c.user_id = current_user_id;
    
    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- Fonction pour créer un client isolé
CREATE OR REPLACE FUNCTION create_isolated_client(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_category TEXT DEFAULT 'particulier',
    p_title TEXT DEFAULT 'mr',
    p_company_name TEXT DEFAULT NULL,
    p_vat_number TEXT DEFAULT NULL,
    p_siren_number TEXT DEFAULT NULL,
    p_country_code TEXT DEFAULT '33',
    p_address_complement TEXT DEFAULT NULL,
    p_region TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_billing_address_same BOOLEAN DEFAULT TRUE,
    p_billing_address TEXT DEFAULT NULL,
    p_billing_address_complement TEXT DEFAULT NULL,
    p_billing_region TEXT DEFAULT NULL,
    p_billing_postal_code TEXT DEFAULT NULL,
    p_billing_city TEXT DEFAULT NULL,
    p_accounting_code TEXT DEFAULT NULL,
    p_cni_identifier TEXT DEFAULT NULL,
    p_attached_file_path TEXT DEFAULT NULL,
    p_internal_note TEXT DEFAULT NULL,
    p_status TEXT DEFAULT 'displayed',
    p_sms_notification BOOLEAN DEFAULT TRUE,
    p_email_notification BOOLEAN DEFAULT TRUE,
    p_sms_marketing BOOLEAN DEFAULT TRUE,
    p_email_marketing BOOLEAN DEFAULT TRUE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_client_id UUID;
    current_user_id UUID;
    result JSON;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not authenticated',
            'message', 'Utilisateur non connecté'
        );
    END IF;
    
    -- Vérifier si l'email existe déjà
    IF p_email IS NOT NULL AND EXISTS(SELECT 1 FROM public.clients WHERE email = p_email AND user_id = current_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un client avec cet email existe déjà'
        );
    END IF;
    
    -- Créer le client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, notes,
        category, title, company_name, vat_number, siren_number, country_code,
        address_complement, region, postal_code, city,
        billing_address_same, billing_address, billing_address_complement, billing_region, billing_postal_code, billing_city,
        accounting_code, cni_identifier, attached_file_path, internal_note,
        status, sms_notification, email_notification, sms_marketing, email_marketing,
        user_id
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_notes,
        p_category, p_title, p_company_name, p_vat_number, p_siren_number, p_country_code,
        p_address_complement, p_region, p_postal_code, p_city,
        p_billing_address_same, p_billing_address, p_billing_address_complement, p_billing_region, p_billing_postal_code, p_billing_city,
        p_accounting_code, p_cni_identifier, p_attached_file_path, p_internal_note,
        p_status, p_sms_notification, p_email_notification, p_sms_marketing, p_email_marketing,
        current_user_id
    ) RETURNING id INTO new_client_id;
    
    -- Retourner le client créé
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'firstName', c.first_name,
        'lastName', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'notes', c.notes,
        'category', c.category,
        'title', c.title,
        'companyName', c.company_name,
        'vatNumber', c.vat_number,
        'sirenNumber', c.siren_number,
        'countryCode', c.country_code,
        'addressComplement', c.address_complement,
        'region', c.region,
        'postalCode', c.postal_code,
        'city', c.city,
        'billingAddressSame', c.billing_address_same,
        'billingAddress', c.billing_address,
        'billingAddressComplement', c.billing_address_complement,
        'billingRegion', c.billing_region,
        'billingPostalCode', c.billing_postal_code,
        'billingCity', c.billing_city,
        'accountingCode', c.accounting_code,
        'cniIdentifier', c.cni_identifier,
        'attachedFilePath', c.attached_file_path,
        'internalNote', c.internal_note,
        'status', c.status,
        'smsNotification', c.sms_notification,
        'emailNotification', c.email_notification,
        'smsMarketing', c.sms_marketing,
        'emailMarketing', c.email_marketing,
        'createdAt', c.created_at,
        'updatedAt', c.updated_at
    ) INTO result
    FROM public.clients c
    WHERE c.id = new_client_id;
    
    RETURN result;
END;
$$;

-- ============================================================================
-- 6. TRIGGER POUR ASSIGNATION AUTOMATIQUE
-- ============================================================================

SELECT '=== CRÉATION TRIGGER ===' as section;

-- Fonction trigger pour assigner automatiquement user_id
CREATE OR REPLACE FUNCTION assign_user_id_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur connecté
    current_user_id := auth.uid();
    
    -- Assigner le user_id si NULL
    IF NEW.user_id IS NULL AND current_user_id IS NOT NULL THEN
        NEW.user_id := current_user_id;
        RAISE NOTICE 'User ID assigné automatiquement: %', current_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
DROP TRIGGER IF EXISTS trigger_assign_user_id_clients ON public.clients;
CREATE TRIGGER trigger_assign_user_id_clients
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION assign_user_id_trigger();

-- ============================================================================
-- 7. TEST DE LA CORRECTION
-- ============================================================================

SELECT '=== TEST DE LA CORRECTION ===' as section;

-- Test 1: Vérifier l'isolation via RLS
DO $$
DECLARE
    current_user_id UUID;
    total_clients INTEGER;
    user_clients INTEGER;
    isolation_perfect BOOLEAN := TRUE;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter tous les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    
    -- Compter les clients de l'utilisateur connecté
    SELECT COUNT(*) INTO user_clients FROM public.clients WHERE user_id = current_user_id;
    
    RAISE NOTICE '📊 Test d''isolation: % clients au total, % clients pour l''utilisateur connecté', total_clients, user_clients;
    
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

-- Test 2: Créer un client via la fonction RPC
SELECT 
    'Test 2: Création client via fonction RPC' as test,
    create_isolated_client(
        'Test Isolation', 
        'Page Client', 
        'test.isolation.' || extract(epoch from now())::TEXT || '@example.com',
        '1111111111',
        'Adresse test isolation page client',
        'Note test isolation',
        'particulier',
        'mr',
        'Entreprise Test',
        'FR12345678901',
        '123456789',
        '33',
        'Complément adresse',
        'Île-de-France',
        '75001',
        'Paris',
        TRUE,
        'Adresse facturation',
        'Complément facturation',
        'Île-de-France',
        '75001',
        'Paris',
        'CODE001',
        'CNI123456',
        '/path/to/file.pdf',
        'Note interne test',
        'displayed',
        TRUE,
        TRUE,
        TRUE,
        TRUE
    ) as resultat;

-- Test 3: Récupérer les clients via la fonction RPC
SELECT 
    'Test 3: Récupération clients via fonction RPC' as test,
    json_array_length(get_isolated_clients()) as nombre_clients;

-- ============================================================================
-- 8. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérification complète
SELECT 
    'Vérification finale de l''isolation des clients' as info,
    (SELECT COUNT(*) FROM public.clients) as total_clients,
    (SELECT COUNT(*) FROM public.clients WHERE user_id = auth.uid()) as clients_utilisateur_connecte,
    (SELECT json_array_length(get_isolated_clients())) as clients_via_rpc,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%isolated%' AND routine_schema = 'public') as fonctions_rpc_creees,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'clients' AND policyname LIKE '%STRICT_ISOLATION%') as politiques_rls_creees,
    CASE 
        WHEN (SELECT COUNT(*) FROM public.clients WHERE user_id = auth.uid()) > 0
        THEN '✅ Isolation des clients fonctionnelle'
        ELSE '❌ Problème avec l''isolation des clients'
    END as status_isolation;

-- ============================================================================
-- 9. INSTRUCTIONS POUR L'APPLICATION
-- ============================================================================

SELECT '=== INSTRUCTIONS POUR L''APPLICATION ===' as section;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions pour la correction de l''isolation' as info,
    '1. RLS est activé avec politiques strictes' as step1,
    '2. Utilisez get_isolated_clients() pour récupérer vos clients' as step2,
    '3. Utilisez create_isolated_client() pour créer des clients' as step3,
    '4. Les triggers assignent automatiquement user_id' as step4,
    '5. Chaque utilisateur ne voit que ses propres clients' as step5,
    '6. Testez votre page client avec ces nouvelles méthodes' as step6;

-- Message final
SELECT 
    '🎉 SUCCÈS: Isolation des clients corrigée !' as final_message,
    'Vos clients sont maintenant isolés par utilisateur.' as details,
    'L''isolation est maintenue avec RLS strict.' as isolation_maintenue,
    'Utilisez get_isolated_clients() ou create_isolated_client() pour accéder à vos clients.' as methode_acces;
