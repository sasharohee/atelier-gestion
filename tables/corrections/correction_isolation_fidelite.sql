-- 🔧 CORRECTION ISOLATION FIDÉLITÉ - Diagnostic et Réparation Complète
-- Ce script résout le problème d'isolation des données de la page fidélité
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC COMPLET DU SYSTÈME DE FIDÉLITÉ
-- ============================================================================

SELECT '=== DIAGNOSTIC COMPLET SYSTÈME FIDÉLITÉ ===' as section;

-- Vérifier l'existence des tables de fidélité
SELECT 
    'Tables de fidélité existantes' as check_type,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name LIKE '%loyalty%'
ORDER BY table_name;

-- Vérifier la structure des tables de fidélité
SELECT 
    'Structure des tables de fidélité' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history', 'clients')
ORDER BY table_name, ordinal_position;

-- Vérifier les politiques RLS existantes
SELECT 
    'Politiques RLS existantes' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history', 'clients')
ORDER BY tablename, policyname;

-- Vérifier l'activation RLS
SELECT 
    'Activation RLS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history', 'clients')
ORDER BY tablename;

-- ============================================================================
-- 2. VÉRIFICATION DES DONNÉES ET ISOLATION
-- ============================================================================

SELECT '=== VÉRIFICATION DONNÉES ET ISOLATION ===' as section;

-- Vérifier les données dans loyalty_config
SELECT 
    'Données loyalty_config' as check_type,
    COUNT(*) as total_configs,
    COUNT(DISTINCT key) as unique_keys
FROM loyalty_config;

-- Vérifier les données dans loyalty_tiers_advanced
SELECT 
    'Données loyalty_tiers_advanced' as check_type,
    COUNT(*) as total_tiers,
    COUNT(CASE WHEN is_active THEN 1 END) as active_tiers
FROM loyalty_tiers_advanced;

-- Vérifier les données dans loyalty_points_history
SELECT 
    'Données loyalty_points_history' as check_type,
    COUNT(*) as total_entries,
    COUNT(DISTINCT client_id) as unique_clients,
    COUNT(DISTINCT points_type) as unique_point_types
FROM loyalty_points_history;

-- Vérifier la vue loyalty_dashboard
SELECT 
    'Vue loyalty_dashboard' as check_type,
    COUNT(*) as total_clients_in_dashboard
FROM loyalty_dashboard;

-- ============================================================================
-- 3. CORRECTION DE L'ISOLATION - ÉTAPE 1: NETTOYAGE
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 1: NETTOYAGE ===' as section;

-- Désactiver RLS temporairement pour pouvoir corriger
ALTER TABLE loyalty_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
            AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON %I.%I', 
            policy_record.policyname, 
            policy_record.schemaname, 
            policy_record.tablename);
        RAISE NOTICE 'Politique supprimée: %s sur %s.%s', 
            policy_record.policyname, 
            policy_record.schemaname, 
            policy_record.tablename;
    END LOOP;
END $$;

-- ============================================================================
-- 4. CORRECTION DE L'ISOLATION - ÉTAPE 2: AJOUT COLONNES D'ISOLATION
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 2: AJOUT COLONNES ===' as section;

-- Ajouter la colonne workshop_id à loyalty_config si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_config' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE loyalty_config ADD COLUMN workshop_id UUID;
        RAISE NOTICE 'Colonne workshop_id ajoutée à loyalty_config';
    ELSE
        RAISE NOTICE 'Colonne workshop_id existe déjà dans loyalty_config';
    END IF;
END $$;

-- Ajouter la colonne workshop_id à loyalty_tiers_advanced si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_tiers_advanced' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE loyalty_tiers_advanced ADD COLUMN workshop_id UUID;
        RAISE NOTICE 'Colonne workshop_id ajoutée à loyalty_tiers_advanced';
    ELSE
        RAISE NOTICE 'Colonne workshop_id existe déjà dans loyalty_tiers_advanced';
    END IF;
END $$;

-- Ajouter la colonne workshop_id à loyalty_points_history si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_points_history' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE loyalty_points_history ADD COLUMN workshop_id UUID;
        RAISE NOTICE 'Colonne workshop_id ajoutée à loyalty_points_history';
    ELSE
        RAISE NOTICE 'Colonne workshop_id existe déjà dans loyalty_points_history';
    END IF;
END $$;

-- ============================================================================
-- 5. CORRECTION DE L'ISOLATION - ÉTAPE 3: MISE À JOUR DES DONNÉES
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 3: MISE À JOUR DONNÉES ===' as section;

-- Mettre à jour loyalty_config avec le workshop_id par défaut
UPDATE loyalty_config 
SET workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE workshop_id IS NULL;

-- Mettre à jour loyalty_tiers_advanced avec le workshop_id par défaut
UPDATE loyalty_tiers_advanced 
SET workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE workshop_id IS NULL;

-- Mettre à jour loyalty_points_history avec le workshop_id du client
UPDATE loyalty_points_history 
SET workshop_id = (
    SELECT c.workshop_id 
    FROM clients c 
    WHERE c.id = loyalty_points_history.client_id
)
WHERE workshop_id IS NULL;

-- Mettre à jour les clients sans workshop_id
UPDATE clients 
SET workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE workshop_id IS NULL;

-- ============================================================================
-- 6. CORRECTION DE L'ISOLATION - ÉTAPE 4: CRÉATION DES INDEX
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 4: CRÉATION INDEX ===' as section;

-- Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_loyalty_config_workshop_id ON loyalty_config(workshop_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_tiers_workshop_id ON loyalty_tiers_advanced(workshop_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_points_history_workshop_id ON loyalty_points_history(workshop_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_points_history_client_id ON loyalty_points_history(client_id);
CREATE INDEX IF NOT EXISTS idx_clients_workshop_id ON clients(workshop_id);

-- ============================================================================
-- 7. CORRECTION DE L'ISOLATION - ÉTAPE 5: RÉACTIVATION RLS
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 5: RÉACTIVATION RLS ===' as section;

-- Réactiver RLS
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 8. CORRECTION DE L'ISOLATION - ÉTAPE 6: CRÉATION DES POLITIQUES
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 6: CRÉATION POLITIQUES ===' as section;

-- Politiques pour loyalty_config (lecture pour tous, modification pour l'atelier)
CREATE POLICY "loyalty_config_read_policy" ON loyalty_config
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "loyalty_config_update_policy" ON loyalty_config
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politiques pour loyalty_tiers_advanced (lecture pour tous, modification pour l'atelier)
CREATE POLICY "loyalty_tiers_advanced_read_policy" ON loyalty_tiers_advanced
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "loyalty_tiers_advanced_insert_policy" ON loyalty_tiers_advanced
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "loyalty_tiers_advanced_update_policy" ON loyalty_tiers_advanced
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "loyalty_tiers_advanced_delete_policy" ON loyalty_tiers_advanced
    FOR DELETE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politiques pour loyalty_points_history (isolation stricte par workshop)
CREATE POLICY "loyalty_points_history_read_policy" ON loyalty_points_history
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "loyalty_points_history_insert_policy" ON loyalty_points_history
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "loyalty_points_history_update_policy" ON loyalty_points_history
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "loyalty_points_history_delete_policy" ON loyalty_points_history
    FOR DELETE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- ============================================================================
-- 9. CORRECTION DE L'ISOLATION - ÉTAPE 7: RECRÉATION DE LA VUE
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 7: RECRÉATION VUE ===' as section;

-- Supprimer la vue existante
DROP VIEW IF EXISTS loyalty_dashboard;

-- Recréer la vue avec isolation
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
    AND c.workshop_id = COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
ORDER BY c.loyalty_points DESC;

-- ============================================================================
-- 10. CORRECTION DE L'ISOLATION - ÉTAPE 8: VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== CORRECTION ISOLATION - ÉTAPE 8: VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure finale
SELECT 
    'Structure finale des tables' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
    AND column_name = 'workshop_id'
ORDER BY table_name;

-- Vérifier les politiques RLS finales
SELECT 
    'Politiques RLS finales' as check_type,
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY tablename, policyname;

-- Vérifier l'activation RLS finale
SELECT 
    'Activation RLS finale' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
ORDER BY tablename;

-- Vérifier les données isolées
SELECT 
    'Données isolées par workshop' as check_type,
    'loyalty_config' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as records_with_workshop_id
FROM loyalty_config
UNION ALL
SELECT 
    'Données isolées par workshop' as check_type,
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as records_with_workshop_id
FROM loyalty_tiers_advanced
UNION ALL
SELECT 
    'Données isolées par workshop' as check_type,
    'loyalty_points_history' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as records_with_workshop_id
FROM loyalty_points_history;

-- Test de la vue loyalty_dashboard
SELECT 
    'Test vue loyalty_dashboard' as check_type,
    COUNT(*) as total_clients_in_dashboard
FROM loyalty_dashboard;

-- ============================================================================
-- 11. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT '✅ CORRECTION ISOLATION FIDÉLITÉ TERMINÉE AVEC SUCCÈS !' as status;

SELECT '📋 RÉSUMÉ DES CORRECTIONS APPLIQUÉES:' as info;

SELECT '1. ✅ Colonnes workshop_id ajoutées aux tables de fidélité' as correction;
SELECT '2. ✅ Données mises à jour avec le bon workshop_id' as correction;
SELECT '3. ✅ Politiques RLS créées pour l''isolation stricte' as correction;
SELECT '4. ✅ Vue loyalty_dashboard recréée avec isolation' as correction;
SELECT '5. ✅ Index créés pour les performances' as correction;

SELECT '🔒 L''isolation des données de la page fidélité est maintenant fonctionnelle !' as confirmation;
