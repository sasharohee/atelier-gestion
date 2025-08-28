-- Script pour corriger les champs NULL dans la table clients
-- Ce script met à jour les champs NULL avec des valeurs par défaut appropriées

-- 1. Mettre à jour les champs avec des valeurs par défaut appropriées
UPDATE clients 
SET 
    -- Informations personnelles et entreprise
    category = COALESCE(category, 'particulier'),
    title = COALESCE(title, 'mr'),
    company_name = COALESCE(company_name, ''),
    vat_number = COALESCE(vat_number, ''),
    siren_number = COALESCE(siren_number, ''),
    country_code = COALESCE(country_code, '33'),
    
    -- Adresse détaillée
    address_complement = COALESCE(address_complement, ''),
    region = COALESCE(region, ''),
    postal_code = COALESCE(postal_code, ''),
    city = COALESCE(city, ''),
    
    -- Adresse de facturation
    billing_address_same = COALESCE(billing_address_same, true),
    billing_address = COALESCE(billing_address, ''),
    billing_address_complement = COALESCE(billing_address_complement, ''),
    billing_region = COALESCE(billing_region, ''),
    billing_postal_code = COALESCE(billing_postal_code, ''),
    billing_city = COALESCE(billing_city, ''),
    
    -- Informations complémentaires
    accounting_code = COALESCE(accounting_code, ''),
    cni_identifier = COALESCE(cni_identifier, ''),
    attached_file_path = COALESCE(attached_file_path, ''),
    internal_note = COALESCE(internal_note, ''),
    
    -- Préférences
    status = COALESCE(status, 'displayed'),
    sms_notification = COALESCE(sms_notification, true),
    email_notification = COALESCE(email_notification, true),
    sms_marketing = COALESCE(sms_marketing, true),
    email_marketing = COALESCE(email_marketing, true),
    
    -- Mettre à jour le timestamp
    updated_at = NOW()
WHERE 
    -- Mettre à jour seulement les clients qui ont au moins un champ NULL
    category IS NULL OR
    title IS NULL OR
    company_name IS NULL OR
    vat_number IS NULL OR
    siren_number IS NULL OR
    country_code IS NULL OR
    address_complement IS NULL OR
    region IS NULL OR
    postal_code IS NULL OR
    city IS NULL OR
    billing_address_same IS NULL OR
    billing_address IS NULL OR
    billing_address_complement IS NULL OR
    billing_region IS NULL OR
    billing_postal_code IS NULL OR
    billing_city IS NULL OR
    accounting_code IS NULL OR
    cni_identifier IS NULL OR
    attached_file_path IS NULL OR
    internal_note IS NULL OR
    status IS NULL OR
    sms_notification IS NULL OR
    email_notification IS NULL OR
    sms_marketing IS NULL OR
    email_marketing IS NULL;

-- 2. Vérifier le nombre de clients mis à jour
SELECT 
    'Clients mis à jour' as description,
    COUNT(*) as count
FROM clients 
WHERE updated_at >= NOW() - INTERVAL '1 minute';

-- 3. Vérifier qu'il n'y a plus de champs NULL
SELECT 
    'Clients avec région NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE region IS NULL
UNION ALL
SELECT 
    'Clients avec code postal NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE postal_code IS NULL
UNION ALL
SELECT 
    'Clients avec ville NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE city IS NULL
UNION ALL
SELECT 
    'Clients avec code comptable NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE accounting_code IS NULL
UNION ALL
SELECT 
    'Clients avec CNI NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE cni_identifier IS NULL
UNION ALL
SELECT 
    'Clients avec complément adresse NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE address_complement IS NULL
UNION ALL
SELECT 
    'Clients avec nom entreprise NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE company_name IS NULL
UNION ALL
SELECT 
    'Clients avec SIREN NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE siren_number IS NULL
UNION ALL
SELECT 
    'Clients avec TVA NULL' as description,
    COUNT(*) as count
FROM clients 
WHERE vat_number IS NULL;

-- 4. Afficher un exemple de client corrigé
SELECT 
    id,
    first_name,
    last_name,
    email,
    category,
    title,
    company_name,
    region,
    postal_code,
    city,
    status,
    created_at,
    updated_at
FROM clients 
ORDER BY updated_at DESC 
LIMIT 3;

-- 5. Résumé des corrections appliquées
SELECT 
    'Résumé des corrections' as info,
    'Tous les champs NULL ont été remplacés par des valeurs par défaut appropriées' as details;
