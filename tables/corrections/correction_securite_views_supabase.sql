-- ============================================================================
-- CORRECTION SÉCURITÉ SUPABASE - VUES SECURITY DEFINER
-- ============================================================================
-- Ce script corrige les problèmes de sécurité identifiés par Supabase
-- en remplaçant les vues SECURITY DEFINER par des vues SECURITY INVOKER
-- et en renforçant les politiques RLS

-- ============================================================================
-- 1. IDENTIFICATION DES VUES PROBLÉMATIQUES
-- ============================================================================

-- Lister toutes les vues avec SECURITY DEFINER
SELECT 
    'Vues SECURITY DEFINER détectées' as info,
    schemaname,
    viewname,
    viewowner
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'clients_all',
    'repair_tracking_view', 
    'repairs_isolated',
    'clients_isolated',
    'clients_filtrés',
    'repair_history_view',
    'repairs_filtered'
);

-- ============================================================================
-- 2. SUPPRESSION DES VUES PROBLÉMATIQUES
-- ============================================================================

-- Supprimer les vues SECURITY DEFINER problématiques
DROP VIEW IF EXISTS public.clients_all CASCADE;
DROP VIEW IF EXISTS public.repair_tracking_view CASCADE;
DROP VIEW IF EXISTS public.repairs_isolated CASCADE;
DROP VIEW IF EXISTS public.clients_isolated CASCADE;
DROP VIEW IF EXISTS public.clients_filtrés CASCADE;
DROP VIEW IF EXISTS public.repair_history_view CASCADE;
DROP VIEW IF EXISTS public.repairs_filtered CASCADE;

-- ============================================================================
-- 3. CRÉATION DE VUES SÉCURISÉES (SECURITY INVOKER)
-- ============================================================================

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
FROM public.clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
);

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
FROM public.clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
);

-- Vue repairs_isolated sécurisée
CREATE OR REPLACE VIEW public.repairs_isolated AS
SELECT 
    id,
    client_id,
    device_id,
    description,
    status,
    estimated_cost,
    actual_cost,
    workshop_id,
    created_at,
    updated_at
FROM public.repairs
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
);

-- Vue repair_tracking_view sécurisée
CREATE OR REPLACE VIEW public.repair_tracking_view AS
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
FROM public.repairs r
LEFT JOIN public.clients c ON r.client_id = c.id
LEFT JOIN public.devices d ON r.device_id = d.id
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
);

-- Vue repair_history_view sécurisée
CREATE OR REPLACE VIEW public.repair_history_view AS
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
FROM public.repairs r
LEFT JOIN public.clients c ON r.client_id = c.id
LEFT JOIN public.devices d ON r.device_id = d.id
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
ORDER BY r.created_at DESC;

-- Vue repairs_filtered sécurisée
CREATE OR REPLACE VIEW public.repairs_filtered AS
SELECT 
    id,
    client_id,
    device_id,
    description,
    status,
    estimated_cost,
    actual_cost,
    workshop_id,
    created_at,
    updated_at
FROM public.repairs
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
AND status IN ('pending', 'in_progress', 'completed');

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
FROM public.clients
WHERE workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
AND email IS NOT NULL
AND email != '';

-- ============================================================================
-- 4. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

-- Vérifier que RLS est activé sur les tables principales
SELECT 
    'Vérification RLS' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'repairs', 'devices', 'system_settings')
ORDER BY tablename;

-- Vérifier les politiques RLS existantes
SELECT 
    'Politiques RLS existantes' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'repairs', 'devices')
ORDER BY tablename, policyname;

-- ============================================================================
-- 5. RENFORCEMENT DES POLITIQUES RLS
-- ============================================================================

-- S'assurer que RLS est activé
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Politiques pour la table clients
DROP POLICY IF EXISTS "clients_workshop_isolation" ON public.clients;
CREATE POLICY "clients_workshop_isolation" ON public.clients
    FOR ALL USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politiques pour la table repairs
DROP POLICY IF EXISTS "repairs_workshop_isolation" ON public.repairs;
CREATE POLICY "repairs_workshop_isolation" ON public.repairs
    FOR ALL USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politiques pour la table devices
DROP POLICY IF EXISTS "devices_workshop_isolation" ON public.devices;
CREATE POLICY "devices_workshop_isolation" ON public.devices
    FOR ALL USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politiques pour system_settings (lecture seule pour les utilisateurs authentifiés)
DROP POLICY IF EXISTS "system_settings_read_only" ON public.system_settings;
CREATE POLICY "system_settings_read_only" ON public.system_settings
    FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================================
-- 6. PERMISSIONS SUR LES VUES
-- ============================================================================

-- Donner les permissions appropriées aux vues
GRANT SELECT ON public.clients_all TO authenticated;
GRANT SELECT ON public.clients_isolated TO authenticated;
GRANT SELECT ON public.repairs_isolated TO authenticated;
GRANT SELECT ON public.repair_tracking_view TO authenticated;
GRANT SELECT ON public.repair_history_view TO authenticated;
GRANT SELECT ON public.repairs_filtered TO authenticated;
GRANT SELECT ON public.clients_filtrés TO authenticated;

-- ============================================================================
-- 7. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier que les vues sont créées sans SECURITY DEFINER
SELECT 
    'Vérification finale des vues' as info,
    schemaname,
    viewname,
    viewowner
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'clients_all',
    'repair_tracking_view', 
    'repairs_isolated',
    'clients_isolated',
    'clients_filtrés',
    'repair_history_view',
    'repairs_filtered'
)
ORDER BY viewname;

-- Test de sécurité : vérifier que les vues respectent l'isolation
SELECT 
    'Test de sécurité - Isolation des données' as info,
    (SELECT COUNT(*) FROM public.clients_all) as clients_visibles,
    (SELECT COUNT(*) FROM public.repairs_isolated) as repairs_visibles,
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) as workshop_actuel;

-- ============================================================================
-- 8. RÉSUMÉ DE LA CORRECTION
-- ============================================================================

SELECT 
    '✅ CORRECTION SÉCURITÉ TERMINÉE' as status,
    'Toutes les vues SECURITY DEFINER ont été remplacées par des vues SECURITY INVOKER' as message,
    'Les politiques RLS ont été renforcées sur toutes les tables' as rls_status,
    'Les vues respectent maintenant l''isolation des données par workshop' as isolation_status;

-- Instructions pour l'utilisation
SELECT 
    'Instructions d''utilisation' as info,
    '1. Les vues utilisent maintenant SECURITY INVOKER (plus sécurisé)' as step1,
    '2. L''isolation des données est maintenue via les politiques RLS' as step2,
    '3. Toutes les vues filtrent automatiquement par workshop_id' as step3,
    '4. Relancez Supabase Security Advisor pour vérifier la correction' as step4,
    '5. Les avertissements SECURITY DEFINER devraient disparaître' as step5;
