-- Script de vérification rapide de la table clients
-- Exécutez ce script pour diagnostiquer immédiatement le problème

-- 1. Vérifier si la table clients existe
SELECT 
    'VÉRIFICATION TABLE' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients' AND table_schema = 'public') 
        THEN '✅ Table clients existe' 
        ELSE '❌ Table clients n\'existe pas' 
    END as status;

-- 2. Vérifier la structure complète de la table
SELECT 
    'STRUCTURE TABLE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IN ('region', 'postal_code', 'city', 'accounting_code', 'cni_identifier', 
                           'address_complement', 'company_name', 'siren_number', 'vat_number',
                           'category', 'title', 'country_code', 'billing_address_same',
                           'billing_address', 'billing_address_complement', 'billing_region',
                           'billing_postal_code', 'billing_city', 'attached_file_path',
                           'internal_note', 'status', 'sms_notification', 'email_notification',
                           'sms_marketing', 'email_marketing') 
        THEN '🆕 NOUVELLE COLONNE'
        ELSE '📋 COLONNE ORIGINALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients' 
ORDER BY ordinal_position;

-- 3. Vérifier spécifiquement les nouvelles colonnes requises
SELECT 
    'COLONNES MANQUANTES' as section,
    required_column as colonne,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' 
            AND column_name = required_column 
            AND table_schema = 'public'
        ) THEN '✅ Existe'
        ELSE '❌ MANQUANTE'
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
) AS required_columns(required_column);

-- 4. Compter les clients et vérifier les champs NULL
SELECT 
    'STATISTIQUES CLIENTS' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN region IS NULL THEN 1 END) as region_null,
    COUNT(CASE WHEN postal_code IS NULL THEN 1 END) as postal_code_null,
    COUNT(CASE WHEN city IS NULL THEN 1 END) as city_null,
    COUNT(CASE WHEN accounting_code IS NULL THEN 1 END) as accounting_code_null,
    COUNT(CASE WHEN cni_identifier IS NULL THEN 1 END) as cni_null,
    COUNT(CASE WHEN company_name IS NULL THEN 1 END) as company_name_null,
    COUNT(CASE WHEN category IS NULL THEN 1 END) as category_null,
    COUNT(CASE WHEN title IS NULL THEN 1 END) as title_null
FROM clients;

-- 5. Afficher un exemple de client avec tous les champs
SELECT 
    'EXEMPLE CLIENT' as section,
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

-- 6. Vérifier les contraintes et index
SELECT 
    'CONTRAINTES' as section,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- 7. Vérifier les index
SELECT 
    'INDEX' as section,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 8. Résumé des actions nécessaires
DO $$
DECLARE
    missing_columns_count INTEGER;
    null_fields_count INTEGER;
BEGIN
    -- Compter les colonnes manquantes
    SELECT COUNT(*) INTO missing_columns_count
    FROM (
        VALUES 
            ('category'), ('title'), ('company_name'), ('vat_number'), ('siren_number'),
            ('country_code'), ('address_complement'), ('region'), ('postal_code'), ('city'),
            ('billing_address_same'), ('billing_address'), ('billing_address_complement'),
            ('billing_region'), ('billing_postal_code'), ('billing_city'), ('accounting_code'),
            ('cni_identifier'), ('attached_file_path'), ('internal_note'), ('status'),
            ('sms_notification'), ('email_notification'), ('sms_marketing'), ('email_marketing')
    ) AS required_columns(required_column)
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = required_column 
        AND table_schema = 'public'
    );

    -- Compter les champs NULL
    SELECT COUNT(*) INTO null_fields_count
    FROM clients 
    WHERE region IS NULL OR postal_code IS NULL OR city IS NULL 
       OR accounting_code IS NULL OR cni_identifier IS NULL 
       OR company_name IS NULL OR category IS NULL OR title IS NULL;

    RAISE NOTICE '📊 RÉSUMÉ DIAGNOSTIC:';
    RAISE NOTICE '   - Colonnes manquantes: %', missing_columns_count;
    RAISE NOTICE '   - Clients avec champs NULL: %', null_fields_count;
    
    IF missing_columns_count > 0 THEN
        RAISE NOTICE '❌ ACTION REQUISE: Exécuter extend_clients_table.sql pour ajouter les colonnes manquantes';
    ELSE
        RAISE NOTICE '✅ Toutes les colonnes existent';
    END IF;
    
    IF null_fields_count > 0 THEN
        RAISE NOTICE '❌ ACTION REQUISE: Exécuter fix_null_clients_fields.sql pour corriger les champs NULL';
    ELSE
        RAISE NOTICE '✅ Aucun champ NULL détecté';
    END IF;
    
    IF missing_columns_count = 0 AND null_fields_count = 0 THEN
        RAISE NOTICE '🎉 La table clients est correctement configurée!';
    END IF;
END $$;
