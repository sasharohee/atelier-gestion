-- VÉRIFICATION COMPLÈTE DE L'ISOLATION DES DONNÉES - ATELIER DE GESTION
-- Ce script vérifie que toutes les tables appliquent bien l'isolation par utilisateur

-- ============================================================================
-- 1. VÉRIFICATION DES TABLES ET STRUCTURE
-- ============================================================================

-- Vérifier que toutes les tables ont une colonne user_id
SELECT 
    'Tables avec user_id' as check_type,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'user_id'
    AND table_name NOT IN ('users', 'system_settings')
ORDER BY table_name;

-- ============================================================================
-- 2. VÉRIFICATION DES POLITIQUES RLS (Row Level Security)
-- ============================================================================

-- Vérifier les politiques RLS actives
SELECT 
    'Politiques RLS actives' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- 3. VÉRIFICATION DE L'ISOLATION PAR TABLE
-- ============================================================================

-- 3.1 Vérifier l'isolation des clients
SELECT 
    'Isolation clients' as check_type,
    user_id,
    COUNT(*) as total_clients,
    COUNT(DISTINCT email) as unique_emails
FROM public.clients 
GROUP BY user_id
ORDER BY user_id;

-- 3.2 Vérifier l'isolation des appareils
SELECT 
    'Isolation appareils' as check_type,
    user_id,
    COUNT(*) as total_devices,
    COUNT(DISTINCT brand) as unique_brands,
    COUNT(DISTINCT type) as unique_types
FROM public.devices 
GROUP BY user_id
ORDER BY user_id;

-- 3.3 Vérifier l'isolation des services
SELECT 
    'Isolation services' as check_type,
    user_id,
    COUNT(*) as total_services,
    COUNT(DISTINCT name) as unique_names
FROM public.services 
GROUP BY user_id
ORDER BY user_id;

-- 3.4 Vérifier l'isolation des pièces détachées
SELECT 
    'Isolation pièces' as check_type,
    user_id,
    COUNT(*) as total_parts,
    COUNT(DISTINCT name) as unique_names,
    SUM(stock_quantity) as total_stock
FROM public.parts 
GROUP BY user_id
ORDER BY user_id;

-- 3.5 Vérifier l'isolation des produits
SELECT 
    'Isolation produits' as check_type,
    user_id,
    COUNT(*) as total_products,
    COUNT(DISTINCT name) as unique_names,
    SUM(stock_quantity) as total_stock
FROM public.products 
GROUP BY user_id
ORDER BY user_id;

-- 3.6 Vérifier l'isolation des réparations
SELECT 
    'Isolation réparations' as check_type,
    user_id,
    COUNT(*) as total_repairs,
    COUNT(DISTINCT status) as unique_statuses,
    COUNT(DISTINCT client_id) as unique_clients
FROM public.repairs 
GROUP BY user_id
ORDER BY user_id;

-- 3.7 Vérifier l'isolation des rendez-vous
SELECT 
    'Isolation rendez-vous' as check_type,
    user_id,
    COUNT(*) as total_appointments,
    COUNT(DISTINCT client_id) as unique_clients
FROM public.appointments 
GROUP BY user_id
ORDER BY user_id;

-- 3.8 Vérifier l'isolation des ventes
SELECT 
    'Isolation ventes' as check_type,
    user_id,
    COUNT(*) as total_sales,
    SUM(total) as total_revenue,
    COUNT(DISTINCT client_id) as unique_clients
FROM public.sales 
GROUP BY user_id
ORDER BY user_id;

-- 3.9 Vérifier l'isolation des messages
SELECT 
    'Isolation messages' as check_type,
    user_id,
    COUNT(*) as total_messages,
    COUNT(DISTINCT sender_id) as unique_senders,
    COUNT(DISTINCT recipient_id) as unique_recipients
FROM public.messages 
GROUP BY user_id
ORDER BY user_id;

-- ============================================================================
-- 4. VÉRIFICATION DES DONNÉES PARTAGÉES (SI APPLICABLE)
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
WHERE user_id IS NULL;

-- ============================================================================
-- 5. VÉRIFICATION DES RELATIONS ET INTÉGRITÉ
-- ============================================================================

-- Vérifier les clés étrangères et leur isolation
SELECT 
    'Clés étrangères' as check_type,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ============================================================================
-- 6. VÉRIFICATION DES DONNÉES DE DÉMONSTRATION
-- ============================================================================

-- Vérifier que les données de démonstration sont bien isolées
SELECT 
    'Données de démonstration' as check_type,
    user_id,
    COUNT(*) as total_demo_records
FROM (
    SELECT user_id FROM public.clients WHERE email LIKE '%@demo%'
    UNION ALL
    SELECT user_id FROM public.devices WHERE brand LIKE '%Demo%'
    UNION ALL
    SELECT user_id FROM public.services WHERE name LIKE '%Demo%'
    UNION ALL
    SELECT user_id FROM public.parts WHERE name LIKE '%Demo%'
    UNION ALL
    SELECT user_id FROM public.products WHERE name LIKE '%Demo%'
    UNION ALL
    SELECT user_id FROM public.repairs WHERE description LIKE '%Demo%'
) demo_data
GROUP BY user_id
ORDER BY user_id;

-- ============================================================================
-- 7. RÉSUMÉ DE L'ISOLATION
-- ============================================================================

-- Résumé global de l'isolation
WITH isolation_summary AS (
    SELECT 
        'clients' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.clients
    UNION ALL
    SELECT 
        'devices' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.devices
    UNION ALL
    SELECT 
        'services' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.services
    UNION ALL
    SELECT 
        'parts' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.parts
    UNION ALL
    SELECT 
        'products' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.products
    UNION ALL
    SELECT 
        'repairs' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.repairs
    UNION ALL
    SELECT 
        'appointments' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.appointments
    UNION ALL
    SELECT 
        'sales' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.sales
    UNION ALL
    SELECT 
        'messages' as table_name,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_records
    FROM public.messages
)
SELECT 
    'Résumé isolation' as check_type,
    table_name,
    unique_users,
    total_records,
    CASE 
        WHEN unique_users > 1 THEN 'MULTI-UTILISATEUR'
        WHEN unique_users = 1 THEN 'ISOLÉ'
        ELSE 'VIDE'
    END as isolation_status
FROM isolation_summary
ORDER BY table_name;

-- ============================================================================
-- 8. VÉRIFICATION DES UTILISATEURS ACTIFS
-- ============================================================================

-- Vérifier les utilisateurs qui ont des données
SELECT 
    'Utilisateurs avec données' as check_type,
    u.id as user_id,
    u.email,
    COUNT(DISTINCT c.id) as clients_count,
    COUNT(DISTINCT d.id) as devices_count,
    COUNT(DISTINCT s.id) as services_count,
    COUNT(DISTINCT p.id) as parts_count,
    COUNT(DISTINCT pr.id) as products_count,
    COUNT(DISTINCT r.id) as repairs_count,
    COUNT(DISTINCT a.id) as appointments_count,
    COUNT(DISTINCT sa.id) as sales_count,
    COUNT(DISTINCT m.id) as messages_count
FROM public.users u
LEFT JOIN public.clients c ON u.id = c.user_id
LEFT JOIN public.devices d ON u.id = d.user_id
LEFT JOIN public.services s ON u.id = s.user_id
LEFT JOIN public.parts p ON u.id = p.user_id
LEFT JOIN public.products pr ON u.id = pr.user_id
LEFT JOIN public.repairs r ON u.id = r.user_id
LEFT JOIN public.appointments a ON u.id = a.user_id
LEFT JOIN public.sales sa ON u.id = sa.user_id
LEFT JOIN public.messages m ON u.id = m.user_id
GROUP BY u.id, u.email
HAVING 
    COUNT(DISTINCT c.id) > 0 OR
    COUNT(DISTINCT d.id) > 0 OR
    COUNT(DISTINCT s.id) > 0 OR
    COUNT(DISTINCT p.id) > 0 OR
    COUNT(DISTINCT pr.id) > 0 OR
    COUNT(DISTINCT r.id) > 0 OR
    COUNT(DISTINCT a.id) > 0 OR
    COUNT(DISTINCT sa.id) > 0 OR
    COUNT(DISTINCT m.id) > 0
ORDER BY u.email;
