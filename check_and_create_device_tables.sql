-- ============================================================================
-- VÉRIFICATION ET CRÉATION DES TABLES POUR LA GESTION DES APPAREILS
-- ============================================================================
-- Date: $(date)
-- Description: Vérifier l'existence et créer les tables manquantes pour les catégories, marques et modèles
-- ============================================================================

-- 1. VÉRIFIER L'EXISTENCE DES TABLES
-- ============================================================================
SELECT '=== VÉRIFICATION EXISTENCE TABLES ===' as section;

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('device_categories', 'device_brands', 'device_models') 
        THEN '✅ Table existe'
        ELSE '❌ Table manquante'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('device_categories', 'device_brands', 'device_models')
ORDER BY table_name;

-- 2. CRÉER LA TABLE device_categories SI ELLE N'EXISTE PAS
-- ============================================================================
SELECT '=== CRÉATION TABLE device_categories ===' as section;

CREATE TABLE IF NOT EXISTS public.device_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'smartphone',
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CRÉER LA TABLE device_brands SI ELLE N'EXISTE PAS
-- ============================================================================
SELECT '=== CRÉATION TABLE device_brands ===' as section;

CREATE TABLE IF NOT EXISTS public.device_brands (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE,
    description TEXT,
    logo TEXT,
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. VÉRIFIER ET COMPLÉTER LA TABLE device_models
-- ============================================================================
SELECT '=== VÉRIFICATION TABLE device_models ===' as section;

-- Ajouter les colonnes manquantes si nécessaire
DO $$
BEGIN
    -- Vérifier et ajouter brand_id si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'brand_id'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN brand_id UUID REFERENCES public.device_brands(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne brand_id ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne brand_id existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter category_id si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'category_id'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne category_id ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne category_id existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter specifications si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN specifications JSONB DEFAULT '{}';
        RAISE NOTICE '✅ Colonne specifications ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne specifications existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter common_issues si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'common_issues'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN common_issues TEXT[] DEFAULT '{}';
        RAISE NOTICE '✅ Colonne common_issues ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne common_issues existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter repair_difficulty si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'repair_difficulty'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN repair_difficulty TEXT DEFAULT 'medium' CHECK (repair_difficulty IN ('easy', 'medium', 'hard'));
        RAISE NOTICE '✅ Colonne repair_difficulty ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne repair_difficulty existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter parts_availability si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'parts_availability'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN parts_availability TEXT DEFAULT 'medium' CHECK (parts_availability IN ('high', 'medium', 'low'));
        RAISE NOTICE '✅ Colonne parts_availability ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne parts_availability existe déjà dans device_models';
    END IF;

    -- Vérifier et ajouter is_active si nécessaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.device_models 
        ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne is_active ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne is_active existe déjà dans device_models';
    END IF;
END $$;

-- 5. ACTIVER RLS SUR LES TABLES
-- ============================================================================
SELECT '=== ACTIVATION RLS ===' as section;

ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER LES POLITIQUES RLS POUR device_categories
-- ============================================================================
SELECT '=== POLITIQUES RLS device_categories ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can insert their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can update their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can delete their own device categories" ON public.device_categories;

-- Créer les nouvelles politiques
CREATE POLICY "Users can view their own device categories" ON public.device_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device categories" ON public.device_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device categories" ON public.device_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device categories" ON public.device_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 7. CRÉER LES POLITIQUES RLS POUR device_brands
-- ============================================================================
SELECT '=== POLITIQUES RLS device_brands ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can insert their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can update their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can delete their own device brands" ON public.device_brands;

-- Créer les nouvelles politiques
CREATE POLICY "Users can view their own device brands" ON public.device_brands
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device brands" ON public.device_brands
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device brands" ON public.device_brands
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device brands" ON public.device_brands
    FOR DELETE USING (auth.uid() = user_id);

-- 8. CRÉER LES TRIGGERS POUR L'ISOLATION
-- ============================================================================
SELECT '=== CRÉATION TRIGGERS ===' as section;

-- Fonction pour device_categories
CREATE OR REPLACE FUNCTION set_device_categories_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour device_brands
CREATE OR REPLACE FUNCTION set_device_brands_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer les anciens triggers
DROP TRIGGER IF EXISTS set_device_categories_context_trigger ON public.device_categories;
DROP TRIGGER IF EXISTS set_device_brands_context_trigger ON public.device_brands;

-- Créer les nouveaux triggers
CREATE TRIGGER set_device_categories_context_trigger
    BEFORE INSERT ON public.device_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_device_categories_context();

CREATE TRIGGER set_device_brands_context_trigger
    BEFORE INSERT ON public.device_brands
    FOR EACH ROW
    EXECUTE FUNCTION set_device_brands_context();

-- 9. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure des tables
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('device_categories', 'device_brands', 'device_models')
ORDER BY table_name, ordinal_position;

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tablename, policyname;

DO $$
BEGIN
    RAISE NOTICE '🎉 Vérification et création des tables terminée !';
    RAISE NOTICE '✅ Les tables device_categories, device_brands et device_models sont prêtes';
    RAISE NOTICE '✅ Les politiques RLS sont configurées';
    RAISE NOTICE '✅ Les triggers d''isolation sont en place';
END $$;
