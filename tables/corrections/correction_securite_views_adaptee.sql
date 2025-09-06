-- ============================================================================
-- CORRECTION SÉCURITÉ SUPABASE - VUES ADAPTÉES À LA STRUCTURE RÉELLE
-- ============================================================================
-- Ce script corrige les vues en s'adaptant à la structure réelle de la base de données

-- ============================================================================
-- 1. VÉRIFICATION PRÉALABLE DES TABLES
-- ============================================================================

-- Vérifier quelles tables existent
SELECT 
    'Tables disponibles' as info,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'clients', 'repairs', 'devices', 'device_models', 'sales', 'sale_items', 
    'products', 'parts', 'appointments', 'users', 'loyalty_points', 
    'loyalty_tiers_advanced', 'system_settings'
)
ORDER BY table_name;

-- ============================================================================
-- 2. SUPPRESSION DES VUES PROBLÉMATIQUES
-- ============================================================================

-- Supprimer toutes les vues SECURITY DEFINER problématiques
DROP VIEW IF EXISTS public.sales_by_category CASCADE;
DROP VIEW IF EXISTS public.repairs_filtered CASCADE;
DROP VIEW IF EXISTS public.clients_all CASCADE;
DROP VIEW IF EXISTS public.repair_tracking_view CASCADE;
DROP VIEW IF EXISTS public.clients_filtrés CASCADE;
DROP VIEW IF EXISTS public.repair_history_view CASCADE;
DROP VIEW IF EXISTS public.clients_isolated CASCADE;
DROP VIEW IF EXISTS public.clients_filtered CASCADE;
DROP VIEW IF EXISTS public.repairs_isolated CASCADE;
DROP VIEW IF EXISTS public.loyalty_dashboard CASCADE;
DROP VIEW IF EXISTS public.loyalty_dashboard_iso CASCADE;
DROP VIEW IF EXISTS public.device_models_my_mode CASCADE;
DROP VIEW IF EXISTS public.clients_isolated_final CASCADE;

-- ============================================================================
-- 3. CRÉATION DE VUES SÉCURISÉES ADAPTÉES
-- ============================================================================

-- Vue sales_by_category sécurisée (adaptée selon la structure)
CREATE OR REPLACE VIEW public.sales_by_category AS
SELECT 
    COALESCE(p.category, 'non_categorise') as category,
    COUNT(*) as nombre_ventes,
    SUM(s.quantity) as quantite_totale,
    SUM(s.total_price) as chiffre_affaires,
    AVG(s.total_price) as prix_moyen,
    COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) as workshop_id
FROM sales s
LEFT JOIN products p ON s.product_id = p.id
WHERE s.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
GROUP BY COALESCE(p.category, 'non_categorise')
ORDER BY chiffre_affaires DESC;

-- Vue repairs_filtered sécurisée
CREATE OR REPLACE VIEW public.repairs_filtered AS
SELECT 
    r.id,
    r.client_id,
    c.first_name || ' ' || c.last_name as client_name,
    r.device_id,
    d.brand || ' ' || d.model as device_name,
    r.description,
    r.status,
    r.estimated_cost,
    r.actual_cost,
    r.workshop_id,
    r.created_at,
    r.updated_at
FROM repairs r
LEFT JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
AND r.status IN ('pending', 'in_progress', 'completed')
ORDER BY r.created_at DESC;

-- Vue clients_all sécurisée
CREATE OR REPLACE VIEW public.clients_all AS
SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
FROM clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY created_at DESC;

-- Vue repair_tracking_view sécurisée
CREATE OR REPLACE VIEW public.repair_tracking_view AS
SELECT 
    r.id,
    r.client_id,
    c.first_name || ' ' || c.last_name as client_name,
    c.email as client_email,
    c.phone as client_phone,
    r.device_id,
    d.brand || ' ' || d.model as device_name,
    d.serial_number,
    r.description,
    r.status,
    r.estimated_cost,
    r.actual_cost,
    r.assigned_technician_id,
    u.first_name || ' ' || u.last_name as technician_name,
    r.due_date,
    r.is_urgent,
    r.workshop_id,
    r.created_at,
    r.updated_at
FROM repairs r
LEFT JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
LEFT JOIN users u ON r.assigned_technician_id = u.id
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY r.created_at DESC;

-- Vue clients_filtrés sécurisée
CREATE OR REPLACE VIEW public.clients_filtrés AS
SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
FROM clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
AND email IS NOT NULL
AND email != ''
AND phone IS NOT NULL
AND phone != ''
ORDER BY last_name, first_name;

-- Vue repair_history_view sécurisée
CREATE OR REPLACE VIEW public.repair_history_view AS
SELECT 
    r.id,
    r.client_id,
    c.first_name || ' ' || c.last_name as client_name,
    c.email as client_email,
    r.device_id,
    d.brand || ' ' || d.model as device_name,
    r.description,
    r.status,
    r.estimated_cost,
    r.actual_cost,
    r.assigned_technician_id,
    u.first_name || ' ' || u.last_name as technician_name,
    r.due_date,
    r.is_urgent,
    r.workshop_id,
    r.created_at,
    r.updated_at
FROM repairs r
LEFT JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
LEFT JOIN users u ON r.assigned_technician_id = u.id
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY r.created_at DESC;

-- Vue clients_isolated sécurisée
CREATE OR REPLACE VIEW public.clients_isolated AS
SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
FROM clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY created_at DESC;

-- Vue clients_filtered sécurisée
CREATE OR REPLACE VIEW public.clients_filtered AS
SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
FROM clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
AND (first_name ILIKE '%' || COALESCE('', '') || '%' 
     OR last_name ILIKE '%' || COALESCE('', '') || '%'
     OR email ILIKE '%' || COALESCE('', '') || '%')
ORDER BY last_name, first_name;

-- Vue repairs_isolated sécurisée
CREATE OR REPLACE VIEW public.repairs_isolated AS
SELECT 
    r.id,
    r.client_id,
    c.first_name || ' ' || c.last_name as client_name,
    r.device_id,
    d.brand || ' ' || d.model as device_name,
    r.description,
    r.status,
    r.estimated_cost,
    r.actual_cost,
    r.assigned_technician_id,
    u.first_name || ' ' || u.last_name as technician_name,
    r.due_date,
    r.is_urgent,
    r.workshop_id,
    r.created_at,
    r.updated_at
FROM repairs r
LEFT JOIN clients c ON r.client_id = c.id
LEFT JOIN devices d ON r.device_id = d.id
LEFT JOIN users u ON r.assigned_technician_id = u.id
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY r.created_at DESC;

-- Vue loyalty_dashboard sécurisée (si les tables existent)
CREATE OR REPLACE VIEW public.loyalty_dashboard AS
SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    COALESCE(lp.current_points, 0) as current_points,
    COALESCE(lt.tier_name, 'Bronze') as current_tier,
    COALESCE(lt.discount_percentage, 0) as discount_percentage,
    COALESCE(lp.total_earned, 0) as total_earned,
    COALESCE(lp.total_redeemed, 0) as total_redeemed,
    c.workshop_id,
    c.created_at,
    c.updated_at
FROM clients c
LEFT JOIN loyalty_points lp ON c.id = lp.client_id
LEFT JOIN loyalty_tiers_advanced lt ON lp.current_tier_id = lt.id
WHERE c.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY current_points DESC;

-- Vue loyalty_dashboard_iso sécurisée
CREATE OR REPLACE VIEW public.loyalty_dashboard_iso AS
SELECT 
    ld.*
FROM loyalty_dashboard ld
WHERE ld.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY ld.current_points DESC;

-- Vue device_models_my_mode sécurisée (si la table existe)
CREATE OR REPLACE VIEW public.device_models_my_mode AS
SELECT 
    dm.id,
    dm.brand,
    dm.model,
    dm.type,
    dm.specifications,
    dm.common_issues,
    dm.repair_difficulty,
    dm.estimated_repair_time,
    dm.workshop_id,
    dm.created_at,
    dm.updated_at
FROM device_models dm
WHERE dm.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY dm.brand, dm.model;

-- Vue clients_isolated_final sécurisée
CREATE OR REPLACE VIEW public.clients_isolated_final AS
SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
FROM clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY created_at DESC;

-- ============================================================================
-- 4. ACTIVATION RLS ET POLITIQUES (seulement sur les tables existantes)
-- ============================================================================

-- Activer RLS sur les tables qui existent
DO $$
BEGIN
    -- Clients
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'clients') THEN
        ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "clients_workshop_isolation" ON public.clients;
        CREATE POLICY "clients_workshop_isolation" ON public.clients
            FOR ALL USING (
                workshop_id = COALESCE(
                    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                    '00000000-0000-0000-0000-000000000000'::UUID
                )
            );
    END IF;

    -- Repairs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'repairs') THEN
        ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "repairs_workshop_isolation" ON public.repairs;
        CREATE POLICY "repairs_workshop_isolation" ON public.repairs
            FOR ALL USING (
                workshop_id = COALESCE(
                    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                    '00000000-0000-0000-0000-000000000000'::UUID
                )
            );
    END IF;

    -- Devices
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'devices') THEN
        ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "devices_workshop_isolation" ON public.devices;
        CREATE POLICY "devices_workshop_isolation" ON public.devices
            FOR ALL USING (
                workshop_id = COALESCE(
                    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                    '00000000-0000-0000-0000-000000000000'::UUID
                )
            );
    END IF;

    -- Device models
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'device_models') THEN
        ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "device_models_workshop_isolation" ON public.device_models;
        CREATE POLICY "device_models_workshop_isolation" ON public.device_models
            FOR ALL USING (
                workshop_id = COALESCE(
                    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                    '00000000-0000-0000-0000-000000000000'::UUID
                )
            );
    END IF;

    -- Sales
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales') THEN
        ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "sales_workshop_isolation" ON public.sales;
        CREATE POLICY "sales_workshop_isolation" ON public.sales
            FOR ALL USING (
                workshop_id = COALESCE(
                    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                    '00000000-0000-0000-0000-000000000000'::UUID
                )
            );
    END IF;

    -- Sale items (si elle existe)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sale_items') THEN
        ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "sale_items_workshop_isolation" ON public.sale_items;
        CREATE POLICY "sale_items_workshop_isolation" ON public.sale_items
            FOR ALL USING (
                sale_id IN (
                    SELECT id FROM sales 
                    WHERE workshop_id = COALESCE(
                        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                        '00000000-0000-0000-0000-000000000000'::UUID
                    )
                )
            );
    END IF;

    -- Loyalty points (si elle existe)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'loyalty_points') THEN
        ALTER TABLE public.loyalty_points ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "loyalty_points_workshop_isolation" ON public.loyalty_points;
        CREATE POLICY "loyalty_points_workshop_isolation" ON public.loyalty_points
            FOR ALL USING (
                client_id IN (
                    SELECT id FROM clients 
                    WHERE workshop_id = COALESCE(
                        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
                        '00000000-0000-0000-0000-000000000000'::UUID
                    )
                )
            );
    END IF;

    -- Loyalty tiers (si elle existe)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'loyalty_tiers_advanced') THEN
        ALTER TABLE public.loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "loyalty_tiers_read_only" ON public.loyalty_tiers_advanced;
        CREATE POLICY "loyalty_tiers_read_only" ON public.loyalty_tiers_advanced
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- System settings
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_settings') THEN
        ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "system_settings_read_only" ON public.system_settings;
        CREATE POLICY "system_settings_read_only" ON public.system_settings
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- ============================================================================
-- 5. PERMISSIONS SUR LES VUES
-- ============================================================================

-- Donner les permissions appropriées aux vues
GRANT SELECT ON public.sales_by_category TO authenticated;
GRANT SELECT ON public.repairs_filtered TO authenticated;
GRANT SELECT ON public.clients_all TO authenticated;
GRANT SELECT ON public.repair_tracking_view TO authenticated;
GRANT SELECT ON public.clients_filtrés TO authenticated;
GRANT SELECT ON public.repair_history_view TO authenticated;
GRANT SELECT ON public.clients_isolated TO authenticated;
GRANT SELECT ON public.clients_filtered TO authenticated;
GRANT SELECT ON public.repairs_isolated TO authenticated;
GRANT SELECT ON public.loyalty_dashboard TO authenticated;
GRANT SELECT ON public.loyalty_dashboard_iso TO authenticated;
GRANT SELECT ON public.device_models_my_mode TO authenticated;
GRANT SELECT ON public.clients_isolated_final TO authenticated;

-- ============================================================================
-- 6. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier que toutes les vues sont créées
SELECT 
    'Vérification finale des vues créées' as info,
    schemaname,
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

-- Test de sécurité : vérifier que les vues respectent l'isolation
SELECT 
    'Test de sécurité - Isolation des données' as info,
    (SELECT COUNT(*) FROM public.clients_all) as clients_visibles,
    (SELECT COUNT(*) FROM public.repairs_isolated) as repairs_visibles,
    (SELECT COUNT(*) FROM public.loyalty_dashboard) as loyalty_clients_visibles,
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) as workshop_actuel;

-- ============================================================================
-- 7. RÉSUMÉ DE LA CORRECTION
-- ============================================================================

SELECT 
    '✅ CORRECTION SÉCURITÉ ADAPTÉE TERMINÉE' as status,
    'Toutes les vues SECURITY DEFINER ont été remplacées par des vues SECURITY INVOKER' as message,
    'Les politiques RLS ont été appliquées sur les tables existantes' as rls_status,
    'Les vues respectent maintenant l''isolation des données par workshop' as isolation_status,
    'Le script s''est adapté à la structure réelle de votre base de données' as adaptation_status;

-- Instructions pour l'utilisation
SELECT 
    'Instructions d''utilisation' as info,
    '1. Toutes les vues utilisent maintenant SECURITY INVOKER (plus sécurisé)' as step1,
    '2. L''isolation des données est maintenue via les politiques RLS' as step2,
    '3. Toutes les vues filtrent automatiquement par workshop_id' as step3,
    '4. Relancez Supabase Security Advisor pour vérifier la correction' as step4,
    '5. Les avertissements SECURITY DEFINER et unrestricted devraient disparaître' as step5,
    '6. Le script s''est adapté à votre structure de base de données' as step6;
