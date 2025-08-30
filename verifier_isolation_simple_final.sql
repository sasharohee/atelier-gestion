-- 🔍 VÉRIFICATION ULTRA-SIMPLE - Isolation des Données
-- Script simple pour vérifier rapidement l'isolation des données
-- Date: 2025-01-23

-- ============================================================================
-- 1. VÉRIFICATION RAPIDE
-- ============================================================================

SELECT '=== VÉRIFICATION RAPIDE ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    value as current_workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 2. COMPTAGE SIMPLE DES DONNÉES
-- ============================================================================

SELECT '=== COMPTAGE DES DONNÉES ===' as section;

-- Compter les données dans chaque table
SELECT 'clients' as table_name, COUNT(*) as total_records FROM clients
UNION ALL
SELECT 'devices' as table_name, COUNT(*) as total_records FROM devices
UNION ALL
SELECT 'repairs' as table_name, COUNT(*) as total_records FROM repairs
UNION ALL
SELECT 'sales' as table_name, COUNT(*) as total_records FROM sales
UNION ALL
SELECT 'appointments' as table_name, COUNT(*) as total_records FROM appointments
UNION ALL
SELECT 'parts' as table_name, COUNT(*) as total_records FROM parts
UNION ALL
SELECT 'products' as table_name, COUNT(*) as total_records FROM products
UNION ALL
SELECT 'services' as table_name, COUNT(*) as total_records FROM services
UNION ALL
SELECT 'loyalty_config' as table_name, COUNT(*) as total_records FROM loyalty_config;

-- ============================================================================
-- 3. VÉRIFICATION DES COLONNES WORKSHOP_ID
-- ============================================================================

SELECT '=== COLONNES WORKSHOP_ID ===' as section;

-- Vérifier quelles tables ont la colonne workshop_id
SELECT 
    table_name,
    CASE 
        WHEN column_name IS NOT NULL THEN 'Présente'
        ELSE 'Manquante'
    END as workshop_id_status
FROM (
    SELECT unnest(ARRAY['clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history']) as table_name
) t
LEFT JOIN information_schema.columns c 
    ON c.table_name = t.table_name 
    AND c.column_name = 'workshop_id' 
    AND c.table_schema = 'public'
ORDER BY table_name;

-- ============================================================================
-- 4. VÉRIFICATION RLS
-- ============================================================================

SELECT '=== STATUT RLS ===' as section;

-- Vérifier l'activation RLS
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN 'Active' ELSE 'Inactive' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY tablename;

-- ============================================================================
-- 5. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé simple
SELECT 
    'Résumé' as info,
    (SELECT COUNT(*) FROM clients) as clients_count,
    (SELECT COUNT(*) FROM devices) as devices_count,
    (SELECT COUNT(*) FROM repairs) as repairs_count,
    (SELECT COUNT(*) FROM sales) as sales_count,
    (SELECT COUNT(*) FROM appointments) as appointments_count,
    (SELECT COUNT(*) FROM parts) as parts_count,
    (SELECT COUNT(*) FROM products) as products_count,
    (SELECT COUNT(*) FROM services) as services_count,
    (SELECT COUNT(*) FROM loyalty_config) as loyalty_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history') AND NOT rowsecurity) = 0
        THEN '✅ RLS ACTIF SUR TOUTES LES TABLES'
        ELSE '❌ RLS INACTIF SUR CERTAINES TABLES'
    END as rls_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND column_name = 'workshop_id' AND table_name IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')) >= 11
        THEN '✅ COLONNES WORKSHOP_ID PRÉSENTES'
        ELSE '❌ COLONNES WORKSHOP_ID MANQUANTES'
    END as workshop_id_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history') AND NOT rowsecurity) = 0
        AND (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND column_name = 'workshop_id' AND table_name IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')) >= 11
        THEN '🎉 ISOLATION FONCTIONNELLE - Toutes les données sont isolées !'
        ELSE '⚠️ PROBLÈME D''ISOLATION DÉTECTÉ - Exécutez le script de correction complète'
    END as final_message;
