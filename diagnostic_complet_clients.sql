-- Script de diagnostic complet pour la table clients
-- Ce script identifie et résout tous les problèmes liés aux champs NULL

-- ========================================
-- ÉTAPE 1: DIAGNOSTIC INITIAL
-- ========================================

-- 1.1 Vérifier si les nouvelles colonnes existent
DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[]::TEXT[];
    required_columns TEXT[] := ARRAY[
        'category', 'title', 'company_name', 'vat_number', 'siren_number', 
        'country_code', 'address_complement', 'region', 'postal_code', 'city',
        'billing_address_same', 'billing_address', 'billing_address_complement',
        'billing_region', 'billing_postal_code', 'billing_city', 'accounting_code',
        'cni_identifier', 'attached_file_path', 'internal_note', 'status',
        'sms_notification', 'email_notification', 'sms_marketing', 'email_marketing'
    ];
    col TEXT;
BEGIN
    RAISE NOTICE '🔍 Vérification des colonnes manquantes...';
    
    FOREACH col IN ARRAY required_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' 
            AND column_name = col 
            AND table_schema = 'public'
        ) THEN
            missing_columns := array_append(missing_columns, col);
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) > 0 THEN
        RAISE NOTICE '❌ Colonnes manquantes: %', array_to_string(missing_columns, ', ');
        RAISE NOTICE '💡 Exécutez le script extend_clients_table.sql pour ajouter ces colonnes';
    ELSE
        RAISE NOTICE '✅ Toutes les colonnes requises existent';
    END IF;
END $$;

-- 1.2 Compter les clients avec des champs NULL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'Région' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE region IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'Code postal' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE postal_code IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'Ville' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE city IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'Code comptable' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE accounting_code IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'CNI' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE cni_identifier IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'Nom entreprise' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE company_name IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'SIREN' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE siren_number IS NULL
UNION ALL
SELECT 
    'DIAGNOSTIC: Clients avec champs NULL' as section,
    'TVA' as field,
    COUNT(*) as null_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients) as percentage
FROM clients WHERE vat_number IS NULL;

-- ========================================
-- ÉTAPE 2: CORRECTION AUTOMATIQUE
-- ========================================

-- 2.1 Mettre à jour les champs NULL avec des valeurs par défaut
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '🔧 Correction des champs NULL...';
    
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
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ % clients mis à jour avec des valeurs par défaut', updated_count;
END $$;

-- ========================================
-- ÉTAPE 3: VÉRIFICATION POST-CORRECTION
-- ========================================

-- 3.1 Vérifier qu'il n'y a plus de champs NULL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'Région' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE region IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'Code postal' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE postal_code IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'Ville' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE city IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'Code comptable' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE accounting_code IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'CNI' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE cni_identifier IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'Nom entreprise' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE company_name IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'SIREN' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE siren_number IS NULL
UNION ALL
SELECT 
    'VÉRIFICATION: Champs NULL après correction' as section,
    'TVA' as field,
    COUNT(*) as remaining_null_count
FROM clients WHERE vat_number IS NULL;

-- 3.2 Afficher un exemple de client corrigé
SELECT 
    'EXEMPLE: Client corrigé' as info,
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
LIMIT 1;

-- ========================================
-- ÉTAPE 4: RÉSUMÉ FINAL
-- ========================================

SELECT 
    'RÉSUMÉ FINAL' as section,
    'Total clients' as metric,
    COUNT(*) as value
FROM clients
UNION ALL
SELECT 
    'RÉSUMÉ FINAL' as section,
    'Clients avec région' as metric,
    COUNT(*) as value
FROM clients WHERE region != ''
UNION ALL
SELECT 
    'RÉSUMÉ FINAL' as section,
    'Clients avec code postal' as metric,
    COUNT(*) as value
FROM clients WHERE postal_code != ''
UNION ALL
SELECT 
    'RÉSUMÉ FINAL' as section,
    'Clients avec ville' as metric,
    COUNT(*) as value
FROM clients WHERE city != ''
UNION ALL
SELECT 
    'RÉSUMÉ FINAL' as section,
    'Clients avec nom entreprise' as metric,
    COUNT(*) as value
FROM clients WHERE company_name != '';

-- Message de fin
DO $$
BEGIN
    RAISE NOTICE '🎉 Diagnostic et correction terminés!';
    RAISE NOTICE '📋 Vérifiez les résultats ci-dessus pour confirmer que tous les champs NULL ont été corrigés.';
    RAISE NOTICE '💡 Les nouveaux clients créés avec le formulaire étendu devraient maintenant avoir tous les champs remplis.';
END $$;
