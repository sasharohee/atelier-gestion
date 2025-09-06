-- VÉRIFICATION SIMPLE DE L'ISOLATION DES DONNÉES
-- Ce script vérifie l'isolation de base sans colonnes problématiques

-- ============================================================================
-- 1. VÉRIFICATION DE L'EXISTENCE DES TABLES
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
    AND table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'appointments', 'sales', 'messages', 'system_settings')
ORDER BY table_name;

-- ============================================================================
-- 2. VÉRIFICATION DES COLONNES USER_ID
-- ============================================================================

SELECT 
    'Colonnes user_id' as check_type,
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = t.table_name 
                AND column_name = 'user_id'
        ) THEN 'PRÉSENTE'
        ELSE 'MANQUANTE'
    END as user_id_status
FROM (
    SELECT 'clients' as table_name
    UNION ALL SELECT 'devices'
    UNION ALL SELECT 'services'
    UNION ALL SELECT 'parts'
    UNION ALL SELECT 'products'
    UNION ALL SELECT 'repairs'
    UNION ALL SELECT 'appointments'
    UNION ALL SELECT 'sales'
    UNION ALL SELECT 'messages'
    UNION ALL SELECT 'system_settings'
) t
ORDER BY table_name;

-- ============================================================================
-- 3. VÉRIFICATION DE L'ISOLATION PAR TABLE (SIMPLIFIÉE)
-- ============================================================================

-- 3.1 Isolation des clients
SELECT 
    'Isolation clients' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.clients 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.2 Isolation des appareils
SELECT 
    'Isolation devices' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.devices 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'devices' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.3 Isolation des services
SELECT 
    'Isolation services' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.services 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'services' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.4 Isolation des pièces détachées
SELECT 
    'Isolation parts' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.parts 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'parts' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.5 Isolation des produits
SELECT 
    'Isolation products' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.products 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.6 Isolation des réparations
SELECT 
    'Isolation repairs' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.repairs 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'repairs' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.7 Isolation des rendez-vous
SELECT 
    'Isolation appointments' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.appointments 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'appointments' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.8 Isolation des ventes
SELECT 
    'Isolation sales' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.sales 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.9 Isolation des messages (sans colonnes problématiques)
SELECT 
    'Isolation messages' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.messages 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'messages' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 3.10 Isolation des paramètres système
SELECT 
    'Isolation system_settings' as check_type,
    user_id,
    COUNT(*) as total_records
FROM public.system_settings 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'system_settings' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- ============================================================================
-- 4. VÉRIFICATION DES DONNÉES SANS USER_ID
-- ============================================================================

-- Vérifier s'il y a des données sans user_id (problématique)
SELECT 
    'Données sans user_id' as check_type,
    'clients' as table_name,
    COUNT(*) as count
FROM public.clients 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'devices' as table_name,
    COUNT(*) as count
FROM public.devices 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'services' as table_name,
    COUNT(*) as count
FROM public.services 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'parts' as table_name,
    COUNT(*) as count
FROM public.parts 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'products' as table_name,
    COUNT(*) as count
FROM public.products 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'repairs' as table_name,
    COUNT(*) as count
FROM public.repairs 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'appointments' as table_name,
    COUNT(*) as count
FROM public.appointments 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'sales' as table_name,
    COUNT(*) as count
FROM public.sales 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'messages' as table_name,
    COUNT(*) as count
FROM public.messages 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'system_settings' as table_name,
    COUNT(*) as count
FROM public.system_settings 
WHERE user_id IS NULL;

-- ============================================================================
-- 5. RÉSUMÉ SIMPLE DE L'ISOLATION
-- ============================================================================

-- Résumé global de l'isolation (version simple)
WITH isolation_summary AS (
    SELECT 
        'clients' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'clients')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'clients' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.clients)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'clients')
            THEN (SELECT COUNT(*) FROM public.clients)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'devices' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'devices')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.devices)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'devices')
            THEN (SELECT COUNT(*) FROM public.devices)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'services' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'services')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'services' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.services)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'services')
            THEN (SELECT COUNT(*) FROM public.services)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'parts' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'parts')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'parts' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.parts)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'parts')
            THEN (SELECT COUNT(*) FROM public.parts)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'products' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'products')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.products)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'products')
            THEN (SELECT COUNT(*) FROM public.products)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'repairs' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'repairs')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'repairs' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.repairs)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'repairs')
            THEN (SELECT COUNT(*) FROM public.repairs)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'appointments' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'appointments')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'appointments' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.appointments)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'appointments')
            THEN (SELECT COUNT(*) FROM public.appointments)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'sales' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.sales)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales')
            THEN (SELECT COUNT(*) FROM public.sales)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'messages' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.messages)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages')
            THEN (SELECT COUNT(*) FROM public.messages)
            ELSE 0
        END as total_records
    UNION ALL
    SELECT 
        'system_settings' as table_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_settings')
                AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'system_settings' AND column_name = 'user_id')
            THEN (SELECT COUNT(DISTINCT user_id) FROM public.system_settings)
            ELSE 0
        END as unique_users,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_settings')
            THEN (SELECT COUNT(*) FROM public.system_settings)
            ELSE 0
        END as total_records
)
SELECT 
    'Résumé isolation simple' as check_type,
    table_name,
    unique_users,
    total_records,
    CASE 
        WHEN unique_users > 1 THEN 'MULTI-UTILISATEUR'
        WHEN unique_users = 1 THEN 'ISOLÉ'
        WHEN total_records = 0 THEN 'VIDE'
        ELSE 'NON ISOLÉ'
    END as isolation_status
FROM isolation_summary
ORDER BY table_name;
