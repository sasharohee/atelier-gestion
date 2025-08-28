-- =====================================================
-- VÉRIFICATION D'UN CLIENT SPÉCIFIQUE
-- =====================================================
-- Ce script vérifie les données d'un client spécifique par son ID
-- Date: 2025-01-27
-- =====================================================

-- Remplacez 'd3108f5b-7af0-4da5-9471-0de3c01d1d24' par l'ID de votre client
SELECT '=== DONNÉES DU CLIENT SPÉCIFIQUE ===' as section;

SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    notes,
    category,
    title,
    company_name,
    vat_number,
    siren_number,
    country_code,
    address_complement,
    region,
    postal_code,
    city,
    billing_address_same,
    billing_address,
    billing_address_complement,
    billing_region,
    billing_postal_code,
    billing_city,
    accounting_code,
    cni_identifier,
    attached_file_path,
    internal_note,
    status,
    sms_notification,
    email_notification,
    sms_marketing,
    email_marketing,
    user_id,
    created_at,
    updated_at
FROM public.clients 
WHERE id = 'd3108f5b-7af0-4da5-9471-0de3c01d1d24';

-- Vérifier tous les clients récents
SELECT '=== TOUS LES CLIENTS RÉCENTS ===' as section;

SELECT 
    id,
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    address_complement,
    region,
    postal_code,
    city,
    accounting_code,
    cni_identifier,
    internal_note,
    created_at
FROM public.clients 
ORDER BY created_at DESC 
LIMIT 5;
