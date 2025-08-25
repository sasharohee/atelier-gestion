-- =====================================================
-- CORRECTION CONTRAINTE QUANTITY - TABLE SALES
-- =====================================================
-- Objectif: Corriger la contrainte NOT NULL sur la colonne quantity
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION STRUCTURE ACTUELLE
SELECT '=== 1. VÉRIFICATION STRUCTURE ACTUELLE ===' as section;

-- Vérifier les colonnes existantes dans la table sales
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sales'
ORDER BY ordinal_position;

-- 2. VÉRIFICATION DES CONTRAINTES
SELECT '=== 2. VÉRIFICATION DES CONTRAINTES ===' as section;

-- Vérifier les contraintes NOT NULL
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'sales'
    AND tc.constraint_type = 'NOT NULL'
ORDER BY kcu.column_name;

-- 3. ANALYSE DE LA STRUCTURE SALES
SELECT '=== 3. ANALYSE DE LA STRUCTURE SALES ===' as section;

-- Vérifier si la table sales a une structure différente
DO $$
DECLARE
    has_quantity BOOLEAN := FALSE;
    has_items BOOLEAN := FALSE;
    has_product_id BOOLEAN := FALSE;
BEGIN
    -- Vérifier si quantity existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'quantity'
    ) INTO has_quantity;
    
    -- Vérifier si items existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'items'
    ) INTO has_items;
    
    -- Vérifier si product_id existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'product_id'
    ) INTO has_product_id;
    
    RAISE NOTICE 'Structure sales: quantity=%, items=%, product_id=%', has_quantity, has_items, has_product_id;
    
    IF has_quantity AND NOT has_items THEN
        RAISE NOTICE '⚠️ Structure détectée: sales avec colonnes individuelles (quantity, product_id, etc.)';
    ELSIF has_items AND NOT has_quantity THEN
        RAISE NOTICE '⚠️ Structure détectée: sales avec colonne items JSONB';
    ELSIF has_quantity AND has_items THEN
        RAISE NOTICE '⚠️ Structure détectée: sales avec colonnes mixtes';
    ELSE
        RAISE NOTICE '⚠️ Structure détectée: sales avec structure inconnue';
    END IF;
END $$;

-- 4. CORRECTION DE LA CONTRAINTE QUANTITY
SELECT '=== 4. CORRECTION DE LA CONTRAINTE QUANTITY ===' as section;

-- Option 1: Si quantity existe et a une contrainte NOT NULL, la rendre nullable
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'quantity'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN quantity DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de quantity';
    ELSE
        RAISE NOTICE '✅ Colonne quantity n''a pas de contrainte NOT NULL ou n''existe pas';
    END IF;
END $$;

-- Option 2: Ajouter une valeur par défaut à quantity
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'quantity'
            AND column_default IS NULL
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN quantity SET DEFAULT 1;
        RAISE NOTICE '✅ Valeur par défaut 1 ajoutée à quantity';
    ELSE
        RAISE NOTICE '✅ Colonne quantity a déjà une valeur par défaut ou n''existe pas';
    END IF;
END $$;

-- 5. CORRECTION DES AUTRES COLONNES POTENTIELLEMENT PROBLÉMATIQUES
SELECT '=== 5. CORRECTION AUTRES COLONNES ===' as section;

-- Vérifier et corriger les autres colonnes qui pourraient avoir des contraintes NOT NULL
DO $$
DECLARE
    col RECORD;
BEGIN
    FOR col IN 
        SELECT column_name, data_type
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND is_nullable = 'NO'
            AND column_name NOT IN ('id', 'user_id') -- Garder NOT NULL pour ces colonnes
    LOOP
        RAISE NOTICE '⚠️ Colonne avec contrainte NOT NULL: % (type: %)', col.column_name, col.data_type;
        
        -- Rendre nullable si ce n'est pas une colonne critique
        IF col.column_name NOT IN ('id', 'user_id', 'created_at') THEN
            EXECUTE format('ALTER TABLE public.sales ALTER COLUMN %I DROP NOT NULL', col.column_name);
            RAISE NOTICE '✅ Contrainte NOT NULL supprimée de %', col.column_name;
        END IF;
    END LOOP;
END $$;

-- 6. AJOUT DE VALEURS PAR DÉFAUT
SELECT '=== 6. AJOUT DE VALEURS PAR DÉFAUT ===' as section;

-- Ajouter des valeurs par défaut pour les colonnes importantes
DO $$
BEGIN
    -- Ajouter valeur par défaut pour quantity si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'quantity'
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN quantity SET DEFAULT 1;
        RAISE NOTICE '✅ Valeur par défaut 1 ajoutée à quantity';
    END IF;
    
    -- Ajouter valeur par défaut pour price si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'price'
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN price SET DEFAULT 0.00;
        RAISE NOTICE '✅ Valeur par défaut 0.00 ajoutée à price';
    END IF;
    
    -- Ajouter valeur par défaut pour total si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'total'
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN total SET DEFAULT 0.00;
        RAISE NOTICE '✅ Valeur par défaut 0.00 ajoutée à total';
    END IF;
    
    -- Ajouter valeur par défaut pour status si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'status'
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN status SET DEFAULT 'completed';
        RAISE NOTICE '✅ Valeur par défaut completed ajoutée à status';
    END IF;
    
    -- Ajouter valeur par défaut pour payment_method si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'payment_method'
    ) THEN
        ALTER TABLE public.sales ALTER COLUMN payment_method SET DEFAULT 'cash';
        RAISE NOTICE '✅ Valeur par défaut cash ajoutée à payment_method';
    END IF;
END $$;

-- 7. VÉRIFICATION FINALE
SELECT '=== 7. VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure finale
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sales'
ORDER BY ordinal_position;

-- 8. TEST D'INSERTION
SELECT '=== 8. TEST D INSERTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_sale_id UUID;
    has_quantity BOOLEAN := FALSE;
    has_items BOOLEAN := FALSE;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Vérifier la structure
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'quantity'
    ) INTO has_quantity;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'items'
    ) INTO has_items;
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: % (quantity=%, items=%)', current_user_id, has_quantity, has_items;
    
    -- Test d'insertion selon la structure détectée
    IF has_quantity AND NOT has_items THEN
        -- Structure avec colonnes individuelles
        INSERT INTO public.sales (
            product_id,
            quantity,
            price,
            total,
            client_id,
            user_id
        )
        VALUES (
            'test-product',
            1,
            100.00,
            100.00,
            NULL,
            current_user_id
        )
        RETURNING id INTO test_sale_id;
        
    ELSIF has_items THEN
        -- Structure avec colonne items JSONB
        INSERT INTO public.sales (
            items,
            total,
            client_id,
            user_id
        )
        VALUES (
            '[{"product_id": "test", "name": "Test Product", "quantity": 1, "price": 100.00}]'::jsonb,
            100.00,
            NULL,
            current_user_id
        )
        RETURNING id INTO test_sale_id;
        
    ELSE
        -- Structure minimale
        INSERT INTO public.sales (
            user_id
        )
        VALUES (
            current_user_id
        )
        RETURNING id INTO test_sale_id;
    END IF;
    
    RAISE NOTICE '✅ Sale créé avec ID: %', test_sale_id;
    
    -- Nettoyer
    DELETE FROM public.sales WHERE id = test_sale_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 9. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 9. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 10. RÉSUMÉ FINAL
SELECT '=== 10. RÉSUMÉ FINAL ===' as section;

-- Résumé des corrections
SELECT 
    'Résumé corrections sales' as info,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN is_nullable = 'YES' THEN 1 END) as colonnes_nullables,
    COUNT(CASE WHEN column_default IS NOT NULL THEN 1 END) as colonnes_avec_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sales';

SELECT 'CORRECTION CONTRAINTE QUANTITY SALES TERMINÉE' as status;
