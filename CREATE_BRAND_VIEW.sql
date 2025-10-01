-- ============================================================================
-- SCRIPT RAPIDE - CRÉATION DE LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
-- Ce script crée uniquement la vue brand_with_categories manquante
-- ============================================================================

SELECT '=== CRÉATION DE LA VUE BRAND_WITH_CATEGORIES ===' as section;

-- 1. S'ASSURER QUE LES TABLES EXISTENT
-- ============================================================================
-- Créer device_brands si elle n'existe pas
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
    PRIMARY KEY (id, user_id)
);

-- Créer device_categories si elle n'existe pas
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

-- Créer brand_categories si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.brand_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand_id TEXT NOT NULL,
    category_id UUID NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(brand_id, category_id)
);

SELECT '✅ Tables vérifiées/créées' as status;

-- 2. SUPPRIMER LA VUE EXISTANTE SI ELLE EXISTE
-- ============================================================================
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- 3. CRÉER LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
CREATE VIEW public.brand_with_categories AS
SELECT 
    b.id,
    b.name,
    b.description,
    b.logo,
    b.is_active,
    b.user_id,
    b.created_at,
    b.updated_at,
    COALESCE(
        json_agg(
            json_build_object(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description,
                'icon', dc.icon,
                'is_active', dc.is_active,
                'created_at', dc.created_at,
                'updated_at', dc.updated_at
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands b
LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id AND bc.user_id = b.user_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id AND dc.user_id = b.user_id
GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.user_id, b.created_at, b.updated_at;

SELECT '✅ Vue brand_with_categories créée' as status;

-- 4. ACCORDER LES PERMISSIONS
-- ============================================================================
GRANT SELECT ON public.brand_with_categories TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- 5. VÉRIFICATION
-- ============================================================================
SELECT '=== VÉRIFICATION ===' as section;

-- Vérifier que la vue existe
SELECT 
    schemaname, 
    viewname
FROM pg_views 
WHERE viewname = 'brand_with_categories' 
AND schemaname = 'public';

-- Tester la vue
SELECT COUNT(*) as nombre_de_marques FROM public.brand_with_categories;

SELECT '=== VUE BRAND_WITH_CATEGORIES CRÉÉE AVEC SUCCÈS ===' as section;

