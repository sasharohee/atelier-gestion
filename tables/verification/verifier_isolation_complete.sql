-- ============================================================================
-- VÉRIFICATION COMPLÈTE DE L'ISOLATION DES DONNÉES
-- ============================================================================

-- Vérifier le workshop_id actuel
SELECT '=== WORKSHOP_ID ACTUEL ===' as section;
SELECT 
    'Workshop ID actuel' as info,
    value as current_workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 1. VÉRIFICATION DE L'EXISTENCE DES COLONNES WORKSHOP_ID
-- ============================================================================

SELECT '=== VÉRIFICATION DES COLONNES WORKSHOP_ID ===' as section;

-- Vérifier quelles tables ont la colonne workshop_id
SELECT 
    'Colonnes workshop_id' as info,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'workshop_id'
    AND table_name IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY table_name;

-- ============================================================================
-- 2. VÉRIFICATION DU STATUT RLS
-- ============================================================================

SELECT '=== VÉRIFICATION DU STATUT RLS ===' as section;

-- Vérifier l'activation RLS sur les tables principales
SELECT 
    'Tables principales' as info,
    tablename,
    CASE WHEN rowsecurity THEN 'RLS Active' ELSE 'RLS Inactive' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY tablename;

-- ============================================================================
-- 3. COMPTAGE DES DONNÉES PAR PAGE (AVEC VÉRIFICATION DES COLONNES)
-- ============================================================================

SELECT '=== COMPTAGE DES DONNÉES PAR PAGE ===' as section;

-- Page Clients (toujours présente)
SELECT 
    'Page Clients' as page,
    COUNT(*) as total_clients,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as clients_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as clients_wrong_workshop
FROM clients;

-- Page Devices (si la colonne existe)
SELECT 
    'Page Devices' as page,
    COUNT(*) as total_devices,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as devices_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as devices_wrong_workshop
FROM devices;

-- Page Repairs (si la colonne existe)
SELECT 
    'Page Repairs' as page,
    COUNT(*) as total_repairs,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as repairs_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as repairs_wrong_workshop
FROM repairs;

-- Page Sales (si la colonne existe)
SELECT 
    'Page Sales' as page,
    COUNT(*) as total_sales,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as sales_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as sales_wrong_workshop
FROM sales;

-- Page Appointments (si la colonne existe)
SELECT 
    'Page Appointments' as page,
    COUNT(*) as total_appointments,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as appointments_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as appointments_wrong_workshop
FROM appointments;

-- Page Parts (si la colonne existe)
SELECT 
    'Page Parts' as page,
    COUNT(*) as total_parts,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'parts' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as parts_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'parts' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as parts_wrong_workshop
FROM parts;

-- Page Products (si la colonne existe)
SELECT 
    'Page Products' as page,
    COUNT(*) as total_products,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as products_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as products_wrong_workshop
FROM products;

-- Page Services (si la colonne existe)
SELECT 
    'Page Services' as page,
    COUNT(*) as total_services,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'services' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as services_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'services' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as services_wrong_workshop
FROM services;

-- Page Fidélité (si la colonne existe)
SELECT 
    'Page Fidelite' as page,
    COUNT(*) as total_loyalty_config,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loyalty_config' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        ELSE COUNT(*)
    END as loyalty_correct_workshop,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loyalty_config' AND column_name = 'workshop_id') 
        THEN COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END)
        ELSE 0
    END as loyalty_wrong_workshop
FROM loyalty_config;

-- ============================================================================
-- 4. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as section;

-- Vérifier les politiques RLS
SELECT 
    'Politiques RLS' as info,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY tablename, cmd;

-- ============================================================================
-- 5. TEST D'ISOLATION COMPLET
-- ============================================================================

SELECT '=== TEST DISOLATION COMPLET ===' as section;

-- Test 1: Vérifier que toutes les tables ont des données isolées (seulement pour les tables avec workshop_id)
SELECT 
    'Test 1: Isolation generale' as test,
    COUNT(*) as total_tables_with_issues,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Toutes les tables sont isolees'
        ELSE 'ECHEC: Problemes d isolation detectes'
    END as result
FROM (
    SELECT 'clients' as table_name, COUNT(*) as wrong_records
    FROM clients 
    WHERE EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'workshop_id')
        AND workshop_id IS NOT NULL 
        AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
        AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
    UNION ALL
    SELECT 'devices' as table_name, COUNT(*)
    FROM devices 
    WHERE EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'workshop_id')
        AND workshop_id IS NOT NULL 
        AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
        AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
    UNION ALL
    SELECT 'repairs' as table_name, COUNT(*)
    FROM repairs 
    WHERE EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'workshop_id')
        AND workshop_id IS NOT NULL 
        AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
        AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
    UNION ALL
    SELECT 'sales' as table_name, COUNT(*)
    FROM sales 
    WHERE EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'workshop_id')
        AND workshop_id IS NOT NULL 
        AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
        AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
) as isolation_check
WHERE wrong_records > 0;

-- Test 2: Vérifier l'activation RLS
SELECT 
    'Test 2: Activation RLS' as test,
    COUNT(*) as tables_without_rls,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Toutes les tables ont RLS active'
        ELSE 'ECHEC: Certaines tables nont pas RLS active'
    END as result
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
    AND NOT rowsecurity;

-- Test 3: Vérifier que les politiques RLS existent
SELECT 
    'Test 3: Politiques RLS' as test,
    COUNT(*) as missing_policies,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Toutes les politiques RLS existent'
        ELSE 'ECHEC: Politiques RLS manquantes'
    END as result
FROM (
    SELECT 'clients' as table_name
    UNION ALL SELECT 'devices' as table_name
    UNION ALL SELECT 'repairs' as table_name
    UNION ALL SELECT 'sales' as table_name
    UNION ALL SELECT 'appointments' as table_name
    UNION ALL SELECT 'parts' as table_name
    UNION ALL SELECT 'products' as table_name
    UNION ALL SELECT 'services' as table_name
    UNION ALL SELECT 'loyalty_config' as table_name
    UNION ALL SELECT 'loyalty_tiers_advanced' as table_name
    UNION ALL SELECT 'loyalty_points_history' as table_name
) as required_tables
WHERE NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
        AND tablename = required_tables.table_name
);

-- ============================================================================
-- 6. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé global de l'isolation
SELECT 
    'Resume global' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM devices) as total_devices,
    (SELECT COUNT(*) FROM repairs) as total_repairs,
    (SELECT COUNT(*) FROM sales) as total_sales,
    (SELECT COUNT(*) FROM appointments) as total_appointments,
    (SELECT COUNT(*) FROM parts) as total_parts,
    (SELECT COUNT(*) FROM products) as total_products,
    (SELECT COUNT(*) FROM services) as total_services,
    (SELECT COUNT(*) FROM loyalty_config) as total_loyalty_config,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history') AND NOT rowsecurity) = 0
        AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')) >= 20
        THEN 'ISOLATION FONCTIONNELLE'
        ELSE 'PROBLEME DISOLATION DETECTE - Executez le script de correction complete'
    END as final_message;
