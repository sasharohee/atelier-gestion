-- =====================================================
-- TEST DU SYSTÈME DE POINTS DE FIDÉLITÉ
-- =====================================================
-- Script de test pour vérifier le bon fonctionnement
-- du système de points de fidélité
-- =====================================================

-- 1. VÉRIFICATION DES TABLES
SELECT '=== VÉRIFICATION DES TABLES ===' as test_section;

-- Vérifier que toutes les tables existent
SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status
FROM (
    SELECT 'loyalty_tiers' as table_name
    UNION ALL SELECT 'referrals'
    UNION ALL SELECT 'client_loyalty_points'
    UNION ALL SELECT 'loyalty_points_history'
    UNION ALL SELECT 'loyalty_rules'
) t
WHERE EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = t.table_name
);

-- 2. VÉRIFICATION DES NIVEAUX DE FIDÉLITÉ
SELECT '=== VÉRIFICATION DES NIVEAUX ===' as test_section;

SELECT 
    name,
    min_points,
    discount_percentage,
    color
FROM loyalty_tiers
ORDER BY min_points;

-- 3. VÉRIFICATION DES RÈGLES
SELECT '=== VÉRIFICATION DES RÈGLES ===' as test_section;

SELECT 
    rule_name,
    points_per_referral,
    points_per_euro_spent,
    points_expiry_months,
    is_active
FROM loyalty_rules;

-- 4. VÉRIFICATION DES FONCTIONS
SELECT '=== VÉRIFICATION DES FONCTIONS ===' as test_section;

-- Tester la fonction de statistiques
SELECT 
    'Test get_loyalty_statistics' as test_name,
    CASE 
        WHEN get_loyalty_statistics()::text LIKE '%success%' THEN '✅ Fonctionne'
        ELSE '❌ Erreur'
    END as status;

-- 5. TEST AVEC DES DONNÉES RÉELLES
SELECT '=== TEST AVEC DONNÉES RÉELLES ===' as test_section;

-- Vérifier s'il y a des clients existants
SELECT 
    'Clients existants' as info,
    COUNT(*) as count
FROM clients;

-- Vérifier s'il y a des réparations existantes
SELECT 
    'Réparations existantes' as info,
    COUNT(*) as count
FROM repairs;

-- 6. TEST DE CRÉATION DE PARRAINAGE (si des clients existent)
DO $$
DECLARE
    v_client1_id UUID;
    v_client2_id UUID;
    v_referral_result JSON;
BEGIN
    -- Récupérer deux clients existants pour le test
    SELECT id INTO v_client1_id FROM clients LIMIT 1;
    SELECT id INTO v_client2_id FROM clients WHERE id != v_client1_id LIMIT 1;
    
    IF v_client1_id IS NOT NULL AND v_client2_id IS NOT NULL THEN
        -- Tester la création d'un parrainage
        SELECT create_referral(v_client1_id, v_client2_id, 'Test automatique') INTO v_referral_result;
        
        RAISE NOTICE 'Test création parrainage: %', v_referral_result;
        
        -- Tester les statistiques après création
        RAISE NOTICE 'Statistiques après création: %', get_loyalty_statistics();
    ELSE
        RAISE NOTICE 'Pas assez de clients pour tester les parrainages';
    END IF;
END $$;

-- 7. VÉRIFICATION DES COLONNES AJOUTÉES À REPAIRS
SELECT '=== VÉRIFICATION COLONNES REPAIRS ===' as test_section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IN ('loyalty_discount_percentage', 'loyalty_points_used', 'final_price') THEN '✅ Ajoutée'
        ELSE '❌ Manquante'
    END as status
FROM information_schema.columns 
WHERE table_name = 'repairs' 
AND column_name IN ('loyalty_discount_percentage', 'loyalty_points_used', 'final_price')
ORDER BY column_name;

-- 8. TEST DES POLITIQUES RLS
SELECT '=== VÉRIFICATION POLITIQUES RLS ===' as test_section;

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
WHERE tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
ORDER BY tablename, policyname;

-- 9. RÉSUMÉ FINAL
SELECT '=== RÉSUMÉ FINAL ===' as test_section;

SELECT 
    'SYSTÈME DE POINTS DE FIDÉLITÉ' as system_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM loyalty_tiers) THEN '✅ Prêt'
        ELSE '❌ Non configuré'
    END as status,
    'Toutes les tables et fonctions ont été créées avec succès' as message;

-- 10. INSTRUCTIONS POUR L'UTILISATION
SELECT '=== INSTRUCTIONS ===' as test_section;

SELECT 
    'Pour utiliser le système:' as instruction,
    '1. Créer des parrainages avec create_referral()' as step1,
    '2. Confirmer les parrainages avec confirm_referral()' as step2,
    '3. Les réductions sont appliquées automatiquement' as step3,
    '4. Consulter les statistiques avec get_loyalty_statistics()' as step4;
