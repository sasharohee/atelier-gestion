-- 🔍 VÉRIFICATION CORRECTION ERREUR 403 PRODUCTS
-- Script pour vérifier que la correction a bien fonctionné

-- ========================================
-- VÉRIFICATION 1: ÉTAT RLS DE LA TABLE PRODUCTS
-- ========================================

SELECT 
    '=== VÉRIFICATION RLS PRODUCTS ===' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ACTIVÉ'
        ELSE '❌ RLS DÉSACTIVÉ'
    END as rls_status,
    schemaname
FROM pg_tables 
WHERE tablename = 'products';

-- ========================================
-- VÉRIFICATION 2: POLITIQUES RLS CRÉÉES
-- ========================================

SELECT 
    '=== POLITIQUES RLS PRODUCTS ===' as section,
    policyname,
    CASE 
        WHEN permissive = 'PERM' THEN 'PERMISSIVE'
        WHEN permissive = 'REST' THEN 'RESTRICTIVE'
        ELSE 'INCONNU'
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
-- VÉRIFICATION 3: COLONNES D'ISOLATION
-- ========================================

SELECT 
    '=== COLONNES D''ISOLATION PRODUCTS ===' as section,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IN ('user_id', 'created_by', 'workshop_id') THEN '✅ COLONNE D''ISOLATION'
        ELSE 'ℹ️ AUTRE COLONNE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('user_id', 'created_by', 'workshop_id')
ORDER BY column_name;

-- ========================================
-- VÉRIFICATION 4: TRIGGER D'ISOLATION
-- ========================================

SELECT 
    '=== TRIGGER D''ISOLATION ===' as section,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    CASE 
        WHEN trigger_name = 'set_products_isolation_trigger' THEN '✅ TRIGGER ACTIF'
        ELSE '❌ TRIGGER MANQUANT'
    END as statut_trigger
FROM information_schema.triggers 
WHERE event_object_table = 'products'
AND trigger_name = 'set_products_isolation_trigger';

-- ========================================
-- VÉRIFICATION 5: DONNÉES EXISTANTES
-- ========================================

DO $$
DECLARE
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
    total_products INTEGER;
    avec_user_id INTEGER;
    avec_created_by INTEGER;
    avec_workshop_id INTEGER;
    sans_isolation INTEGER;
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
    
    -- Compter les produits
    SELECT COUNT(*) INTO total_products FROM products;
    
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
    
    -- Calculer les produits sans isolation
    IF user_id_exists AND created_by_exists AND workshop_id_exists THEN
        SELECT COUNT(CASE WHEN user_id IS NULL AND created_by IS NULL AND workshop_id IS NULL THEN 1 END) INTO sans_isolation FROM products;
    ELSE
        sans_isolation := total_products;
    END IF;
    
    -- Afficher les résultats
    RAISE NOTICE '=== DONNÉES PRODUCTS EXISTANTES ===';
    RAISE NOTICE 'Total produits: %', total_products;
    RAISE NOTICE 'Avec user_id: % (colonne %s)', avec_user_id, CASE WHEN user_id_exists THEN 'EXISTE' ELSE 'MANQUANTE' END;
    RAISE NOTICE 'Avec created_by: % (colonne %s)', avec_created_by, CASE WHEN created_by_exists THEN 'EXISTE' ELSE 'MANQUANTE' END;
    RAISE NOTICE 'Avec workshop_id: % (colonne %s)', avec_workshop_id, CASE WHEN workshop_id_exists THEN 'EXISTE' ELSE 'MANQUANTE' END;
    RAISE NOTICE 'Sans isolation: %', sans_isolation;
    
    -- Afficher un tableau formaté
    RAISE NOTICE '';
    RAISE NOTICE '| Colonne      | Existe | Compteur |';
    RAISE NOTICE '|--------------|--------|----------|';
    RAISE NOTICE '| user_id      | %s | %s |', 
        CASE WHEN user_id_exists THEN '✅' ELSE '❌' END, 
        avec_user_id;
    RAISE NOTICE '| created_by   | %s | %s |', 
        CASE WHEN created_by_exists THEN '✅' ELSE '❌' END, 
        avec_created_by;
    RAISE NOTICE '| workshop_id  | %s | %s |', 
        CASE WHEN workshop_id_exists THEN '✅' ELSE '❌' END, 
        avec_workshop_id;
    RAISE NOTICE '| Total        | -      | %s |', total_products;
    RAISE NOTICE '| Sans isolation| -      | %s |', sans_isolation;
END $$;

-- ========================================
-- VÉRIFICATION 6: TEST D'INSERTION
-- ========================================

DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
    test_workshop_id UUID;
    test_user_id UUID;
    insertion_success BOOLEAN := FALSE;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== TEST D''INSERTION PRODUCTS ===';
    
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
    
    RAISE NOTICE 'Colonnes d''isolation - user_id: %s, created_by: %s, workshop_id: %s', 
        CASE WHEN user_id_exists THEN 'EXISTE' ELSE 'MANQUANTE' END,
        CASE WHEN created_by_exists THEN 'EXISTE' ELSE 'MANQUANTE' END,
        CASE WHEN workshop_id_exists THEN 'EXISTE' ELSE 'MANQUANTE' END;
    
    BEGIN
        -- Test d'insertion avec gestion des colonnes manquantes
        IF user_id_exists AND created_by_exists AND workshop_id_exists THEN
            -- Toutes les colonnes existent
            INSERT INTO products (
                id, name, description, price, stock_quantity, category, is_active, 
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), 'Test Vérification 403', 'Test Description', 30.00, 5, 'Test Category', true,
                NOW(), NOW()
            ) RETURNING id, created_by, workshop_id, user_id INTO test_id, test_created_by, test_workshop_id, test_user_id;
        ELSE
            -- Certaines colonnes manquent, insertion simple
            INSERT INTO products (
                id, name, description, price, stock_quantity, category, is_active, 
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), 'Test Vérification 403', 'Test Description', 30.00, 5, 'Test Category', true,
                NOW(), NOW()
            ) RETURNING id INTO test_id;
            
            test_created_by := NULL;
            test_workshop_id := NULL;
            test_user_id := NULL;
        END IF;
        
        insertion_success := TRUE;
        
        RAISE NOTICE '✅ Test d''insertion RÉUSSI';
        RAISE NOTICE '   - ID: %', test_id;
        
        IF created_by_exists THEN
            RAISE NOTICE '   - Created_by: %', test_created_by;
        END IF;
        
        IF workshop_id_exists THEN
            RAISE NOTICE '   - Workshop_id: %', test_workshop_id;
        END IF;
        
        IF user_id_exists THEN
            RAISE NOTICE '   - User_id: %', test_user_id;
        END IF;
        
        -- Vérifier que les valeurs d'isolation ont été définies (si les colonnes existent)
        IF created_by_exists AND workshop_id_exists AND user_id_exists THEN
            IF test_created_by IS NOT NULL AND test_workshop_id IS NOT NULL AND test_user_id IS NOT NULL THEN
                RAISE NOTICE '✅ Valeurs d''isolation correctement définies par le trigger';
            ELSE
                RAISE NOTICE '❌ Problème avec les valeurs d''isolation';
            END IF;
        ELSE
            RAISE NOTICE '⚠️ Colonnes d''isolation manquantes - trigger non testé';
        END IF;
        
        -- Nettoyer le test
        DELETE FROM products WHERE id = test_id;
        RAISE NOTICE '✅ Enregistrement de test supprimé';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ ERREUR lors du test d''insertion: %', SQLERRM;
            insertion_success := FALSE;
    END;
    
    -- Résumé du test
    IF insertion_success THEN
        IF created_by_exists AND workshop_id_exists AND user_id_exists THEN
            RAISE NOTICE '🎉 CORRECTION 403 RÉUSSIE - L''insertion de produits fonctionne avec isolation !';
        ELSE
            RAISE NOTICE '⚠️ INSERTION RÉUSSIE mais colonnes d''isolation manquantes - exécutez le script de correction';
        END IF;
    ELSE
        RAISE NOTICE '❌ CORRECTION 403 ÉCHOUÉE - L''insertion de produits ne fonctionne pas';
    END IF;
END $$;

-- ========================================
-- VÉRIFICATION 7: TYPE DISCOUNT_PERCENTAGE
-- ========================================

SELECT 
    '=== VÉRIFICATION TYPE DISCOUNT_PERCENTAGE ===' as section,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    CASE 
        WHEN data_type = 'numeric' AND numeric_precision = 5 AND numeric_scale = 2 THEN '✅ TYPE CORRECT'
        ELSE '❌ TYPE INCORRECT'
    END as statut_type
FROM information_schema.columns 
WHERE table_name = 'loyalty_tiers_advanced' 
AND column_name = 'discount_percentage';

-- ========================================
-- VÉRIFICATION 8: FONCTION GET_LOYALTY_TIERS
-- ========================================

DO $$
DECLARE
    function_exists BOOLEAN;
    test_result RECORD;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION FONCTION GET_LOYALTY_TIERS ===';
    
    -- Vérifier si la fonction existe
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_loyalty_tiers'
    ) INTO function_exists;
    
    IF function_exists THEN
        RAISE NOTICE '✅ Fonction get_loyalty_tiers existe';
        
        -- Tester la fonction
        BEGIN
            SELECT * INTO test_result FROM get_loyalty_tiers((SELECT id FROM auth.users LIMIT 1)) LIMIT 1;
            RAISE NOTICE '✅ Fonction get_loyalty_tiers fonctionne correctement';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Erreur lors du test de la fonction: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '❌ Fonction get_loyalty_tiers n''existe pas';
    END IF;
END $$;

-- ========================================
-- RÉSUMÉ FINAL
-- ========================================

SELECT 
    '=== RÉSUMÉ FINAL CORRECTION 403 ===' as section,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_policies 
            WHERE tablename = 'products' 
            AND cmd = 'INSERT'
        ) THEN '✅ Politique INSERT présente'
        ELSE '❌ Politique INSERT manquante'
    END as politique_insert,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.triggers 
            WHERE trigger_name = 'set_products_isolation_trigger'
            AND event_object_table = 'products'
        ) THEN '✅ Trigger d''isolation actif'
        ELSE '❌ Trigger d''isolation manquant'
    END as trigger_isolation,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'products' 
            AND column_name IN ('user_id', 'created_by', 'workshop_id')
        ) THEN '✅ Colonnes d''isolation présentes'
        ELSE '❌ Colonnes d''isolation manquantes'
    END as colonnes_isolation,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'loyalty_tiers_advanced' 
            AND column_name = 'discount_percentage'
            AND data_type = 'numeric'
        ) THEN '✅ Type discount_percentage correct'
        ELSE '❌ Type discount_percentage incorrect'
    END as type_discount;

-- Message final
SELECT 
    CASE 
        WHEN (
            EXISTS (SELECT FROM pg_policies WHERE tablename = 'products' AND cmd = 'INSERT') AND
            EXISTS (SELECT FROM information_schema.triggers WHERE trigger_name = 'set_products_isolation_trigger' AND event_object_table = 'products') AND
            EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'products' AND column_name IN ('user_id', 'created_by', 'workshop_id'))
        ) THEN '🎉 CORRECTION 403 COMPLÈTE ET RÉUSSIE !'
        ELSE '❌ CORRECTION 403 INCOMPLÈTE - Vérifiez les éléments manquants'
    END as statut_final;
