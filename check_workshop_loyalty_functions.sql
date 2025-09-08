-- Vérification des fonctions d'isolation par atelier pour la fidélité
-- Ce script vérifie que les fonctions nécessaires existent et fonctionnent

-- 1. Vérifier l'existence des fonctions
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN (
    'get_workshop_loyalty_tiers',
    'get_workshop_loyalty_config',
    'create_default_loyalty_tiers_for_workshop'
)
AND routine_schema = 'public';

-- 2. Tester la fonction get_workshop_loyalty_tiers
SELECT 'Test get_workshop_loyalty_tiers' as test_name;
SELECT * FROM get_workshop_loyalty_tiers() LIMIT 5;

-- 3. Vérifier l'isolation par atelier
SELECT 'Vérification isolation par atelier' as test_name;
SELECT 
    workshop_id,
    COUNT(*) as nombre_niveaux,
    STRING_AGG(name, ', ') as niveaux
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

-- 4. Vérifier les permissions RLS
SELECT 'Vérification RLS loyalty_tiers_advanced' as test_name;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_actif,
    hasrules as a_des_regles
FROM pg_tables 
WHERE tablename = 'loyalty_tiers_advanced';

-- 5. Vérifier les politiques RLS
SELECT 'Politiques RLS loyalty_tiers_advanced' as test_name;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'loyalty_tiers_advanced';

-- 6. Test avec un utilisateur spécifique (remplacer par un vrai user_id)
SELECT 'Test isolation avec utilisateur' as test_name;
-- Note: Remplacer 'USER_ID_ICI' par un vrai user_id pour tester
-- SELECT * FROM loyalty_tiers_advanced WHERE workshop_id = 'USER_ID_ICI';
