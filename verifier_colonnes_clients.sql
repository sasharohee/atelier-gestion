-- =====================================================
-- VÉRIFICATION DES COLONNES DE LA TABLE CLIENTS
-- =====================================================
-- Ce script vérifie quelles colonnes existent actuellement dans la table clients
-- Date: 2025-01-27
-- =====================================================

-- Vérifier la structure actuelle de la table clients
SELECT '=== STRUCTURE ACTUELLE DE LA TABLE CLIENTS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- Vérifier le nombre total de colonnes
SELECT 
    '=== RÉSUMÉ ===' as section,
    COUNT(*) as total_columns,
    'colonnes trouvées dans la table clients' as description
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients';

-- Vérifier spécifiquement les colonnes manquantes
SELECT '=== COLONNES MANQUANTES ===' as section;

-- Liste des colonnes attendues
WITH expected_columns AS (
    SELECT unnest(ARRAY[
        'id', 'first_name', 'last_name', 'email', 'phone', 'address', 'notes',
        'category', 'title', 'company_name', 'vat_number', 'siren_number', 'country_code',
        'address_complement', 'region', 'postal_code', 'city',
        'billing_address_same', 'billing_address', 'billing_address_complement', 
        'billing_region', 'billing_postal_code', 'billing_city',
        'accounting_code', 'cni_identifier', 'attached_file_path', 'internal_note',
        'status', 'sms_notification', 'email_notification', 'sms_marketing', 'email_marketing',
        'user_id', 'created_at', 'updated_at'
    ]) as column_name
)
SELECT 
    ec.column_name,
    CASE 
        WHEN ic.column_name IS NOT NULL THEN '✅ PRÉSENTE'
        ELSE '❌ MANQUANTE'
    END as status
FROM expected_columns ec
LEFT JOIN information_schema.columns ic ON 
    ic.table_schema = 'public' 
    AND ic.table_name = 'clients' 
    AND ic.column_name = ec.column_name
ORDER BY ec.column_name;

-- Vérifier les données d'un client existant (si il y en a)
SELECT '=== DONNEES D''UN CLIENT EXEMPLE ===' as section;

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
LIMIT 1;
