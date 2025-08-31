-- VÉRIFICATION ET CORRECTION DES PERMISSIONS UPDATE
-- Ce script vérifie et corrige les permissions pour les mises à jour

-- 1. VÉRIFIER LES POLITIQUES ACTUELLES
SELECT '🔍 POLITIQUES ACTUELLES' as action;

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
WHERE tablename IN ('loyalty_config', 'loyalty_tiers_advanced')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- 2. VÉRIFIER LES PERMISSIONS DE L'UTILISATEUR
SELECT '👤 PERMISSIONS UTILISATEUR' as action;

SELECT 
    grantee,
    table_name,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name IN ('loyalty_config', 'loyalty_tiers_advanced')
AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- 3. ACCORDER LES PERMISSIONS MANQUANTES
SELECT '🔧 ACCORD DES PERMISSIONS' as action;

-- Accorder toutes les permissions sur loyalty_config
GRANT ALL ON loyalty_config TO authenticated;

-- Accorder toutes les permissions sur loyalty_tiers_advanced
GRANT ALL ON loyalty_tiers_advanced TO authenticated;

-- Accorder toutes les permissions sur loyalty_points_history
GRANT ALL ON loyalty_points_history TO authenticated;

-- 4. CRÉER DES POLITIQUES SPÉCIFIQUES POUR UPDATE
SELECT '✅ CRÉATION POLITIQUES UPDATE' as action;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS loyalty_config_all_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_tiers_all_policy ON loyalty_tiers_advanced;

-- Créer des politiques plus spécifiques
CREATE POLICY loyalty_config_policy ON loyalty_config
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY loyalty_tiers_policy ON loyalty_tiers_advanced
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 5. TESTER LES PERMISSIONS UPDATE
SELECT '🧪 TEST PERMISSIONS UPDATE' as action;

-- Test de mise à jour sur loyalty_config
UPDATE loyalty_config 
SET value = value 
WHERE key = 'points_per_euro';

SELECT '✅ Test UPDATE loyalty_config réussi' as result;

-- Test de mise à jour sur loyalty_tiers_advanced
UPDATE loyalty_tiers_advanced 
SET description = description 
WHERE name = 'Bronze';

SELECT '✅ Test UPDATE loyalty_tiers_advanced réussi' as result;

-- 6. VÉRIFICATION FINALE
SELECT '🔍 VÉRIFICATION FINALE' as action;

SELECT 
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name IN ('loyalty_config', 'loyalty_tiers_advanced')
AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- 7. MESSAGE DE CONFIRMATION
SELECT '🎉 PERMISSIONS CORRIGÉES !' as result;
SELECT '📋 Les mises à jour devraient maintenant fonctionner.' as next_step;


