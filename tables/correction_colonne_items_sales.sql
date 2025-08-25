-- =====================================================
-- CORRECTION COLONNE ITEMS MANQUANTE - TABLE SALES
-- =====================================================
-- Objectif: Ajouter la colonne items manquante à la table sales
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION STRUCTURE ACTUELLE
SELECT '=== 1. VÉRIFICATION STRUCTURE ACTUELLE ===' as section;

-- Vérifier les colonnes existantes dans la table sales
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sales'
ORDER BY ordinal_position;

-- 2. AJOUT DE LA COLONNE ITEMS
SELECT '=== 2. AJOUT DE LA COLONNE ITEMS ===' as section;

-- Ajouter la colonne items si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'items'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN items JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE '✅ Colonne items ajoutée à sales avec valeur par défaut []';
    ELSE
        RAISE NOTICE '✅ Colonne items existe déjà dans sales';
    END IF;
END $$;

-- 3. VÉRIFICATION DES AUTRES COLONNES MANQUANTES
SELECT '=== 3. VÉRIFICATION AUTRES COLONNES ===' as section;

-- Vérifier les colonnes couramment utilisées dans sales
DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[
        'client_id',
        'subtotal', 
        'tax',
        'total',
        'payment_method',
        'status',
        'user_id',
        'created_at',
        'updated_at'
    ];
    col TEXT;
BEGIN
    FOREACH col IN ARRAY missing_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'sales' 
                AND column_name = col
        ) THEN
            RAISE NOTICE '⚠️ Colonne manquante: %', col;
        ELSE
            RAISE NOTICE '✅ Colonne présente: %', col;
        END IF;
    END LOOP;
END $$;

-- 4. AJOUT DES COLONNES MANQUANTES
SELECT '=== 4. AJOUT DES COLONNES MANQUANTES ===' as section;

-- Ajouter client_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'client_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Colonne client_id ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne client_id existe déjà dans sales';
    END IF;
END $$;

-- Ajouter subtotal si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'subtotal'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN subtotal DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE '✅ Colonne subtotal ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne subtotal existe déjà dans sales';
    END IF;
END $$;

-- Ajouter tax si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'tax'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN tax DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE '✅ Colonne tax ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne tax existe déjà dans sales';
    END IF;
END $$;

-- Ajouter total si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'total'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN total DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE '✅ Colonne total ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne total existe déjà dans sales';
    END IF;
END $$;

-- Ajouter payment_method si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'payment_method'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN payment_method VARCHAR(50) DEFAULT 'cash';
        RAISE NOTICE '✅ Colonne payment_method ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne payment_method existe déjà dans sales';
    END IF;
END $$;

-- Ajouter status si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'status'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN status VARCHAR(50) DEFAULT 'completed';
        RAISE NOTICE '✅ Colonne status ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne status existe déjà dans sales';
    END IF;
END $$;

-- Ajouter user_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans sales';
    END IF;
END $$;

-- Ajouter created_at si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans sales';
    END IF;
END $$;

-- Ajouter updated_at si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans sales';
    END IF;
END $$;

-- 5. VÉRIFICATION FINALE
SELECT '=== 5. VÉRIFICATION FINALE ===' as section;

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

-- 6. TEST D'INSERTION
SELECT '=== 6. TEST D INSERTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_sale_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion avec colonnes complètes pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans sales avec toutes les colonnes
    INSERT INTO public.sales (
        client_id,
        items,
        subtotal,
        tax,
        total,
        payment_method,
        status,
        user_id
    )
    VALUES (
        NULL, -- client_id peut être NULL
        '[{"product_id": "test", "name": "Test Product", "quantity": 1, "price": 100.00}]'::jsonb,
        100.00,
        20.00,
        120.00,
        'cash',
        'completed',
        current_user_id
    )
    RETURNING id INTO test_sale_id;
    
    RAISE NOTICE '✅ Sale créé avec ID: %', test_sale_id;
    
    -- Nettoyer
    DELETE FROM public.sales WHERE id = test_sale_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 7. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 7. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 8. RÉSUMÉ FINAL
SELECT '=== 8. RÉSUMÉ FINAL ===' as section;

-- Résumé des corrections
SELECT 
    'Résumé corrections sales' as info,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name IN ('items', 'client_id', 'subtotal', 'tax', 'total', 'payment_method', 'status', 'user_id', 'created_at', 'updated_at') THEN 1 END) as colonnes_essentielles
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sales';

SELECT 'CORRECTION COLONNE ITEMS SALES TERMINÉE' as status;
