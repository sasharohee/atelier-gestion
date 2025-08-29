-- =====================================================
-- VÉRIFICATION DES DONNÉES D'UN CLIENT
-- =====================================================
-- Ce script vérifie les données d'un client spécifique
-- Date: 2025-01-27
-- =====================================================

-- Vérifier les données du client le plus récent
SELECT '=== DONNÉES DU CLIENT LE PLUS RÉCENT ===' as section;

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
ORDER BY created_at DESC 
LIMIT 1;

-- Vérifier le nombre total de clients
SELECT '=== STATISTIQUES ===' as section;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN company_name IS NOT NULL AND company_name != '' THEN 1 END) as clients_with_company,
    COUNT(CASE WHEN vat_number IS NOT NULL AND vat_number != '' THEN 1 END) as clients_with_vat,
    COUNT(CASE WHEN siren_number IS NOT NULL AND siren_number != '' THEN 1 END) as clients_with_siren,
    COUNT(CASE WHEN address_complement IS NOT NULL AND address_complement != '' THEN 1 END) as clients_with_address_complement,
    COUNT(CASE WHEN region IS NOT NULL AND region != '' THEN 1 END) as clients_with_region,
    COUNT(CASE WHEN postal_code IS NOT NULL AND postal_code != '' THEN 1 END) as clients_with_postal_code,
    COUNT(CASE WHEN city IS NOT NULL AND city != '' THEN 1 END) as clients_with_city,
    COUNT(CASE WHEN accounting_code IS NOT NULL AND accounting_code != '' THEN 1 END) as clients_with_accounting_code,
    COUNT(CASE WHEN cni_identifier IS NOT NULL AND cni_identifier != '' THEN 1 END) as clients_with_cni,
    COUNT(CASE WHEN internal_note IS NOT NULL AND internal_note != '' THEN 1 END) as clients_with_internal_note
FROM public.clients;

-- Vérifier les clients avec des données manquantes
SELECT '=== CLIENTS AVEC DONNÉES MANQUANTES ===' as section;

SELECT 
    id,
    first_name,
    last_name,
    email,
    CASE 
        WHEN company_name IS NULL OR company_name = '' THEN '❌'
        ELSE '✅'
    END as company_name_status,
    CASE 
        WHEN vat_number IS NULL OR vat_number = '' THEN '❌'
        ELSE '✅'
    END as vat_number_status,
    CASE 
        WHEN siren_number IS NULL OR siren_number = '' THEN '❌'
        ELSE '✅'
    END as siren_number_status,
    CASE 
        WHEN address_complement IS NULL OR address_complement = '' THEN '❌'
        ELSE '✅'
    END as address_complement_status,
    CASE 
        WHEN region IS NULL OR region = '' THEN '❌'
        ELSE '✅'
    END as region_status,
    CASE 
        WHEN postal_code IS NULL OR postal_code = '' THEN '❌'
        ELSE '✅'
    END as postal_code_status,
    CASE 
        WHEN city IS NULL OR city = '' THEN '❌'
        ELSE '✅'
    END as city_status,
    CASE 
        WHEN accounting_code IS NULL OR accounting_code = '' THEN '❌'
        ELSE '✅'
    END as accounting_code_status,
    CASE 
        WHEN cni_identifier IS NULL OR cni_identifier = '' THEN '❌'
        ELSE '✅'
    END as cni_identifier_status,
    CASE 
        WHEN internal_note IS NULL OR internal_note = '' THEN '❌'
        ELSE '✅'
    END as internal_note_status
FROM public.clients 
ORDER BY created_at DESC 
LIMIT 5;
