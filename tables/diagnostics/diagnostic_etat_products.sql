-- 🔍 DIAGNOSTIC ÉTAT ACTUEL TABLE PRODUCTS
-- Script pour diagnostiquer l'état actuel de la table products

-- ========================================
-- DIAGNOSTIC 1: STRUCTURE DE LA TABLE
-- ========================================

SELECT 
    '=== STRUCTURE TABLE PRODUCTS ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IN ('user_id', 'created_by', 'workshop_id') THEN '🔒 COLONNE D''ISOLATION'
        WHEN column_name IN ('id', 'created_at', 'updated_at') THEN '📅 COLONNE SYSTÈME'
        ELSE '📋 COLONNE MÉTIER'
    END as type_colonne
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- DIAGNOSTIC 2: ÉTAT RLS
-- ========================================

SELECT 
    '=== ÉTAT RLS PRODUCTS ===' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '🔒 RLS ACTIVÉ'
        ELSE '🔓 RLS DÉSACTIVÉ'
    END as rls_status,
    schemaname
FROM pg_tables 
WHERE tablename = 'products';

-- ========================================
-- DIAGNOSTIC 3: POLITIQUES RLS EXISTANTES
-- ========================================

SELECT 
    '=== POLITIQUES RLS EXISTANTES ===' as section,
    policyname,
    CASE 
        WHEN permissive = 'PERM' THEN '✅ PERMISSIVE'
        WHEN permissive = 'REST' THEN '❌ RESTRICTIVE'
        ELSE '❓ INCONNU'
    END as type_politique,
    roles,
    cmd as operation,
    CASE 
        WHEN qual IS NOT NULL THEN '✅ CONDITION SELECT'
        ELSE '❌ AUCUNE CONDITION'
    END as condition_select,
    CASE 
        WHEN with_check IS NOT NULL THEN '✅ CONDITION INSERT/UPDATE'
        ELSE '❌ AUCUNE CONDITION'
    END as condition_insert_update
FROM pg_policies 
WHERE tablename = 'products'
ORDER BY cmd;

-- ========================================
-- DIAGNOSTIC 4: TRIGGERS EXISTANTS
-- ========================================

SELECT 
    '=== TRIGGERS EXISTANTS ===' as section,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    CASE 
        WHEN trigger_name = 'set_products_isolation_trigger' THEN '✅ TRIGGER D''ISOLATION'
        ELSE 'ℹ️ AUTRE TRIGGER'
    END as type_trigger
FROM information_schema.triggers 
WHERE event_object_table = 'products'
ORDER BY trigger_name;

-- ========================================
-- DIAGNOSTIC 5: DONNÉES EXISTANTES
-- ========================================

DO $$
DECLARE
    total_products INTEGER;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
    avec_user_id INTEGER;
    avec_created_by INTEGER;
    avec_workshop_id INTEGER;
BEGIN
    -- Compter les produits
    SELECT COUNT(*) INTO total_products FROM products;
    
    -- Vérifier quelles colonnes existent
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    -- Compter selon les colonnes existantes
    IF user_id_exists THEN
        SELECT COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) INTO avec_user_id FROM products;
    ELSE
        avec_user_id := 0;
    END IF;
    
    IF created_by_exists THEN
        SELECT COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) INTO avec_created_by FROM products;
    ELSE
        avec_created_by := 0;
    END IF;
    
    IF workshop_id_exists THEN
        SELECT COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) INTO avec_workshop_id FROM products;
    ELSE
        avec_workshop_id := 0;
    END IF;
    
    RAISE NOTICE '=== DONNÉES PRODUCTS EXISTANTES ===';
    RAISE NOTICE 'Total produits dans la table: %', total_products;
    RAISE NOTICE '';
    RAISE NOTICE 'Colonnes d''isolation:';
    RAISE NOTICE '  - user_id: %s (%s produits avec valeur)', 
        CASE WHEN user_id_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END, avec_user_id;
    RAISE NOTICE '  - created_by: %s (%s produits avec valeur)', 
        CASE WHEN created_by_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END, avec_created_by;
    RAISE NOTICE '  - workshop_id: %s (%s produits avec valeur)', 
        CASE WHEN workshop_id_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END, avec_workshop_id;
END $$;

-- ========================================
-- DIAGNOSTIC 6: PROBLÈMES IDENTIFIÉS
-- ========================================

DO $$
DECLARE
    rls_actif BOOLEAN;
    politique_insert_existe BOOLEAN;
    trigger_isolation_existe BOOLEAN;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
    problemes TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Vérifications
    SELECT rowsecurity INTO rls_actif FROM pg_tables WHERE tablename = 'products';
    
    SELECT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'products' 
        AND cmd = 'INSERT'
    ) INTO politique_insert_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.triggers 
        WHERE trigger_name = 'set_products_isolation_trigger'
        AND event_object_table = 'products'
    ) INTO trigger_isolation_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    -- Identifier les problèmes
    IF NOT rls_actif THEN
        problemes := array_append(problemes, 'RLS désactivé sur products');
    END IF;
    
    IF NOT politique_insert_existe THEN
        problemes := array_append(problemes, 'Politique INSERT manquante');
    END IF;
    
    IF NOT trigger_isolation_existe THEN
        problemes := array_append(problemes, 'Trigger d''isolation manquant');
    END IF;
    
    IF NOT user_id_exists THEN
        problemes := array_append(problemes, 'Colonne user_id manquante');
    END IF;
    
    IF NOT created_by_exists THEN
        problemes := array_append(problemes, 'Colonne created_by manquante');
    END IF;
    
    IF NOT workshop_id_exists THEN
        problemes := array_append(problemes, 'Colonne workshop_id manquante');
    END IF;
    
    -- Afficher le diagnostic
    RAISE NOTICE '=== DIAGNOSTIC PROBLÈMES ===';
    
    IF array_length(problemes, 1) IS NULL THEN
        RAISE NOTICE '✅ Aucun problème identifié - la table products est correctement configurée';
    ELSE
        RAISE NOTICE '❌ Problèmes identifiés (%):', array_length(problemes, 1);
        FOR i IN 1..array_length(problemes, 1) LOOP
            RAISE NOTICE '  %: %', i, problemes[i];
        END LOOP;
        
        RAISE NOTICE '';
        RAISE NOTICE '💡 SOLUTION: Exécutez le script correction_type_discount_percentage.sql';
    END IF;
END $$;

-- ========================================
-- DIAGNOSTIC 7: TEST D'INSERTION SIMPLE
-- ========================================

DO $$
DECLARE
    test_id UUID;
    insertion_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== TEST D''INSERTION SIMPLE ===';
    
    BEGIN
        -- Test d'insertion simple
        INSERT INTO products (
            id, name, description, price, stock_quantity, category, is_active, 
            created_at, updated_at
        ) VALUES (
            gen_random_uuid(), 'Test Diagnostic', 'Test Description', 25.00, 10, 'Test Category', true,
            NOW(), NOW()
        ) RETURNING id INTO test_id;
        
        insertion_success := TRUE;
        RAISE NOTICE '✅ Insertion simple RÉUSSIE - ID: %', test_id;
        
        -- Nettoyer
        DELETE FROM products WHERE id = test_id;
        RAISE NOTICE '✅ Enregistrement de test supprimé';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ ERREUR lors de l''insertion simple: %', SQLERRM;
            RAISE NOTICE '   Code erreur: %', SQLSTATE;
            insertion_success := FALSE;
    END;
    
    IF insertion_success THEN
        RAISE NOTICE '✅ L''insertion de base fonctionne - le problème vient des politiques RLS';
    ELSE
        RAISE NOTICE '❌ L''insertion de base échoue - problème plus profond';
    END IF;
END $$;

-- ========================================
-- RÉSUMÉ FINAL
-- ========================================

SELECT 
    '=== RÉSUMÉ DIAGNOSTIC ===' as section,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_tables 
            WHERE tablename = 'products' 
            AND rowsecurity = true
        ) THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as rls_status,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_policies 
            WHERE tablename = 'products' 
            AND cmd = 'INSERT'
        ) THEN '✅ Politique INSERT'
        ELSE '❌ Politique INSERT manquante'
    END as politique_insert,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'products' 
            AND column_name IN ('user_id', 'created_by', 'workshop_id')
        ) THEN '✅ Colonnes d''isolation'
        ELSE '❌ Colonnes d''isolation manquantes'
    END as colonnes_isolation,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.triggers 
            WHERE trigger_name = 'set_products_isolation_trigger'
            AND event_object_table = 'products'
        ) THEN '✅ Trigger d''isolation'
        ELSE '❌ Trigger d''isolation manquant'
    END as trigger_isolation;

SELECT 
    CASE 
        WHEN (
            EXISTS (SELECT FROM pg_tables WHERE tablename = 'products' AND rowsecurity = true) AND
            EXISTS (SELECT FROM pg_policies WHERE tablename = 'products' AND cmd = 'INSERT') AND
            EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'products' AND column_name IN ('user_id', 'created_by', 'workshop_id'))
        ) THEN '🎉 TABLE PRODUCTS CORRECTEMENT CONFIGURÉE'
        ELSE '⚠️ TABLE PRODUCTS NÉCESSITE UNE CORRECTION'
    END as statut_final;
