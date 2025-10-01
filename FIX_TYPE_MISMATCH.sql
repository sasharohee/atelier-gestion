-- ============================================================================
-- SCRIPT DE CORRECTION DU PROBLÈME DE TYPES
-- ============================================================================
-- Ce script corrige l'erreur : operator does not exist: uuid = text
-- ============================================================================

SELECT '=== CORRECTION DES TYPES DE COLONNES ===' as section;

-- 1. VÉRIFIER LES TYPES ACTUELS
-- ============================================================================
SELECT '=== VÉRIFICATION DES TYPES ACTUELS ===' as section;

-- Vérifier le type de device_brands.id
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND column_name = 'id'
AND table_schema = 'public';

-- Vérifier le type de brand_categories.brand_id
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND column_name = 'brand_id'
AND table_schema = 'public';

-- 2. CORRIGER LE TYPE DE BRAND_ID DANS BRAND_CATEGORIES
-- ============================================================================
SELECT '=== CORRECTION DU TYPE BRAND_ID ===' as section;

-- Changer le type de brand_id de UUID vers TEXT si nécessaire
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
    ELSE
        RAISE NOTICE '✅ Type de brand_id déjà correct (TEXT) dans brand_categories';
    END IF;
END $$;

-- 3. CORRIGER LE TYPE DE ID DANS DEVICE_BRANDS SI NÉCESSAIRE
-- ============================================================================
SELECT '=== VÉRIFICATION DU TYPE ID DANS DEVICE_BRANDS ===' as section;

-- Vérifier et corriger le type de device_brands.id si nécessaire
DO $$
BEGIN
    -- Vérifier si id est de type UUID et le changer en TEXT
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'id' 
        AND data_type = 'uuid'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.device_brands ALTER COLUMN id TYPE TEXT;
        RAISE NOTICE '✅ Type de id corrigé de UUID vers TEXT dans device_brands';
    ELSE
        RAISE NOTICE '✅ Type de id déjà correct (TEXT) dans device_brands';
    END IF;
END $$;

-- 4. VÉRIFIER LES TYPES APRÈS CORRECTION
-- ============================================================================
SELECT '=== VÉRIFICATION APRÈS CORRECTION ===' as section;

-- Vérifier le type de device_brands.id
SELECT 
    'device_brands.id' as column_info,
    data_type as current_type
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND column_name = 'id'
AND table_schema = 'public'

UNION ALL

-- Vérifier le type de brand_categories.brand_id
SELECT 
    'brand_categories.brand_id' as column_info,
    data_type as current_type
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND column_name = 'brand_id'
AND table_schema = 'public';

-- 5. TEST DE LA JOINTURE
-- ============================================================================
SELECT '=== TEST DE LA JOINTURE ===' as section;

-- Tester la jointure qui causait l'erreur
SELECT 
    COUNT(*) as nombre_de_jointures_reussies
FROM public.device_brands b
LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id;

SELECT '✅ Jointure testée avec succès' as test_result;

-- 6. RECRÉER LA VUE SI NÉCESSAIRE
-- ============================================================================
SELECT '=== RECRÉATION DE LA VUE ===' as section;

-- Supprimer la vue si elle existe
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Recréer la vue avec les types corrigés
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
LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.user_id, b.created_at, b.updated_at;

SELECT '✅ Vue brand_with_categories recréée avec succès' as status;

-- 7. TEST FINAL
-- ============================================================================
SELECT '=== TEST FINAL ===' as section;

-- Tester la vue
SELECT COUNT(*) as nombre_de_marques_avec_categories 
FROM public.brand_with_categories;

SELECT '=== CORRECTION TERMINÉE AVEC SUCCÈS ===' as section;

