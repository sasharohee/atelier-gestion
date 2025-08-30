-- 🚨 VÉRIFICATION URGENTE - Isolation des Données
-- Script simplifié pour diagnostiquer rapidement les problèmes d'isolation
-- Date: 2025-01-23

-- ============================================================================
-- 1. VÉRIFICATION RAPIDE
-- ============================================================================

SELECT '=== VÉRIFICATION RAPIDE ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    value as workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 2. VÉRIFICATION DES DONNÉES PAR PAGE
-- ============================================================================

SELECT '=== VÉRIFICATION DES DONNÉES PAR PAGE ===' as section;

-- Page Clients
SELECT 
    'Page Clients' as page,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_correct_workshop,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END) as clients_wrong_workshop
FROM clients;

-- Page Devices
SELECT 
    'Page Devices' as page,
    COUNT(*) as total_devices,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as devices_correct_workshop,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END) as devices_wrong_workshop
FROM devices;

-- Page Repairs
SELECT 
    'Page Repairs' as page,
    COUNT(*) as total_repairs,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as repairs_correct_workshop,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END) as repairs_wrong_workshop
FROM repairs;

-- Page Sales
SELECT 
    'Page Sales' as page,
    COUNT(*) as total_sales,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as sales_correct_workshop,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END) as sales_wrong_workshop
FROM sales;

-- Page Fidélité
SELECT 
    'Page Fidelite' as page,
    COUNT(*) as total_loyalty_config,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as loyalty_correct_workshop,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL THEN 1 END) as loyalty_wrong_workshop
FROM loyalty_config;

-- ============================================================================
-- 3. TEST D'ISOLATION SIMPLE
-- ============================================================================

SELECT '=== TEST DISOLATION SIMPLE ===' as section;

-- Test 1: Vérifier les clients d'autres ateliers
SELECT 
    'Test 1: Clients d autres ateliers' as test,
    COUNT(*) as clients_from_other_workshops,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Aucun client d autre atelier'
        ELSE 'ECHEC: Clients d autres ateliers detectes'
    END as result
FROM clients 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Test 2: Vérifier les devices d'autres ateliers
SELECT 
    'Test 2: Devices d autres ateliers' as test,
    COUNT(*) as devices_from_other_workshops,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Aucun device d autre atelier'
        ELSE 'ECHEC: Devices d autres ateliers detectes'
    END as result
FROM devices 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Test 3: Vérifier les repairs d'autres ateliers
SELECT 
    'Test 3: Repairs d autres ateliers' as test,
    COUNT(*) as repairs_from_other_workshops,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Aucune reparation d autre atelier'
        ELSE 'ECHEC: Reparations d autres ateliers detectees'
    END as result
FROM repairs 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Test 4: Vérifier les sales d'autres ateliers
SELECT 
    'Test 4: Sales d autres ateliers' as test,
    COUNT(*) as sales_from_other_workshops,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Aucune vente d autre atelier'
        ELSE 'ECHEC: Ventes d autres ateliers detectees'
    END as result
FROM sales 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 4. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé global
SELECT 
    'Resume global' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM devices) as total_devices,
    (SELECT COUNT(*) FROM repairs) as total_repairs,
    (SELECT COUNT(*) FROM sales) as total_sales,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        AND (SELECT COUNT(*) FROM devices WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        AND (SELECT COUNT(*) FROM repairs WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        AND (SELECT COUNT(*) FROM sales WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        THEN 'ISOLATION FONCTIONNELLE'
        ELSE 'PROBLEME DISOLATION DETECTE'
    END as isolation_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        AND (SELECT COUNT(*) FROM devices WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        AND (SELECT COUNT(*) FROM repairs WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        AND (SELECT COUNT(*) FROM sales WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) = 0
        THEN 'L isolation des donnees fonctionne correctement !'
        ELSE 'PROBLEME D ISOLATION DETECTE - Executez le script de correction complete'
    END as final_message;
