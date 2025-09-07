-- =====================================================
-- DIAGNOSTIC CONTRAINTES CLÉS ÉTRANGÈRES
-- =====================================================
-- Script pour diagnostiquer les problèmes de contraintes
-- de clés étrangères liées à la table clients
-- Date: 2025-01-23
-- =====================================================

-- 1. Analyser toutes les contraintes de clés étrangères
SELECT '=== CONTRAINTES CLÉS ÉTRANGÈRES ===' as etape;

SELECT 
    tc.table_name as table_cible,
    kcu.column_name as colonne_cible,
    ccu.table_name AS table_source,
    ccu.column_name AS colonne_source,
    tc.constraint_name as nom_contrainte,
    CASE 
        WHEN tc.table_name = 'clients' THEN '🎯 Table clients'
        WHEN ccu.table_name = 'clients' THEN '🔗 Référence vers clients'
        ELSE '📋 Autre table'
    END as type_relation
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND (ccu.table_name = 'clients' OR tc.table_name = 'clients')
ORDER BY tc.table_name, kcu.column_name;

-- 2. Analyser les contraintes NOT NULL
SELECT '=== CONTRAINTES NOT NULL ===' as etape;

SELECT 
    table_name as table_cible,
    column_name as colonne,
    is_nullable as nullable,
    column_default as valeur_par_defaut,
    CASE 
        WHEN table_name = 'clients' THEN '🎯 Table clients'
        WHEN column_name LIKE '%client%' THEN '🔗 Colonne liée aux clients'
        ELSE '📋 Autre colonne'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public'
    AND (table_name = 'clients' OR column_name LIKE '%client%')
    AND is_nullable = 'NO'
ORDER BY table_name, column_name;

-- 3. Vérifier les données orphelines
SELECT '=== VÉRIFICATION DONNÉES ORPHELINES ===' as etape;

-- Vérifier les clients sans user_id valide
SELECT 
    'Clients sans user_id valide' as type_probleme,
    COUNT(*) as nombre
FROM clients 
WHERE user_id IS NULL 
   OR user_id = '00000000-0000-0000-0000-000000000000'::UUID
   OR user_id NOT IN (SELECT id FROM auth.users);

-- Vérifier les données liées aux clients orphelins
DO $$
DECLARE
    v_orphan_clients_count INTEGER;
    v_related_data_count INTEGER;
    v_table_name TEXT;
    v_column_name TEXT;
    v_count INTEGER;
BEGIN
    -- Compter les clients orphelins
    SELECT COUNT(*) INTO v_orphan_clients_count
    FROM clients 
    WHERE user_id IS NULL 
       OR user_id = '00000000-0000-0000-0000-000000000000'::UUID
       OR user_id NOT IN (SELECT id FROM auth.users);
    
    RAISE NOTICE '📊 Clients orphelins: %', v_orphan_clients_count;
    
    IF v_orphan_clients_count > 0 THEN
        RAISE NOTICE '🔍 Vérification des données liées...';
        
        -- Vérifier chaque table qui référence clients
        FOR v_table_name, v_column_name IN 
            SELECT tc.table_name, kcu.column_name
            FROM information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY' 
                AND ccu.table_name = 'clients'
                AND ccu.column_name = 'id'
        LOOP
            -- Exécuter une requête dynamique pour compter les données liées
            EXECUTE format('SELECT COUNT(*) FROM %I WHERE %I IN (SELECT id FROM clients WHERE user_id IS NULL OR user_id = ''00000000-0000-0000-0000-000000000000''::UUID OR user_id NOT IN (SELECT id FROM auth.users))', 
                          v_table_name, v_column_name) INTO v_count;
            
            IF v_count > 0 THEN
                RAISE NOTICE '  - %: % enregistrements liés', v_table_name, v_count;
            END IF;
        END LOOP;
    ELSE
        RAISE NOTICE '✅ Aucun client orphelin trouvé';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
END $$;

-- 4. Analyser les tables avec des colonnes client_id
SELECT '=== TABLES AVEC COLONNES CLIENT_ID ===' as etape;

SELECT 
    table_name as table_cible,
    column_name as colonne,
    data_type as type,
    is_nullable as nullable,
    column_default as valeur_par_defaut
FROM information_schema.columns 
WHERE table_schema = 'public'
    AND column_name LIKE '%client%'
    AND table_name != 'clients'
ORDER BY table_name, column_name;

-- 5. Vérifier les contraintes de suppression en cascade
SELECT '=== CONTRAINTES SUPPRESSION EN CASCADE ===' as etape;

SELECT 
    tc.table_name as table_cible,
    kcu.column_name as colonne_cible,
    ccu.table_name AS table_source,
    ccu.column_name AS colonne_source,
    tc.constraint_name as nom_contrainte,
    CASE 
        WHEN tc.table_name = 'clients' THEN '🎯 Table clients'
        WHEN ccu.table_name = 'clients' THEN '🔗 Référence vers clients'
        ELSE '📋 Autre table'
    END as type_relation
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND (ccu.table_name = 'clients' OR tc.table_name = 'clients')
ORDER BY tc.table_name, kcu.column_name;

-- 6. Recommandations pour la gestion des contraintes
SELECT '=== RECOMMANDATIONS GESTION CONTRAINTES ===' as etape;

DO $$
DECLARE
    v_orphan_clients_count INTEGER;
    v_constraints_count INTEGER;
    v_not_null_constraints_count INTEGER;
BEGIN
    -- Compter les clients orphelins
    SELECT COUNT(*) INTO v_orphan_clients_count
    FROM clients 
    WHERE user_id IS NULL 
       OR user_id = '00000000-0000-0000-0000-000000000000'::UUID
       OR user_id NOT IN (SELECT id FROM auth.users);
    
    -- Compter les contraintes de clés étrangères
    SELECT COUNT(*) INTO v_constraints_count
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND ccu.table_name = 'clients';
    
    -- Compter les contraintes NOT NULL sur les colonnes client
    SELECT COUNT(*) INTO v_not_null_constraints_count
    FROM information_schema.columns 
    WHERE table_schema = 'public'
        AND column_name LIKE '%client%'
        AND is_nullable = 'NO';
    
    RAISE NOTICE '📊 État des contraintes:';
    RAISE NOTICE '  - Clients orphelins: %', v_orphan_clients_count;
    RAISE NOTICE '  - Contraintes FK vers clients: %', v_constraints_count;
    RAISE NOTICE '  - Contraintes NOT NULL sur colonnes client: %', v_not_null_constraints_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Recommandations:';
    
    IF v_orphan_clients_count > 0 THEN
        RAISE NOTICE '  🚨 URGENT: Nettoyer les clients orphelins';
        RAISE NOTICE '     Utiliser: correction_nouveaux_comptes_v2.sql';
        RAISE NOTICE '     (Gère les contraintes de clés étrangères)';
    END IF;
    
    IF v_constraints_count > 0 THEN
        RAISE NOTICE '  ⚠️ Attention: % contraintes FK vers clients', v_constraints_count;
        RAISE NOTICE '     Vérifier que les suppressions en cascade fonctionnent';
    END IF;
    
    IF v_not_null_constraints_count > 0 THEN
        RAISE NOTICE '  ⚠️ Attention: % contraintes NOT NULL sur colonnes client', v_not_null_constraints_count;
        RAISE NOTICE '     Vérifier que les valeurs par défaut sont définies';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Solution recommandée:';
    RAISE NOTICE '  1. Exécuter correction_nouveaux_comptes_v2.sql';
    RAISE NOTICE '  2. Vérifier que toutes les contraintes sont respectées';
    RAISE NOTICE '  3. Tester la suppression de clients';
    RAISE NOTICE '  4. Redéployer l''application';
    
END $$;
