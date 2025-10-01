-- ============================================================================
-- SCRIPT RAPIDE - CRÉATION DES TABLES MANQUANTES
-- ============================================================================
-- Ce script crée uniquement les tables manquantes pour résoudre l'erreur immédiate
-- ============================================================================

SELECT '=== CRÉATION DES TABLES MANQUANTES ===' as section;

-- 1. CRÉER LA TABLE DEVICE_CATEGORIES (si elle n'existe pas)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.device_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'smartphone',
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

SELECT '✅ Table device_categories créée ou vérifiée' as status;

-- 2. CRÉER LA TABLE DEVICE_BRANDS (si elle n'existe pas)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.device_brands (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    logo TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contrainte de clé primaire composite
    PRIMARY KEY (id, user_id)
);

SELECT '✅ Table device_brands créée ou vérifiée' as status;

-- 3. CRÉER LA TABLE BRAND_CATEGORIES (si elle n'existe pas)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.brand_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand_id TEXT NOT NULL,
    category_id UUID NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contrainte d'unicité pour éviter les doublons
    UNIQUE(brand_id, category_id)
);

-- Si la table existe déjà mais avec un mauvais type, la corriger
DO $$
BEGIN
    -- Vérifier si brand_id est de type UUID et le changer en TEXT
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'brand_categories' 
        AND column_name = 'brand_id' 
        AND data_type = 'uuid'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.brand_categories ALTER COLUMN brand_id TYPE TEXT;
        RAISE NOTICE '✅ Type de brand_id corrigé de UUID vers TEXT dans brand_categories';
    END IF;
END $$;

SELECT '✅ Table brand_categories créée ou vérifiée' as status;

-- 4. ACTIVER RLS SUR LES TABLES
-- ============================================================================
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;

SELECT '✅ RLS activé sur toutes les tables' as status;

-- 5. CRÉER LES POLITIQUES RLS
-- ============================================================================

-- Politique pour device_brands
DROP POLICY IF EXISTS "Users can manage their own brands" ON public.device_brands;
CREATE POLICY "Users can manage their own brands" ON public.device_brands
    FOR ALL USING (user_id = auth.uid());

-- Politique pour brand_categories
DROP POLICY IF EXISTS "Users can manage their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can manage their own brand categories" ON public.brand_categories
    FOR ALL USING (user_id = auth.uid());

-- Politique pour device_categories
DROP POLICY IF EXISTS "Users can manage their own device categories" ON public.device_categories;
CREATE POLICY "Users can manage their own device categories" ON public.device_categories
    FOR ALL USING (user_id = auth.uid());

SELECT '✅ Politiques RLS créées' as status;

-- 6. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que toutes les tables existent
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_brands' AND table_schema = 'public') 
        THEN '✅ device_brands'
        ELSE '❌ device_brands MANQUANTE'
    END as table_status
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'brand_categories' AND table_schema = 'public') 
        THEN '✅ brand_categories'
        ELSE '❌ brand_categories MANQUANTE'
    END as table_status
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_categories' AND table_schema = 'public') 
        THEN '✅ device_categories'
        ELSE '❌ device_categories MANQUANTE'
    END as table_status;

SELECT '=== TABLES CRÉÉES AVEC SUCCÈS ===' as section;
