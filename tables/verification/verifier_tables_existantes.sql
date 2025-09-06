-- 🔍 VÉRIFICATION DES TABLES EXISTANTES
-- Script pour vérifier quelles tables existent réellement
-- Date: 2025-01-23

-- ============================================================================
-- 1. LISTE DE TOUTES LES TABLES
-- ============================================================================

SELECT '=== LISTE DE TOUTES LES TABLES ===' as section;

-- Lister toutes les tables du schéma public
SELECT 
    'Tables existantes' as info,
    tablename,
    schemaname,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 2. TABLES AVEC WORKSHOP_ID
-- ============================================================================

SELECT '=== TABLES AVEC WORKSHOP_ID ===' as section;

-- Vérifier quelles tables ont une colonne workshop_id
SELECT 
    'Tables avec workshop_id' as info,
    t.table_name,
    c.column_name,
    c.data_type
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
    AND c.column_name = 'workshop_id'
ORDER BY t.table_name;

-- ============================================================================
-- 3. TABLES PRINCIPALES POUR L'ISOLATION
-- ============================================================================

SELECT '=== TABLES PRINCIPALES POUR L''ISOLATION ===' as section;

-- Vérifier l'existence des tables principales
SELECT 
    'Existence des tables principales' as info,
    'clients' as table_name,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'clients' AND table_schema = 'public')
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as status;

SELECT 
    'Existence des tables principales' as info,
    'repairs' as table_name,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'repairs' AND table_schema = 'public')
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as status;

SELECT 
    'Existence des tables principales' as info,
    'loyalty_points' as table_name,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_points' AND table_schema = 'public')
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as status;

SELECT 
    'Existence des tables principales' as info,
    'loyalty_history' as table_name,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_history' AND table_schema = 'public')
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as status;

SELECT 
    'Existence des tables principales' as info,
    'loyalty_dashboard' as table_name,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_dashboard' AND table_schema = 'public')
        THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as status;

-- ============================================================================
-- 4. TABLES LIÉES À LA FIDÉLITÉ
-- ============================================================================

SELECT '=== TABLES LIÉES À LA FIDÉLITÉ ===' as section;

-- Chercher toutes les tables contenant "loyalty" dans le nom
SELECT 
    'Tables contenant "loyalty"' as info,
    tablename,
    schemaname
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename LIKE '%loyalty%'
ORDER BY tablename;

-- Chercher toutes les tables contenant "fidelite" dans le nom
SELECT 
    'Tables contenant "fidelite"' as info,
    tablename,
    schemaname
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename LIKE '%fidelite%'
ORDER BY tablename;

-- ============================================================================
-- 5. STRUCTURE DE LA TABLE CLIENTS
-- ============================================================================

SELECT '=== STRUCTURE DE LA TABLE CLIENTS ===' as section;

-- Vérifier la structure de la table clients si elle existe
SELECT 
    'Structure table clients' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- 6. STRUCTURE DE LA TABLE REPAIRS
-- ============================================================================

SELECT '=== STRUCTURE DE LA TABLE REPAIRS ===' as section;

-- Vérifier la structure de la table repairs si elle existe
SELECT 
    'Structure table repairs' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repairs' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- 7. RÉSUMÉ DES TABLES DISPONIBLES
-- ============================================================================

SELECT '=== RÉSUMÉ DES TABLES DISPONIBLES ===' as section;

-- Résumé des tables disponibles pour l'isolation
SELECT 
    'Résumé des tables pour isolation' as info,
    COUNT(*) as total_tables,
    COUNT(CASE WHEN tablename IN ('clients', 'repairs') THEN 1 END) as tables_principales,
    COUNT(CASE WHEN tablename LIKE '%loyalty%' OR tablename LIKE '%fidelite%' THEN 1 END) as tables_fidelite,
    COUNT(CASE WHEN tablename LIKE '%workshop%' OR tablename LIKE '%atelier%' THEN 1 END) as tables_workshop
FROM pg_tables 
WHERE schemaname = 'public';

-- Message final
SELECT 
    '🎯 DIAGNOSTIC: Vérification des tables terminée' as final_message,
    'Adaptez la solution d''isolation aux tables réellement existantes.' as instruction;
