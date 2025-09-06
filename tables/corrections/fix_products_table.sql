-- CORRECTION DE LA TABLE PRODUCTS
-- Ce script corrige la structure de la table products pour résoudre l'erreur is_active

-- ============================================================================
-- 1. VÉRIFICATION DE LA STRUCTURE ACTUELLE
-- ============================================================================

-- Vérifier les colonnes existantes
SELECT 
    'Structure actuelle products' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. AJOUT DE LA COLONNE USER_ID MANQUANTE
-- ============================================================================

-- Ajouter la colonne user_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà';
    END IF;
END $$;

-- ============================================================================
-- 3. VÉRIFICATION DE LA COLONNE IS_ACTIVE
-- ============================================================================

-- Vérifier si la colonne is_active existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Colonne is_active ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne is_active existe déjà';
    END IF;
END $$;

-- ============================================================================
-- 4. VÉRIFICATION DES AUTRES COLONNES NÉCESSAIRES
-- ============================================================================

-- Ajouter les colonnes manquantes si nécessaire
DO $$
BEGIN
    -- Vérifier et ajouter stock_quantity
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'stock_quantity'
    ) THEN
        ALTER TABLE public.products ADD COLUMN stock_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne stock_quantity ajoutée';
    END IF;
    
    -- Vérifier et ajouter category
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'category'
    ) THEN
        ALTER TABLE public.products ADD COLUMN category TEXT;
        RAISE NOTICE 'Colonne category ajoutée';
    END IF;
    
    -- Vérifier et ajouter created_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.products ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Colonne created_at ajoutée';
    END IF;
    
    -- Vérifier et ajouter updated_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.products ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Colonne updated_at ajoutée';
    END IF;
END $$;

-- ============================================================================
-- 5. VÉRIFICATION FINALE DE LA STRUCTURE
-- ============================================================================

-- Afficher la structure finale
SELECT 
    'Structure finale products' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;

-- ============================================================================
-- 6. RÉFRESH DU CACHE DE SCHÉMA POSTGREST
-- ============================================================================

-- Notifier PostgREST de rafraîchir son cache de schéma
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- 7. TEST D'INSERTION
-- ============================================================================

-- Test d'insertion d'un produit de test (à supprimer après)
INSERT INTO public.products (
    name, 
    description, 
    category, 
    price, 
    stock_quantity, 
    is_active, 
    user_id,
    created_at, 
    updated_at
) VALUES (
    'Test Product',
    'Produit de test pour vérification',
    'test',
    10.00,
    5,
    true,
    (SELECT id FROM public.users LIMIT 1),
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Vérifier l'insertion
SELECT 
    'Test insertion' as check_type,
    id,
    name,
    is_active,
    user_id
FROM public.products 
WHERE name = 'Test Product'
LIMIT 1;

-- Nettoyer le produit de test
DELETE FROM public.products WHERE name = 'Test Product';

-- ============================================================================
-- 8. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

-- Vérifier les politiques RLS pour products
SELECT 
    'Politiques RLS products' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'products'
ORDER BY policyname;
