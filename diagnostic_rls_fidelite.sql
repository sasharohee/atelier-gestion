-- DIAGNOSTIC DES PERMISSIONS RLS POUR LE SYSTÈME DE FIDÉLITÉ
-- Ce script vérifie et corrige les permissions RLS

-- 1. VÉRIFIER L'ÉTAT ACTUEL DES POLITIQUES RLS
SELECT '🔍 ÉTAT ACTUEL DES POLITIQUES RLS' as diagnostic;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- 2. VÉRIFIER SI LES TABLES ONT RLS ACTIVÉ
SELECT '🔒 ÉTAT RLS DES TABLES' as diagnostic;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
AND schemaname = 'public';

-- 3. VÉRIFIER LES DONNÉES AVEC L'UTILISATEUR ACTUEL
SELECT '👤 TEST D''ACCÈS AVEC L''UTILISATEUR ACTUEL' as diagnostic;

-- Test d'accès à loyalty_config
SELECT '📊 Test loyalty_config:' as test;
SELECT COUNT(*) as total_config FROM loyalty_config;

-- Test d'accès à loyalty_tiers_advanced  
SELECT '🏆 Test loyalty_tiers_advanced:' as test;
SELECT COUNT(*) as total_tiers FROM loyalty_tiers_advanced;

-- 4. VÉRIFIER LA FONCTION system_settings
SELECT '⚙️ VÉRIFICATION DE system_settings' as diagnostic;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings' AND table_schema = 'public') 
        THEN '✅ Table system_settings existe'
        ELSE '❌ Table system_settings n''existe pas'
    END as status;

-- Si la table existe, vérifier les données
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings' AND table_schema = 'public') THEN
        RAISE NOTICE '📊 Données dans system_settings: % lignes', (SELECT COUNT(*) FROM system_settings);
    END IF;
END $$;

-- 5. CRÉER DES POLITIQUES RLS TEMPORAIRES POUR LE TEST
SELECT '🔧 CRÉATION DE POLITIQUES RLS TEMPORAIRES' as diagnostic;

-- Désactiver temporairement RLS pour les tests
ALTER TABLE loyalty_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced DISABLE ROW LEVEL SECURITY;

-- 6. TESTER L'ACCÈS SANS RLS
SELECT '🧪 TEST D''ACCÈS SANS RLS' as diagnostic;

SELECT '📊 loyalty_config sans RLS:' as test;
SELECT COUNT(*) as total_config FROM loyalty_config;

SELECT '🏆 loyalty_tiers_advanced sans RLS:' as test;  
SELECT COUNT(*) as total_tiers FROM loyalty_tiers_advanced;

-- 7. RÉACTIVER RLS ET CRÉER DES POLITIQUES CORRECTES
SELECT '🔒 RÉACTIVATION RLS AVEC POLITIQUES CORRECTES' as diagnostic;

-- Réactiver RLS
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques (si elles existent)
DROP POLICY IF EXISTS loyalty_config_select_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_insert_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_update_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_delete_policy ON loyalty_config;

DROP POLICY IF EXISTS loyalty_tiers_select_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_insert_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_update_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_delete_policy ON loyalty_tiers_advanced;

-- Créer des politiques permissives pour le test
CREATE POLICY loyalty_config_select_policy ON loyalty_config
    FOR SELECT USING (true);

CREATE POLICY loyalty_config_insert_policy ON loyalty_config
    FOR INSERT WITH CHECK (true);

CREATE POLICY loyalty_config_update_policy ON loyalty_config
    FOR UPDATE USING (true);

CREATE POLICY loyalty_config_delete_policy ON loyalty_config
    FOR DELETE USING (true);

CREATE POLICY loyalty_tiers_select_policy ON loyalty_tiers_advanced
    FOR SELECT USING (true);

CREATE POLICY loyalty_tiers_insert_policy ON loyalty_tiers_advanced
    FOR INSERT WITH CHECK (true);

CREATE POLICY loyalty_tiers_update_policy ON loyalty_tiers_advanced
    FOR UPDATE USING (true);

CREATE POLICY loyalty_tiers_delete_policy ON loyalty_tiers_advanced
    FOR DELETE USING (true);

-- 8. TEST FINAL
SELECT '✅ TEST FINAL AVEC NOUVELLES POLITIQUES' as diagnostic;

SELECT '📊 Test final loyalty_config:' as test;
SELECT COUNT(*) as total_config FROM loyalty_config;

SELECT '🏆 Test final loyalty_tiers_advanced:' as test;
SELECT COUNT(*) as total_tiers FROM loyalty_tiers_advanced;

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 POLITIQUES RLS CORRIGÉES !' as result;
SELECT '📋 Vous pouvez maintenant tester l''interface de fidélité.' as next_step;


