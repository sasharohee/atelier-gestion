-- ============================================================================
-- VÉRIFICATION DES TABLES EXISTANTES
-- ============================================================================
-- Ce script vérifie quelles tables existent réellement dans la base de données

-- ============================================================================
-- 1. VÉRIFICATION DES TABLES PRINCIPALES
-- ============================================================================

SELECT 
    'Tables principales existantes' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'clients',
    'repairs', 
    'devices',
    'device_models',
    'sales',
    'sale_items',
    'products',
    'parts',
    'appointments',
    'users',
    'loyalty_points',
    'loyalty_tiers_advanced',
    'system_settings'
)
ORDER BY table_name;

-- ============================================================================
-- 2. VÉRIFICATION DES VUES EXISTANTES
-- ============================================================================

SELECT 
    'Vues existantes' as info,
    viewname,
    viewowner
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'sales_by_category',
    'repairs_filtered',
    'clients_all',
    'repair_tracking_view',
    'clients_filtrés',
    'repair_history_view',
    'clients_isolated',
    'clients_filtered',
    'repairs_isolated',
    'loyalty_dashboard',
    'loyalty_dashboard_iso',
    'device_models_my_mode',
    'clients_isolated_final'
)
ORDER BY viewname;

-- ============================================================================
-- 3. VÉRIFICATION DE LA STRUCTURE DE LA TABLE SALES
-- ============================================================================

SELECT 
    'Structure de la table sales' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'sales'
ORDER BY ordinal_position;

-- ============================================================================
-- 4. VÉRIFICATION DE LA STRUCTURE DE LA TABLE SALE_ITEMS (si elle existe)
-- ============================================================================

SELECT 
    'Structure de la table sale_items' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'sale_items'
ORDER BY ordinal_position;

-- ============================================================================
-- 5. VÉRIFICATION DES POLITIQUES RLS EXISTANTES
-- ============================================================================

SELECT 
    'Politiques RLS existantes' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename, policyname;

-- ============================================================================
-- 6. VÉRIFICATION DES COLONNES WORKSHOP_ID
-- ============================================================================

SELECT 
    'Colonnes workshop_id existantes' as info,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND column_name = 'workshop_id'
ORDER BY table_name;

-- ============================================================================
-- 7. VÉRIFICATION DES DONNÉES DANS SYSTEM_SETTINGS
-- ============================================================================

SELECT 
    'Paramètres système' as info,
    key,
    value,
    description
FROM system_settings
ORDER BY key;

-- ============================================================================
-- 8. RÉSUMÉ DE L'ÉTAT ACTUEL
-- ============================================================================

SELECT 
    'Résumé de l''état actuel' as info,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public') as total_tables,
    (SELECT COUNT(*) FROM pg_views WHERE schemaname = 'public') as total_views,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as total_policies,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND column_name = 'workshop_id') as tables_with_workshop_id;
