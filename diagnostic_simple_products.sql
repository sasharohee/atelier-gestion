-- 🔍 DIAGNOSTIC SIMPLE - État actuel de la table products
-- Script de diagnostic qui ne dépend pas des colonnes d'isolation

-- ========================================
-- DIAGNOSTIC 1: STRUCTURE DE BASE DE LA TABLE
-- ========================================

SELECT 
    '=== STRUCTURE TABLE PRODUCTS ===' as section,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IN ('id', 'created_at', 'updated_at') THEN '📅 COLONNE SYSTÈME'
        WHEN column_name IN ('name', 'description', 'price', 'stock_quantity', 'category', 'is_active') THEN '📋 COLONNE MÉTIER'
        WHEN column_name IN ('user_id', 'created_by', 'workshop_id') THEN '🔒 COLONNE D''ISOLATION'
        ELSE '❓ AUTRE COLONNE'
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
    cmd as operation
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
    CASE 
        WHEN trigger_name = 'set_products_isolation_trigger' THEN '✅ TRIGGER D''ISOLATION'
        ELSE 'ℹ️ AUTRE TRIGGER'
    END as type_trigger
FROM information_schema.triggers 
WHERE event_object_table = 'products'
ORDER BY trigger_name;

-- ========================================
-- DIAGNOSTIC 5: DONNÉES EXISTANTES (SANS COLONNES D'ISOLATION)
-- ========================================

SELECT 
    '=== DONNÉES PRODUCTS EXISTANTES ===' as section,
    COUNT(*) as total_produits,
    COUNT(CASE WHEN is_active = true THEN 1 END) as produits_actifs,
    COUNT(CASE WHEN is_active = false THEN 1 END) as produits_inactifs,
    COUNT(CASE WHEN stock_quantity > 0 THEN 1 END) as produits_en_stock,
    COUNT(CASE WHEN stock_quantity = 0 THEN 1 END) as produits_rupture_stock
FROM products;

-- ========================================
-- DIAGNOSTIC 6: VÉRIFICATION COLONNES D'ISOLATION
-- ========================================

DO $$
DECLARE
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
    problemes TEXT[] := ARRAY[]::TEXT[];
BEGIN
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
    
    -- Identifier les problèmes
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
    RAISE NOTICE '=== VÉRIFICATION COLONNES D''ISOLATION ===';
    RAISE NOTICE 'user_id: %s', CASE WHEN user_id_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END;
    RAISE NOTICE 'created_by: %s', CASE WHEN created_by_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END;
    RAISE NOTICE 'workshop_id: %s', CASE WHEN workshop_id_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END;
    
    IF array_length(problemes, 1) IS NULL THEN
        RAISE NOTICE '✅ Toutes les colonnes d''isolation sont présentes';
    ELSE
        RAISE NOTICE '❌ Colonnes d''isolation manquantes (%):', array_length(problemes, 1);
        FOR i IN 1..array_length(problemes, 1) LOOP
            RAISE NOTICE '  %: %', i, problemes[i];
        END LOOP;
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
            gen_random_uuid(), 'Test Diagnostic Simple', 'Test Description', 25.00, 10, 'Test Category', true,
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

DO $$
DECLARE
    rls_actif BOOLEAN;
    politique_insert_existe BOOLEAN;
    trigger_isolation_existe BOOLEAN;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
    total_problemes INTEGER := 0;
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
    
    -- Compter les problèmes
    IF NOT rls_actif THEN total_problemes := total_problemes + 1; END IF;
    IF NOT politique_insert_existe THEN total_problemes := total_problemes + 1; END IF;
    IF NOT trigger_isolation_existe THEN total_problemes := total_problemes + 1; END IF;
    IF NOT user_id_exists THEN total_problemes := total_problemes + 1; END IF;
    IF NOT created_by_exists THEN total_problemes := total_problemes + 1; END IF;
    IF NOT workshop_id_exists THEN total_problemes := total_problemes + 1; END IF;
    
    -- Afficher le résumé
    RAISE NOTICE '=== RÉSUMÉ DIAGNOSTIC ===';
    RAISE NOTICE 'RLS activé: %s', CASE WHEN rls_actif THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Politique INSERT: %s', CASE WHEN politique_insert_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Trigger d''isolation: %s', CASE WHEN trigger_isolation_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne user_id: %s', CASE WHEN user_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne created_by: %s', CASE WHEN created_by_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne workshop_id: %s', CASE WHEN workshop_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Total problèmes identifiés: %', total_problemes;
    
    IF total_problemes = 0 THEN
        RAISE NOTICE '🎉 TABLE PRODUCTS CORRECTEMENT CONFIGURÉE';
    ELSE
        RAISE NOTICE '⚠️ TABLE PRODUCTS NÉCESSITE UNE CORRECTION';
        RAISE NOTICE '💡 SOLUTION: Exécutez le script correction_type_discount_percentage.sql';
    END IF;
END $$;
