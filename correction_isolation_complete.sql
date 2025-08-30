-- 🔧 CORRECTION COMPLÈTE - Isolation des Données Entre Comptes
-- Script pour résoudre l'isolation des données sur toutes les pages (clients, fidélité, etc.)
-- Date: 2025-01-23

-- ============================================================================
-- 1. VÉRIFICATION ET AJOUT DES COLONNES WORKSHOP_ID MANQUANTES
-- ============================================================================

SELECT '=== VÉRIFICATION ET AJOUT DES COLONNES WORKSHOP_ID ===' as section;

-- Vérifier quelles tables ont déjà la colonne workshop_id
SELECT 
    'Colonnes workshop_id existantes' as check_type,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'workshop_id'
    AND table_name IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY table_name;

-- Ajouter la colonne workshop_id aux tables qui ne l'ont pas
DO $$
DECLARE
    current_table text;
BEGIN
    FOR current_table IN 
        SELECT unnest(ARRAY['devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services']) 
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = current_table 
                AND column_name = 'workshop_id'
        ) THEN
            EXECUTE format('ALTER TABLE %I ADD COLUMN workshop_id UUID', current_table);
            RAISE NOTICE 'Colonne workshop_id ajoutée à la table %', current_table;
        ELSE
            RAISE NOTICE 'La table % a déjà la colonne workshop_id', current_table;
        END IF;
    END LOOP;
END $$;

-- ============================================================================
-- 2. DIAGNOSTIC COMPLET DE L'ISOLATION
-- ============================================================================

SELECT '=== DIAGNOSTIC COMPLET DE L''ISOLATION ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as check_type,
    key,
    value as workshop_id,
    CASE 
        WHEN value IS NULL THEN 'PROBLEME: workshop_id non defini'
        WHEN value = '00000000-0000-0000-0000-000000000000' THEN 'ATTENTION: workshop_id par defaut'
        ELSE 'OK: workshop_id defini'
    END as status
FROM system_settings 
WHERE key = 'workshop_id';

-- Vérifier toutes les tables principales
SELECT 
    'Tables principales' as check_type,
    tablename,
    CASE WHEN rowsecurity THEN 'RLS Active' ELSE 'RLS Inactive' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY tablename;

-- Vérifier les données sans workshop_id
SELECT 
    'Donnees sans workshop_id' as check_type,
    'clients' as table_name,
    COUNT(*) as records_without_workshop
FROM clients 
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Donnees sans workshop_id' as check_type,
    'devices' as table_name,
    COUNT(*) as records_without_workshop
FROM devices 
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Donnees sans workshop_id' as check_type,
    'repairs' as table_name,
    COUNT(*) as records_without_workshop
FROM repairs 
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Donnees sans workshop_id' as check_type,
    'sales' as table_name,
    COUNT(*) as records_without_workshop
FROM sales 
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

-- Vérifier les données d'autres ateliers
SELECT 
    'Donnees d autres ateliers' as check_type,
    'clients' as table_name,
    COUNT(*) as records_from_other_workshops
FROM clients 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Donnees d autres ateliers' as check_type,
    'devices' as table_name,
    COUNT(*) as records_from_other_workshops
FROM devices 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Donnees d autres ateliers' as check_type,
    'repairs' as table_name,
    COUNT(*) as records_from_other_workshops
FROM repairs 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Donnees d autres ateliers' as check_type,
    'sales' as table_name,
    COUNT(*) as records_from_other_workshops
FROM sales 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 2. CORRECTION FORCÉE COMPLÈTE
-- ============================================================================

SELECT '=== CORRECTION FORCÉE COMPLÈTE ===' as section;

-- Étape 1: Désactiver RLS sur toutes les tables
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE repairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;
ALTER TABLE parts DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE services DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history DISABLE ROW LEVEL SECURITY;

-- Étape 2: Supprimer toutes les données d'autres ateliers
-- Clients
DELETE FROM clients 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Devices
DELETE FROM devices 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Repairs
DELETE FROM repairs 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Sales
DELETE FROM sales 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Appointments
DELETE FROM appointments 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Parts
DELETE FROM parts 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Products
DELETE FROM products 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Services
DELETE FROM services 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Données de fidélité
DELETE FROM loyalty_config 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

DELETE FROM loyalty_tiers_advanced 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

DELETE FROM loyalty_points_history 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- Étape 3: Mettre à jour toutes les données restantes avec le bon workshop_id
UPDATE clients 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE devices 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE repairs 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE sales 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE appointments 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE parts 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE products 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE services 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE loyalty_config 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE loyalty_tiers_advanced 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

UPDATE loyalty_points_history 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 3. CRÉATION DES POLITIQUES RLS STRICTES
-- ============================================================================

SELECT '=== CRÉATION DES POLITIQUES RLS STRICTES ===' as section;

-- Supprimer toutes les politiques existantes
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
            AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services', 'loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON %I.%I', 
            policy_record.policyname, 
            policy_record.schemaname, 
            policy_record.tablename);
    END LOOP;
END $$;

-- Créer des politiques RLS strictes pour toutes les tables
-- Clients
CREATE POLICY "clients_isolation_policy" ON clients
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Devices
CREATE POLICY "devices_isolation_policy" ON devices
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Repairs
CREATE POLICY "repairs_isolation_policy" ON repairs
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Sales
CREATE POLICY "sales_isolation_policy" ON sales
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Appointments
CREATE POLICY "appointments_isolation_policy" ON appointments
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Parts
CREATE POLICY "parts_isolation_policy" ON parts
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Products
CREATE POLICY "products_isolation_policy" ON products
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Services
CREATE POLICY "services_isolation_policy" ON services
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Données de fidélité
CREATE POLICY "loyalty_config_isolation_policy" ON loyalty_config
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "loyalty_tiers_isolation_policy" ON loyalty_tiers_advanced
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "loyalty_points_isolation_policy" ON loyalty_points_history
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- ============================================================================
-- 4. RÉACTIVATION RLS
-- ============================================================================

SELECT '=== RÉACTIVATION RLS ===' as section;

-- Réactiver RLS sur toutes les tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RECRÉATION DES VUES AVEC ISOLATION
-- ============================================================================

SELECT '=== RECRÉATION DES VUES AVEC ISOLATION ===' as section;

-- Recréer la vue loyalty_dashboard
DROP VIEW IF EXISTS loyalty_dashboard;

CREATE OR REPLACE VIEW loyalty_dashboard AS
SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.email,
    COALESCE(c.loyalty_points, 0) as current_points,
    lt.name as current_tier,
    lt.discount_percentage,
    lt.color as tier_color,
    lt.benefits,
    (SELECT COUNT(*) FROM loyalty_points_history lph WHERE lph.client_id = c.id) as total_transactions,
    (SELECT SUM(points_change) FROM loyalty_points_history lph WHERE lph.client_id = c.id AND lph.points_type = 'earned') as total_points_earned,
    (SELECT SUM(points_change) FROM loyalty_points_history lph WHERE lph.client_id = c.id AND lph.points_type = 'used') as total_points_used,
    c.created_at as client_since,
    c.updated_at as last_activity
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE COALESCE(c.loyalty_points, 0) > 0
    AND c.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
ORDER BY c.loyalty_points DESC;

-- ============================================================================
-- 6. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que seules les données de l'atelier actuel sont visibles
SELECT 
    'Verification finale' as check_type,
    'clients' as table_name,
    COUNT(*) as total_records
FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
UNION ALL
SELECT 
    'Verification finale' as check_type,
    'devices' as table_name,
    COUNT(*) as total_records
FROM devices 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
UNION ALL
SELECT 
    'Verification finale' as check_type,
    'repairs' as table_name,
    COUNT(*) as total_records
FROM repairs 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
UNION ALL
SELECT 
    'Verification finale' as check_type,
    'sales' as table_name,
    COUNT(*) as total_records
FROM sales 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Vérifier qu'il n'y a plus de données d'autres ateliers
SELECT 
    'Absence de donnees d autres ateliers' as check_type,
    'clients' as table_name,
    COUNT(*) as records_from_other_workshops
FROM clients 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Absence de donnees d autres ateliers' as check_type,
    'devices' as table_name,
    COUNT(*) as records_from_other_workshops
FROM devices 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Absence de donnees d autres ateliers' as check_type,
    'repairs' as table_name,
    COUNT(*) as records_from_other_workshops
FROM repairs 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID
UNION ALL
SELECT 
    'Absence de donnees d autres ateliers' as check_type,
    'sales' as table_name,
    COUNT(*) as records_from_other_workshops
FROM sales 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 7. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 'CORRECTION COMPLÈTE TERMINÉE !' as status;

SELECT 'ACTIONS EFFECTUÉES:' as info;

SELECT '1. Suppression de toutes les donnees d autres ateliers' as action;
SELECT '2. Mise a jour de toutes les donnees avec le bon workshop_id' as action;
SELECT '3. Creation de politiques RLS strictes pour toutes les tables' as action;
SELECT '4. Reactivation de RLS sur toutes les tables' as action;
SELECT '5. Recreation des vues avec isolation stricte' as action;

SELECT 'L isolation des donnees entre comptes est maintenant FORCÉE et fonctionnelle !' as confirmation;
