-- Script pour vérifier la structure de la table clients et identifier les champs NULL
-- Exécutez ce script pour diagnostiquer les problèmes de structure

-- 1. Vérifier la structure complète de la table clients
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    col_description((table_schema||'.'||table_name)::regclass, ordinal_position) as comment
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients' 
ORDER BY ordinal_position;

-- 2. Vérifier spécifiquement les nouveaux champs requis
SELECT 
    column_name,
    CASE 
        WHEN column_name IS NOT NULL THEN '✅ Existe'
        ELSE '❌ Manquant'
    END as status
FROM (
    VALUES 
        ('category'),
        ('title'),
        ('company_name'),
        ('vat_number'),
        ('siren_number'),
        ('country_code'),
        ('address_complement'),
        ('region'),
        ('postal_code'),
        ('city'),
        ('billing_address_same'),
        ('billing_address'),
        ('billing_address_complement'),
        ('billing_region'),
        ('billing_postal_code'),
        ('billing_city'),
        ('accounting_code'),
        ('cni_identifier'),
        ('attached_file_path'),
        ('internal_note'),
        ('status'),
        ('sms_notification'),
        ('email_notification'),
        ('sms_marketing'),
        ('email_marketing')
) AS required_fields(column_name)
LEFT JOIN information_schema.columns ic 
    ON ic.column_name = required_fields.column_name 
    AND ic.table_name = 'clients' 
    AND ic.table_schema = 'public';

-- 3. Compter les clients avec des champs NULL
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

-- 4. Afficher un exemple de client avec tous les champs
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
    created_at,
    updated_at
FROM clients 
ORDER BY created_at DESC 
LIMIT 1;

-- 5. Vérifier les contraintes et index
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- 6. Vérifier les index
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'clients' 
AND schemaname = 'public';
