-- Diagnostic complet pour identifier les champs qui ne se remplissent pas
-- Ce script va analyser en détail tous les aspects du problème

-- ========================================
-- ÉTAPE 1: VÉRIFICATION DE LA STRUCTURE
-- ========================================

-- 1.1 Vérifier la structure complète de la table
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

-- 1.2 Vérifier spécifiquement les champs problématiques
SELECT 
    'CHAMPS PROBLÉMATIQUES' as section,
    required_column as champ,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' 
            AND column_name = required_column 
            AND table_schema = 'public'
        ) THEN '✅ Existe'
        ELSE '❌ MANQUANT'
    END as status
FROM (
    VALUES 
        ('region'),
        ('postal_code'),
        ('city'),
        ('accounting_code'),
        ('cni_identifier'),
        ('address_complement'),
        ('company_name'),
        ('siren_number'),
        ('vat_number'),
        ('category'),
        ('title'),
        ('country_code'),
        ('billing_address_same'),
        ('billing_address'),
        ('billing_address_complement'),
        ('billing_region'),
        ('billing_postal_code'),
        ('billing_city'),
        ('attached_file_path'),
        ('internal_note'),
        ('status'),
        ('sms_notification'),
        ('email_notification'),
        ('sms_marketing'),
        ('email_marketing')
) AS required_columns(required_column);

-- ========================================
-- ÉTAPE 2: ANALYSE DES DONNÉES
-- ========================================

-- 2.1 Compter les clients et analyser les champs NULL
SELECT 
    'ANALYSE DONNÉES' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN region IS NULL THEN 1 END) as region_null,
    COUNT(CASE WHEN region = '' THEN 1 END) as region_vide,
    COUNT(CASE WHEN postal_code IS NULL THEN 1 END) as postal_code_null,
    COUNT(CASE WHEN postal_code = '' THEN 1 END) as postal_code_vide,
    COUNT(CASE WHEN city IS NULL THEN 1 END) as city_null,
    COUNT(CASE WHEN city = '' THEN 1 END) as city_vide,
    COUNT(CASE WHEN accounting_code IS NULL THEN 1 END) as accounting_code_null,
    COUNT(CASE WHEN accounting_code = '' THEN 1 END) as accounting_code_vide,
    COUNT(CASE WHEN cni_identifier IS NULL THEN 1 END) as cni_null,
    COUNT(CASE WHEN cni_identifier = '' THEN 1 END) as cni_vide,
    COUNT(CASE WHEN company_name IS NULL THEN 1 END) as company_name_null,
    COUNT(CASE WHEN company_name = '' THEN 1 END) as company_name_vide,
    COUNT(CASE WHEN siren_number IS NULL THEN 1 END) as siren_null,
    COUNT(CASE WHEN siren_number = '' THEN 1 END) as siren_vide,
    COUNT(CASE WHEN vat_number IS NULL THEN 1 END) as vat_null,
    COUNT(CASE WHEN vat_number = '' THEN 1 END) as vat_vide
FROM clients;

-- 2.2 Analyser les clients récents
SELECT 
    'CLIENTS RÉCENTS' as section,
    id,
    first_name,
    last_name,
    email,
    region,
    postal_code,
    city,
    accounting_code,
    cni_identifier,
    company_name,
    siren_number,
    vat_number,
    created_at,
    updated_at
FROM clients 
ORDER BY created_at DESC 
LIMIT 5;

-- ========================================
-- ÉTAPE 3: VÉRIFICATION RLS ET PERMISSIONS
-- ========================================

-- 3.1 Vérifier l'état de RLS
SELECT 
    'ÉTAT RLS' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 3.2 Vérifier les politiques RLS
SELECT 
    'POLITIQUES RLS' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 3.3 Vérifier les permissions
SELECT 
    'PERMISSIONS' as section,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- ========================================
-- ÉTAPE 4: ANALYSE DES VALEURS PAR DÉFAUT
-- ========================================

-- 4.1 Vérifier les valeurs par défaut actuelles
SELECT 
    'VALEURS PAR DÉFAUT' as section,
    column_name,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
AND column_name IN (
    'region', 'postal_code', 'city', 'accounting_code', 'cni_identifier',
    'address_complement', 'company_name', 'siren_number', 'vat_number',
    'category', 'title', 'country_code', 'status'
)
ORDER BY column_name;

-- 4.2 Analyser les contraintes
SELECT 
    'CONTRAINTES' as section,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- ========================================
-- ÉTAPE 5: TEST DE CRÉATION
-- ========================================

-- 5.1 Test d'insertion avec tous les champs
DO $$
DECLARE
    test_client_id UUID;
    insert_success BOOLEAN := false;
BEGIN
    RAISE NOTICE '🧪 Test d''insertion avec tous les champs...';
    
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address,
            category, title, company_name, vat_number, siren_number, country_code,
            address_complement, region, postal_code, city,
            billing_address_same, billing_address, billing_address_complement,
            billing_region, billing_postal_code, billing_city,
            accounting_code, cni_identifier, attached_file_path, internal_note,
            status, sms_notification, email_notification, sms_marketing, email_marketing,
            user_id
        ) VALUES (
            'Test', 'Diagnostic', 'test.diagnostic@example.com', '0123456789', '123 Rue Test',
            'particulier', 'mr', 'Test SARL', 'FR12345678901', '123456789', '33',
            'Bâtiment A', 'Île-de-France', '75001', 'Paris',
            true, '123 Rue Test', 'Bâtiment A', 'Île-de-France', '75001', 'Paris',
            'TEST001', '123456789', '', 'Note de test',
            'displayed', true, true, true, true,
            '00000000-0000-0000-0000-000000000000'::uuid
        ) RETURNING id INTO test_client_id;
        
        insert_success := true;
        RAISE NOTICE '✅ Test d''insertion réussi! ID: %', test_client_id;
        
        -- Vérifier les données insérées
        RAISE NOTICE '📋 Vérification des données insérées:';
        RAISE NOTICE '   - Région: %', (SELECT region FROM clients WHERE id = test_client_id);
        RAISE NOTICE '   - Code postal: %', (SELECT postal_code FROM clients WHERE id = test_client_id);
        RAISE NOTICE '   - Ville: %', (SELECT city FROM clients WHERE id = test_client_id);
        RAISE NOTICE '   - Code comptable: %', (SELECT accounting_code FROM clients WHERE id = test_client_id);
        RAISE NOTICE '   - CNI: %', (SELECT cni_identifier FROM clients WHERE id = test_client_id);
        RAISE NOTICE '   - Nom entreprise: %', (SELECT company_name FROM clients WHERE id = test_client_id);
        
        -- Nettoyer le test
        DELETE FROM clients WHERE id = test_client_id;
        RAISE NOTICE '🧹 Client de test supprimé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
        insert_success := false;
    END;
    
    IF insert_success THEN
        RAISE NOTICE '🎉 Le test d''insertion confirme que la table fonctionne correctement!';
    ELSE
        RAISE NOTICE '🚨 Le problème vient de la table ou des politiques RLS!';
    END IF;
END $$;

-- ========================================
-- ÉTAPE 6: RÉSUMÉ ET RECOMMANDATIONS
-- ========================================

DO $$
DECLARE
    missing_columns_count INTEGER;
    null_fields_count INTEGER;
    rls_active BOOLEAN;
BEGIN
    -- Compter les colonnes manquantes
    SELECT COUNT(*) INTO missing_columns_count
    FROM (
        VALUES 
            ('region'), ('postal_code'), ('city'), ('accounting_code'), ('cni_identifier'),
            ('address_complement'), ('company_name'), ('siren_number'), ('vat_number'),
            ('category'), ('title'), ('country_code'), ('billing_address_same'),
            ('billing_address'), ('billing_address_complement'), ('billing_region'),
            ('billing_postal_code'), ('billing_city'), ('attached_file_path'),
            ('internal_note'), ('status'), ('sms_notification'), ('email_notification'),
            ('sms_marketing'), ('email_marketing')
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
       OR company_name IS NULL OR siren_number IS NULL OR vat_number IS NULL;

    -- Vérifier RLS
    SELECT rowsecurity INTO rls_active
    FROM pg_tables 
    WHERE tablename = 'clients' 
    AND schemaname = 'public';

    RAISE NOTICE '📊 RÉSUMÉ DIAGNOSTIC COMPLET:';
    RAISE NOTICE '   - Colonnes manquantes: %', missing_columns_count;
    RAISE NOTICE '   - Clients avec champs NULL: %', null_fields_count;
    RAISE NOTICE '   - RLS activé: %', rls_active;
    
    IF missing_columns_count > 0 THEN
        RAISE NOTICE '❌ PROBLÈME: Colonnes manquantes dans la table';
        RAISE NOTICE '💡 SOLUTION: Exécuter recreation_table_clients.sql';
    ELSIF null_fields_count > 0 THEN
        RAISE NOTICE '❌ PROBLÈME: Champs NULL dans les données existantes';
        RAISE NOTICE '💡 SOLUTION: Exécuter fix_null_clients_fields.sql';
    ELSIF rls_active THEN
        RAISE NOTICE '⚠️ ATTENTION: RLS est activé - peut causer des problèmes d''accès';
        RAISE NOTICE '💡 SOLUTION: Tester avec desactiver_isolation_clients.sql';
    ELSE
        RAISE NOTICE '✅ La structure de la table semble correcte';
        RAISE NOTICE '💡 Le problème peut venir de l''application (mapping, validation, etc.)';
    END IF;
    
    RAISE NOTICE '🔍 PROCHAINES ÉTAPES:';
    RAISE NOTICE '   1. Vérifier les logs de l''application';
    RAISE NOTICE '   2. Tester le formulaire avec la console ouverte';
    RAISE NOTICE '   3. Vérifier le mapping dans supabaseService.ts';
    RAISE NOTICE '   4. Contrôler la validation du formulaire';
END $$;
