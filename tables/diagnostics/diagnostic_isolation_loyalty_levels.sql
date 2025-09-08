-- =====================================================
-- DIAGNOSTIC ISOLATION NIVEAUX DE FIDÉLITÉ
-- =====================================================
-- Script pour diagnostiquer pourquoi l'isolation ne fonctionne pas
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel des tables de fidélité
SELECT '=== ÉTAT ACTUEL TABLES FIDÉLITÉ ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = tablename 
            AND column_name = 'workshop_id'
            AND table_schema = 'public'
        ) THEN '✅ workshop_id présent'
        ELSE '❌ workshop_id manquant'
    END as workshop_id_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename;

-- 2. Vérifier les colonnes des tables
SELECT '=== STRUCTURE DES TABLES ===' as etape;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY table_name, ordinal_position;

-- 3. Vérifier les politiques RLS actuelles
SELECT '=== POLITIQUES RLS ACTUELLES ===' as etape;

SELECT 
    tablename,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename, policyname;

-- 4. Vérifier les triggers
SELECT '=== TRIGGERS ACTUELS ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY event_object_table, trigger_name;

-- 5. Vérifier les fonctions créées
SELECT '=== FONCTIONS CRÉÉES ===' as etape;

SELECT 
    routine_name,
    routine_type,
    data_type as return_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%loyalty%'
ORDER BY routine_name;

-- 6. Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as etape;

-- Compter les niveaux par workshop_id
SELECT 
    'loyalty_tiers_advanced' as table_name,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as tier_names
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY workshop_id;

-- Compter les configurations par workshop_id
SELECT 
    'loyalty_config' as table_name,
    workshop_id,
    COUNT(*) as count,
    STRING_AGG(key, ', ') as config_keys
FROM loyalty_config 
GROUP BY workshop_id
ORDER BY workshop_id;

-- 7. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as etape;

SELECT 
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ Aucun utilisateur connecté'
        ELSE '✅ Utilisateur connecté'
    END as auth_status;

-- 8. Test d'isolation simple
SELECT '=== TEST ISOLATION SIMPLE ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_tiers_count INTEGER;
    v_config_count INTEGER;
    v_other_tiers_count INTEGER;
    v_other_config_count INTEGER;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test avec utilisateur: %', v_current_user_id;
    
    -- Compter les niveaux de l'utilisateur actuel
    SELECT COUNT(*) INTO v_tiers_count 
    FROM loyalty_tiers_advanced 
    WHERE workshop_id = v_current_user_id;
    
    -- Compter les configurations de l'utilisateur actuel
    SELECT COUNT(*) INTO v_config_count 
    FROM loyalty_config 
    WHERE workshop_id = v_current_user_id;
    
    -- Compter les niveaux d'autres utilisateurs
    SELECT COUNT(*) INTO v_other_tiers_count 
    FROM loyalty_tiers_advanced 
    WHERE workshop_id != v_current_user_id;
    
    -- Compter les configurations d'autres utilisateurs
    SELECT COUNT(*) INTO v_other_config_count 
    FROM loyalty_config 
    WHERE workshop_id != v_current_user_id;
    
    RAISE NOTICE '📊 Résultats du test:';
    RAISE NOTICE '  - Niveaux de l''utilisateur actuel: %', v_tiers_count;
    RAISE NOTICE '  - Configurations de l''utilisateur actuel: %', v_config_count;
    RAISE NOTICE '  - Niveaux d''autres utilisateurs: %', v_other_tiers_count;
    RAISE NOTICE '  - Configurations d''autres utilisateurs: %', v_other_config_count;
    
    -- Vérifier l'isolation
    IF v_other_tiers_count = 0 AND v_other_config_count = 0 THEN
        RAISE NOTICE '✅ ISOLATION PARFAITE: Aucune donnée d''autre utilisateur visible';
    ELSIF v_other_tiers_count > 0 OR v_other_config_count > 0 THEN
        RAISE NOTICE '❌ PROBLÈME D''ISOLATION: Données d''autres utilisateurs visibles';
    ELSE
        RAISE NOTICE '⚠️ ÉTAT INCERTAIN: Vérifiez manuellement';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 9. Vérifier les permissions
SELECT '=== PERMISSIONS ===' as etape;

SELECT 
    table_name,
    privilege_type,
    grantee
FROM information_schema.table_privileges 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY table_name, privilege_type;

-- 10. Test des fonctions utilitaires
SELECT '=== TEST FONCTIONS UTILITAIRES ===' as etape;

-- Test get_workshop_loyalty_tiers
DO $$
DECLARE
    v_result RECORD;
    v_count INTEGER := 0;
BEGIN
    BEGIN
        FOR v_result IN SELECT * FROM get_workshop_loyalty_tiers() LOOP
            v_count := v_count + 1;
        END LOOP;
        
        RAISE NOTICE '✅ Fonction get_workshop_loyalty_tiers() fonctionne - % niveaux retournés', v_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur fonction get_workshop_loyalty_tiers(): %', SQLERRM;
    END;
END $$;

-- Test get_workshop_loyalty_config
DO $$
DECLARE
    v_result RECORD;
    v_count INTEGER := 0;
BEGIN
    BEGIN
        FOR v_result IN SELECT * FROM get_workshop_loyalty_config() LOOP
            v_count := v_count + 1;
        END LOOP;
        
        RAISE NOTICE '✅ Fonction get_workshop_loyalty_config() fonctionne - % configurations retournées', v_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur fonction get_workshop_loyalty_config(): %', SQLERRM;
    END;
END $$;

-- 11. Vérifier les contraintes
SELECT '=== CONTRAINTES ===' as etape;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tc.table_name, tc.constraint_type;

-- 12. Résumé du diagnostic
SELECT '=== RÉSUMÉ DU DIAGNOSTIC ===' as etape;

SELECT 
    'Vérifiez les résultats ci-dessus pour identifier le problème d''isolation' as instruction,
    'Les problèmes courants sont:' as problemes_communs,
    '1. RLS désactivé' as probleme_1,
    '2. Politiques RLS manquantes ou incorrectes' as probleme_2,
    '3. Colonne workshop_id manquante' as probleme_3,
    '4. Triggers manquants' as probleme_4,
    '5. Fonctions utilitaires non créées' as probleme_5,
    '6. Données existantes sans workshop_id' as probleme_6;
