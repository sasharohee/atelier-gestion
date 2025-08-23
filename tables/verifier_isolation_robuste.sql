-- VÉRIFICATION ROBUSTE DE L'ISOLATION DES DONNÉES
-- Ce script vérifie l'isolation en gérant les erreurs de colonnes manquantes

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
-- 2. VÉRIFICATION DES COLONNES USER_ID PAR TABLE
-- ============================================================================

-- Vérifier l'existence de la colonne user_id dans chaque table
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
-- 3. VÉRIFICATION DE L'ISOLATION PAR TABLE (AVEC GESTION D'ERREURS)
-- ============================================================================

-- 3.1 Vérifier l'isolation des clients (si la table existe)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'clients') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'clients' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation clients...';
            -- La requête sera exécutée dans le script principal
        ELSE
            RAISE NOTICE 'Table clients existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table clients n''existe pas';
    END IF;
END $$;

-- 3.2 Vérifier l'isolation des appareils
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'devices') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation devices...';
        ELSE
            RAISE NOTICE 'Table devices existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table devices n''existe pas';
    END IF;
END $$;

-- 3.3 Vérifier l'isolation des services
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'services') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'services' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation services...';
        ELSE
            RAISE NOTICE 'Table services existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table services n''existe pas';
    END IF;
END $$;

-- 3.4 Vérifier l'isolation des pièces détachées
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'parts') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'parts' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation parts...';
        ELSE
            RAISE NOTICE 'Table parts existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table parts n''existe pas';
    END IF;
END $$;

-- 3.5 Vérifier l'isolation des produits
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'products') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation products...';
        ELSE
            RAISE NOTICE 'Table products existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table products n''existe pas';
    END IF;
END $$;

-- 3.6 Vérifier l'isolation des réparations
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'repairs') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'repairs' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation repairs...';
        ELSE
            RAISE NOTICE 'Table repairs existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table repairs n''existe pas';
    END IF;
END $$;

-- 3.7 Vérifier l'isolation des rendez-vous
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'appointments') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'appointments' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation appointments...';
        ELSE
            RAISE NOTICE 'Table appointments existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table appointments n''existe pas';
    END IF;
END $$;

-- 3.8 Vérifier l'isolation des ventes
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation sales...';
        ELSE
            RAISE NOTICE 'Table sales existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table sales n''existe pas';
    END IF;
END $$;

-- 3.9 Vérifier l'isolation des messages
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'user_id') THEN
            RAISE NOTICE 'Vérification isolation messages...';
        ELSE
            RAISE NOTICE 'Table messages existe mais colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table messages n''existe pas';
    END IF;
END $$;

-- ============================================================================
-- 4. REQUÊTES D'ISOLATION CONDITIONNELLES
-- ============================================================================

-- 4.1 Isolation des clients (si la table et la colonne existent)
SELECT 
    'Isolation clients' as check_type,
    user_id,
    COUNT(*) as total_clients,
    COUNT(DISTINCT email) as unique_emails
FROM public.clients 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.2 Isolation des appareils (si la table et la colonne existent)
SELECT 
    'Isolation devices' as check_type,
    user_id,
    COUNT(*) as total_devices,
    COUNT(DISTINCT brand) as unique_brands,
    COUNT(DISTINCT type) as unique_types
FROM public.devices 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'devices' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.3 Isolation des services (si la table et la colonne existent)
SELECT 
    'Isolation services' as check_type,
    user_id,
    COUNT(*) as total_services,
    COUNT(DISTINCT name) as unique_names
FROM public.services 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'services' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.4 Isolation des pièces (si la table et la colonne existent)
SELECT 
    'Isolation parts' as check_type,
    user_id,
    COUNT(*) as total_parts,
    COUNT(DISTINCT name) as unique_names,
    SUM(stock_quantity) as total_stock
FROM public.parts 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'parts' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.5 Isolation des produits (si la table et la colonne existent)
SELECT 
    'Isolation products' as check_type,
    user_id,
    COUNT(*) as total_products,
    COUNT(DISTINCT name) as unique_names,
    SUM(stock_quantity) as total_stock
FROM public.products 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.6 Isolation des réparations (si la table et la colonne existent)
SELECT 
    'Isolation repairs' as check_type,
    user_id,
    COUNT(*) as total_repairs,
    COUNT(DISTINCT status) as unique_statuses,
    COUNT(DISTINCT client_id) as unique_clients
FROM public.repairs 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'repairs' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.7 Isolation des rendez-vous (si la table et la colonne existent)
SELECT 
    'Isolation appointments' as check_type,
    user_id,
    COUNT(*) as total_appointments,
    COUNT(DISTINCT client_id) as unique_clients
FROM public.appointments 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'appointments' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.8 Isolation des ventes (si la table et la colonne existent)
SELECT 
    'Isolation sales' as check_type,
    user_id,
    COUNT(*) as total_sales,
    SUM(total) as total_revenue,
    COUNT(DISTINCT client_id) as unique_clients
FROM public.sales 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'user_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.9 Isolation des messages (si la table et les colonnes existent)
SELECT 
    'Isolation messages' as check_type,
    user_id,
    COUNT(*) as total_messages,
    COUNT(DISTINCT sender_id) as unique_senders,
    COUNT(DISTINCT recipient_id) as unique_recipients
FROM public.messages 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'messages' 
        AND column_name = 'user_id'
)
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'messages' 
        AND column_name = 'sender_id'
)
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'messages' 
        AND column_name = 'recipient_id'
)
GROUP BY user_id
ORDER BY user_id;

-- ============================================================================
-- 5. RÉSUMÉ DE L'ISOLATION
-- ============================================================================

-- Résumé global de l'isolation (version robuste)
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
)
SELECT 
    'Résumé isolation robuste' as check_type,
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
