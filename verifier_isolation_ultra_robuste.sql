-- VÉRIFICATION ULTRA-ROBUSTE DE L'ISOLATION DES DONNÉES
-- Ce script vérifie l'isolation en vérifiant l'existence de chaque colonne avant utilisation

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
-- 2. VÉRIFICATION DES COLONNES PAR TABLE
-- ============================================================================

-- Vérifier toutes les colonnes importantes par table
SELECT 
    'Colonnes par table' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'appointments', 'sales', 'messages', 'system_settings')
    AND column_name IN ('user_id', 'id', 'email', 'name', 'brand', 'type', 'stock_quantity', 'status', 'client_id', 'total', 'sender_id', 'recipient_id', 'key', 'value')
ORDER BY table_name, column_name;

-- ============================================================================
-- 3. VÉRIFICATION DE L'ISOLATION PAR TABLE (AVEC VÉRIFICATION DE COLONNES)
-- ============================================================================

-- 3.1 Isolation des clients (vérification des colonnes)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'clients') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'clients' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'clients' AND column_name = 'email') THEN
                RAISE NOTICE 'Table clients: OK - user_id et email présents';
            ELSE
                RAISE NOTICE 'Table clients: WARNING - user_id présent mais email manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table clients: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table clients: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.2 Isolation des appareils
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'devices') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'brand') THEN
                RAISE NOTICE 'Table devices: OK - user_id et brand présents';
            ELSE
                RAISE NOTICE 'Table devices: WARNING - user_id présent mais brand manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table devices: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table devices: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.3 Isolation des services
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'services') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'services' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'services' AND column_name = 'name') THEN
                RAISE NOTICE 'Table services: OK - user_id et name présents';
            ELSE
                RAISE NOTICE 'Table services: WARNING - user_id présent mais name manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table services: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table services: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.4 Isolation des pièces détachées
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'parts') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'parts' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'parts' AND column_name = 'stock_quantity') THEN
                RAISE NOTICE 'Table parts: OK - user_id et stock_quantity présents';
            ELSE
                RAISE NOTICE 'Table parts: WARNING - user_id présent mais stock_quantity manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table parts: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table parts: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.5 Isolation des produits
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'products') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'stock_quantity') THEN
                RAISE NOTICE 'Table products: OK - user_id et stock_quantity présents';
            ELSE
                RAISE NOTICE 'Table products: WARNING - user_id présent mais stock_quantity manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table products: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table products: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.6 Isolation des réparations
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'repairs') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'repairs' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'repairs' AND column_name = 'status') THEN
                RAISE NOTICE 'Table repairs: OK - user_id et status présents';
            ELSE
                RAISE NOTICE 'Table repairs: WARNING - user_id présent mais status manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table repairs: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table repairs: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.7 Isolation des rendez-vous
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'appointments') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'appointments' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'appointments' AND column_name = 'client_id') THEN
                RAISE NOTICE 'Table appointments: OK - user_id et client_id présents';
            ELSE
                RAISE NOTICE 'Table appointments: WARNING - user_id présent mais client_id manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table appointments: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table appointments: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.8 Isolation des ventes
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total') THEN
                RAISE NOTICE 'Table sales: OK - user_id et total présents';
            ELSE
                RAISE NOTICE 'Table sales: WARNING - user_id présent mais total manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table sales: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table sales: ERROR - table n''existe pas';
    END IF;
END $$;

-- 3.9 Isolation des messages
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'user_id') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'sender_id') THEN
                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'recipient_id') THEN
                    RAISE NOTICE 'Table messages: OK - user_id, sender_id et recipient_id présents';
                ELSE
                    RAISE NOTICE 'Table messages: WARNING - user_id et sender_id présents mais recipient_id manquant';
                END IF;
            ELSE
                RAISE NOTICE 'Table messages: WARNING - user_id présent mais sender_id manquant';
            END IF;
        ELSE
            RAISE NOTICE 'Table messages: ERROR - colonne user_id manquante';
        END IF;
    ELSE
        RAISE NOTICE 'Table messages: ERROR - table n''existe pas';
    END IF;
END $$;

-- ============================================================================
-- 4. REQUÊTES D'ISOLATION AVEC VÉRIFICATION DE COLONNES
-- ============================================================================

-- 4.1 Isolation des clients (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'email'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.2 Isolation des appareils (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'devices' 
        AND column_name = 'brand'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.3 Isolation des services (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'services' 
        AND column_name = 'name'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.4 Isolation des pièces (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'parts' 
        AND column_name = 'stock_quantity'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.5 Isolation des produits (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'stock_quantity'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.6 Isolation des réparations (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'repairs' 
        AND column_name = 'status'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.7 Isolation des rendez-vous (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'appointments' 
        AND column_name = 'client_id'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.8 Isolation des ventes (vérification complète)
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
    AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'total'
)
GROUP BY user_id
ORDER BY user_id;

-- 4.9 Isolation des messages (vérification complète)
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
-- 5. RÉSUMÉ DE L'ISOLATION AVEC VÉRIFICATION DE COLONNES
-- ============================================================================

-- Résumé global de l'isolation (version ultra-robuste)
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
    'Résumé isolation ultra-robuste' as check_type,
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
