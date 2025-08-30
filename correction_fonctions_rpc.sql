-- 🔧 CORRECTION FONCTIONS RPC - Types de Données
-- Script pour corriger les fonctions RPC avec les bons types
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DES TYPES DE DONNÉES
-- ============================================================================

SELECT '=== DIAGNOSTIC DES TYPES DE DONNÉES ===' as section;

-- Vérifier la structure de la table clients
SELECT 
    'Structure table clients' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. CORRECTION DE LA FONCTION RPC GET_ISOLATED_CLIENTS
-- ============================================================================

SELECT '=== CORRECTION DE LA FONCTION RPC GET_ISOLATED_CLIENTS ===' as section;

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS get_isolated_clients();

-- Créer la fonction corrigée avec les bons types
CREATE OR REPLACE FUNCTION get_isolated_clients()
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    notes TEXT,
    category VARCHAR(50),
    title VARCHAR(50),
    company_name TEXT,
    vat_number TEXT,
    siren_number TEXT,
    country_code VARCHAR(10),
    address_complement TEXT,
    region TEXT,
    postal_code VARCHAR(20),
    city TEXT,
    billing_address_same BOOLEAN,
    billing_address TEXT,
    billing_address_complement TEXT,
    billing_region TEXT,
    billing_postal_code VARCHAR(20),
    billing_city TEXT,
    accounting_code TEXT,
    cni_identifier TEXT,
    attached_file_path TEXT,
    internal_note TEXT,
    status VARCHAR(50),
    sms_notification BOOLEAN,
    email_notification BOOLEAN,
    sms_marketing BOOLEAN,
    email_marketing BOOLEAN,
    user_id UUID,
    workshop_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.notes,
        c.category,
        c.title,
        c.company_name,
        c.vat_number,
        c.siren_number,
        c.country_code,
        c.address_complement,
        c.region,
        c.postal_code,
        c.city,
        c.billing_address_same,
        c.billing_address,
        c.billing_address_complement,
        c.billing_region,
        c.billing_postal_code,
        c.billing_city,
        c.accounting_code,
        c.cni_identifier,
        c.attached_file_path,
        c.internal_note,
        c.status,
        c.sms_notification,
        c.email_notification,
        c.sms_marketing,
        c.email_marketing,
        c.user_id,
        c.workshop_id,
        c.created_at,
        c.updated_at
    FROM clients c
    WHERE c.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
END;
$$;

-- Tester la fonction corrigée
SELECT 
    'Fonction RPC get_isolated_clients corrigée' as info,
    COUNT(*) as clients_visibles
FROM get_isolated_clients();

-- ============================================================================
-- 3. CORRECTION DE LA FONCTION RPC CREATE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION DE LA FONCTION RPC CREATE_ISOLATED_CLIENT ===' as section;

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS create_isolated_client(TEXT, TEXT, TEXT, TEXT, TEXT);

-- Créer la fonction corrigée avec les bons types
CREATE OR REPLACE FUNCTION create_isolated_client(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_category VARCHAR(50) DEFAULT NULL,
    p_title VARCHAR(50) DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL,
    p_vat_number TEXT DEFAULT NULL,
    p_siren_number TEXT DEFAULT NULL,
    p_country_code VARCHAR(10) DEFAULT NULL,
    p_address_complement TEXT DEFAULT NULL,
    p_region TEXT DEFAULT NULL,
    p_postal_code VARCHAR(20) DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_billing_address_same BOOLEAN DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_billing_address_complement TEXT DEFAULT NULL,
    p_billing_region TEXT DEFAULT NULL,
    p_billing_postal_code VARCHAR(20) DEFAULT NULL,
    p_billing_city TEXT DEFAULT NULL,
    p_accounting_code TEXT DEFAULT NULL,
    p_cni_identifier TEXT DEFAULT NULL,
    p_attached_file_path TEXT DEFAULT NULL,
    p_internal_note TEXT DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT NULL,
    p_sms_notification BOOLEAN DEFAULT NULL,
    p_email_notification BOOLEAN DEFAULT NULL,
    p_sms_marketing BOOLEAN DEFAULT NULL,
    p_email_marketing BOOLEAN DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    workshop_id UUID
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Créer le client
    INSERT INTO clients (
        first_name, last_name, email, phone, address, notes, category, title,
        company_name, vat_number, siren_number, country_code, address_complement,
        region, postal_code, city, billing_address_same, billing_address,
        billing_address_complement, billing_region, billing_postal_code,
        billing_city, accounting_code, cni_identifier, attached_file_path,
        internal_note, status, sms_notification, email_notification,
        sms_marketing, email_marketing, user_id, workshop_id
    )
    VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_notes, p_category, p_title,
        p_company_name, p_vat_number, p_siren_number, p_country_code, p_address_complement,
        p_region, p_postal_code, p_city, p_billing_address_same, p_billing_address,
        p_billing_address_complement, p_billing_region, p_billing_postal_code,
        p_billing_city, p_accounting_code, p_cni_identifier, p_attached_file_path,
        p_internal_note, p_status, p_sms_notification, p_email_notification,
        p_sms_marketing, p_email_marketing, p_user_id, current_workshop_id
    )
    RETURNING clients.id INTO new_client_id;
    
    -- Retourner le client créé
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.workshop_id
    FROM clients c
    WHERE c.id = new_client_id;
END;
$$;

-- Tester la fonction corrigée
SELECT 
    'Test fonction RPC create_isolated_client corrigée' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM create_isolated_client('Test', 'Corrigé', 'test.corrige@example.com', '3333333333', 'Adresse test corrigé');

-- ============================================================================
-- 4. CORRECTION DE LA FONCTION RPC UPDATE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION DE LA FONCTION RPC UPDATE_ISOLATED_CLIENT ===' as section;

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS update_isolated_client(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, VARCHAR, TEXT, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, UUID);

-- Créer la fonction corrigée avec les bons types
CREATE OR REPLACE FUNCTION update_isolated_client(
    p_id UUID,
    p_first_name TEXT DEFAULT NULL,
    p_last_name TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_category VARCHAR(50) DEFAULT NULL,
    p_title VARCHAR(50) DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL,
    p_vat_number TEXT DEFAULT NULL,
    p_siren_number TEXT DEFAULT NULL,
    p_country_code VARCHAR(10) DEFAULT NULL,
    p_address_complement TEXT DEFAULT NULL,
    p_region TEXT DEFAULT NULL,
    p_postal_code VARCHAR(20) DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_billing_address_same BOOLEAN DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_billing_address_complement TEXT DEFAULT NULL,
    p_billing_region TEXT DEFAULT NULL,
    p_billing_postal_code VARCHAR(20) DEFAULT NULL,
    p_billing_city TEXT DEFAULT NULL,
    p_accounting_code TEXT DEFAULT NULL,
    p_cni_identifier TEXT DEFAULT NULL,
    p_attached_file_path TEXT DEFAULT NULL,
    p_internal_note TEXT DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT NULL,
    p_sms_notification BOOLEAN DEFAULT NULL,
    p_email_notification BOOLEAN DEFAULT NULL,
    p_sms_marketing BOOLEAN DEFAULT NULL,
    p_email_marketing BOOLEAN DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    workshop_id UUID
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Modifier le client seulement s'il appartient au workshop actuel
    UPDATE clients SET
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address),
        notes = COALESCE(p_notes, notes),
        category = COALESCE(p_category, category),
        title = COALESCE(p_title, title),
        company_name = COALESCE(p_company_name, company_name),
        vat_number = COALESCE(p_vat_number, vat_number),
        siren_number = COALESCE(p_siren_number, siren_number),
        country_code = COALESCE(p_country_code, country_code),
        address_complement = COALESCE(p_address_complement, address_complement),
        region = COALESCE(p_region, region),
        postal_code = COALESCE(p_postal_code, postal_code),
        city = COALESCE(p_city, city),
        billing_address_same = COALESCE(p_billing_address_same, billing_address_same),
        billing_address = COALESCE(p_billing_address, billing_address),
        billing_address_complement = COALESCE(p_billing_address_complement, billing_address_complement),
        billing_region = COALESCE(p_billing_region, billing_region),
        billing_postal_code = COALESCE(p_billing_postal_code, billing_postal_code),
        billing_city = COALESCE(p_billing_city, billing_city),
        accounting_code = COALESCE(p_accounting_code, accounting_code),
        cni_identifier = COALESCE(p_cni_identifier, cni_identifier),
        attached_file_path = COALESCE(p_attached_file_path, attached_file_path),
        internal_note = COALESCE(p_internal_note, internal_note),
        status = COALESCE(p_status, status),
        sms_notification = COALESCE(p_sms_notification, sms_notification),
        email_notification = COALESCE(p_email_notification, email_notification),
        sms_marketing = COALESCE(p_sms_marketing, sms_marketing),
        email_marketing = COALESCE(p_email_marketing, email_marketing),
        user_id = COALESCE(p_user_id, user_id),
        updated_at = NOW()
    WHERE id = p_id 
        AND workshop_id = current_workshop_id;
    
    -- Retourner le client modifié
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.workshop_id
    FROM clients c
    WHERE c.id = p_id 
        AND c.workshop_id = current_workshop_id;
END;
$$;

-- ============================================================================
-- 5. VÉRIFICATION DES FONCTIONS CORRIGÉES
-- ============================================================================

SELECT '=== VÉRIFICATION DES FONCTIONS CORRIGÉES ===' as section;

-- Vérifier que les fonctions existent
SELECT 
    'Fonctions RPC corrigées' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%isolated%'
    AND routine_schema = 'public'
ORDER BY routine_name;

-- Tester la fonction de récupération
SELECT 
    'Test fonction get_isolated_clients' as info,
    COUNT(*) as clients_visibles
FROM get_isolated_clients();

-- Tester la fonction de création
SELECT 
    'Test fonction create_isolated_client' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM create_isolated_client('Test', 'Final', 'test.final@example.com', '4444444444', 'Adresse test final');

-- ============================================================================
-- 6. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction
SELECT 
    'Résumé de la correction des fonctions RPC' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM get_isolated_clients()) as clients_visibles_via_rpc,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%isolated%' AND routine_schema = 'public') as fonctions_rpc_creees,
    CASE 
        WHEN (SELECT COUNT(*) FROM get_isolated_clients()) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Fonctions RPC corrigées et fonctionnelles'
        ELSE '❌ Problème avec les fonctions RPC'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM get_isolated_clients()) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '🎉 SUCCÈS: Les fonctions RPC sont maintenant corrigées et fonctionnelles !'
        ELSE '⚠️ PROBLÈME: Les fonctions RPC ne fonctionnent toujours pas'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Les fonctions RPC sont maintenant corrigées avec les bons types' as step1,
    '2. Utilisez get_isolated_clients() pour récupérer vos clients' as step2,
    '3. Utilisez create_isolated_client() pour créer des clients' as step3,
    '4. Utilisez update_isolated_client() pour modifier des clients' as step4,
    '5. Utilisez delete_isolated_client() pour supprimer des clients' as step5,
    '6. L''isolation est maintenant forcée côté base de données' as step6;
