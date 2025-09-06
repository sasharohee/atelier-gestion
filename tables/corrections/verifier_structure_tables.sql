-- VÉRIFICATION DE LA STRUCTURE DES TABLES
-- Ce script vérifie la structure exacte des tables avant les vérifications d'isolation

-- ============================================================================
-- 1. STRUCTURE DE LA TABLE CLIENTS
-- ============================================================================

SELECT 
    'Structure clients' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. STRUCTURE DE LA TABLE DEVICES
-- ============================================================================

SELECT 
    'Structure devices' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. STRUCTURE DE LA TABLE SERVICES
-- ============================================================================

SELECT 
    'Structure services' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'services'
ORDER BY ordinal_position;

-- ============================================================================
-- 4. STRUCTURE DE LA TABLE PARTS
-- ============================================================================

SELECT 
    'Structure parts' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'parts'
ORDER BY ordinal_position;

-- ============================================================================
-- 5. STRUCTURE DE LA TABLE PRODUCTS
-- ============================================================================

SELECT 
    'Structure products' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;

-- ============================================================================
-- 6. STRUCTURE DE LA TABLE REPAIRS
-- ============================================================================

SELECT 
    'Structure repairs' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'repairs'
ORDER BY ordinal_position;

-- ============================================================================
-- 7. STRUCTURE DE LA TABLE APPOINTMENTS
-- ============================================================================

SELECT 
    'Structure appointments' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
ORDER BY ordinal_position;

-- ============================================================================
-- 8. STRUCTURE DE LA TABLE SALES
-- ============================================================================

SELECT 
    'Structure sales' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sales'
ORDER BY ordinal_position;

-- ============================================================================
-- 9. STRUCTURE DE LA TABLE MESSAGES
-- ============================================================================

SELECT 
    'Structure messages' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'messages'
ORDER BY ordinal_position;

-- ============================================================================
-- 10. STRUCTURE DE LA TABLE SYSTEM_SETTINGS
-- ============================================================================

SELECT 
    'Structure system_settings' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;

-- ============================================================================
-- 11. VÉRIFICATION DE L'EXISTENCE DES TABLES
-- ============================================================================

SELECT 
    'Tables existantes' as check_type,
    table_name,
    CASE 
        WHEN table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'appointments', 'sales', 'messages', 'system_settings') 
        THEN 'TABLE PRINCIPALE'
        ELSE 'TABLE SYSTÈME'
    END as table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================================================
-- 12. VÉRIFICATION DES COLONNES USER_ID
-- ============================================================================

SELECT 
    'Colonnes user_id' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'user_id'
    AND table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'appointments', 'sales', 'messages', 'system_settings')
ORDER BY table_name;
