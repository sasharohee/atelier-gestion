-- ============================================================================
-- SCRIPT DE CORRECTION DES TYPES DANS LA FONCTION UPSERT_BRAND
-- ============================================================================
-- Ce script corrige l'erreur: column "id" is of type uuid but expression is of type text
-- ============================================================================

SELECT '=== CORRECTION DES TYPES DANS UPSERT_BRAND ===' as section;

-- 1. VÉRIFIER LES TYPES ACTUELS DES TABLES
-- ============================================================================
SELECT '=== VÉRIFICATION DES TYPES ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories', 'device_categories')
AND column_name IN ('id', 'brand_id', 'category_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- 2. CORRIGER LE TYPE DE DEVICE_BRANDS.ID SI NÉCESSAIRE
-- ============================================================================
SELECT '=== CORRECTION DU TYPE ID DANS DEVICE_BRANDS ===' as section;

-- Si device_brands.id est de type UUID, le changer en TEXT
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'id' 
        AND data_type = 'uuid'
        AND table_schema = 'public'
    ) THEN
        -- Supprimer les contraintes de clé primaire d'abord
        ALTER TABLE public.device_brands DROP CONSTRAINT IF EXISTS device_brands_pkey;
        
        -- Changer le type
        ALTER TABLE public.device_brands ALTER COLUMN id TYPE TEXT;
        
        -- Recréer la contrainte de clé primaire composite
        ALTER TABLE public.device_brands ADD CONSTRAINT device_brands_pkey PRIMARY KEY (id, user_id);
        
        RAISE NOTICE '✅ Type de device_brands.id corrigé de UUID vers TEXT';
    ELSE
        RAISE NOTICE '✅ Type de device_brands.id déjà correct (TEXT)';
    END IF;
END $$;

-- 3. CORRIGER LE TYPE DE BRAND_CATEGORIES.BRAND_ID SI NÉCESSAIRE
-- ============================================================================
SELECT '=== CORRECTION DU TYPE BRAND_ID DANS BRAND_CATEGORIES ===' as section;

-- Si brand_categories.brand_id est de type UUID, le changer en TEXT
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'brand_categories' 
        AND column_name = 'brand_id' 
        AND data_type = 'uuid'
        AND table_schema = 'public'
    ) THEN
        -- Supprimer les contraintes d'unicité d'abord
        ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_brand_id_category_id_key;
        
        -- Changer le type
        ALTER TABLE public.brand_categories ALTER COLUMN brand_id TYPE TEXT;
        
        -- Recréer la contrainte d'unicité
        ALTER TABLE public.brand_categories ADD CONSTRAINT brand_categories_brand_id_category_id_key UNIQUE (brand_id, category_id);
        
        RAISE NOTICE '✅ Type de brand_categories.brand_id corrigé de UUID vers TEXT';
    ELSE
        RAISE NOTICE '✅ Type de brand_categories.brand_id déjà correct (TEXT)';
    END IF;
END $$;

-- 4. RECRÉER LA FONCTION UPSERT_BRAND AVEC LES BONS TYPES
-- ============================================================================
SELECT '=== RECRÉATION DE LA FONCTION UPSERT_BRAND ===' as section;

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- Créer la nouvelle fonction avec les types corrects
CREATE OR REPLACE FUNCTION public.upsert_brand(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_ids TEXT[] DEFAULT NULL
)
RETURNS TABLE(
    id TEXT,
    name TEXT,
    description TEXT,
    logo TEXT,
    is_active BOOLEAN,
    categories JSON,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_brand_id TEXT;
    v_category_id TEXT;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    -- Insérer ou mettre à jour la marque (avec conversion explicite du type si nécessaire)
    INSERT INTO public.device_brands (
        id, name, description, logo, is_active, user_id, created_by, updated_at
    ) VALUES (
        p_id::TEXT, p_name, p_description, p_logo, true, v_user_id, v_user_id, NOW()
    )
    ON CONFLICT (id, user_id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_at = NOW();
    
    v_brand_id := p_id;
    
    -- Supprimer les associations existantes si des catégories sont fournies
    IF p_category_ids IS NOT NULL THEN
        DELETE FROM public.brand_categories 
        WHERE brand_id = v_brand_id AND user_id = v_user_id;
        
        -- Ajouter les nouvelles associations
        FOREACH v_category_id IN ARRAY p_category_ids
        LOOP
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            VALUES (v_brand_id::TEXT, v_category_id::UUID, v_user_id, v_user_id)
            ON CONFLICT (brand_id, category_id) DO NOTHING;
        END LOOP;
    END IF;
    
    -- Retourner la marque avec ses catégories
    RETURN QUERY
    SELECT 
        b.id::TEXT,
        b.name,
        b.description,
        b.logo,
        b.is_active,
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
        ) as categories,
        b.created_at,
        b.updated_at
    FROM public.device_brands b
    LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id AND bc.user_id = v_user_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id AND dc.user_id = v_user_id
    WHERE b.id = v_brand_id AND b.user_id = v_user_id
    GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.created_at, b.updated_at;
END;
$$;

SELECT '✅ Fonction upsert_brand recréée avec les bons types' as status;

-- 5. RECRÉER LA VUE AVEC LES BONS TYPES
-- ============================================================================
SELECT '=== RECRÉATION DE LA VUE ===' as section;

-- Supprimer la vue existante
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Recréer la vue avec les types corrects
CREATE VIEW public.brand_with_categories AS
SELECT 
    b.id::TEXT as id,
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

SELECT '✅ Vue brand_with_categories recréée avec les bons types' as status;

-- 6. ACCORDER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.upsert_brand TO authenticated;
GRANT SELECT ON public.brand_with_categories TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- 7. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les types après correction
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories')
AND column_name IN ('id', 'brand_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- Vérifier que la fonction existe
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'upsert_brand' AND routine_schema = 'public')
         THEN '✅ Fonction upsert_brand existe'
         ELSE '❌ Fonction upsert_brand manquante'
    END as fonction_status;

-- Vérifier que la vue existe
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'brand_with_categories' AND table_schema = 'public')
         THEN '✅ Vue brand_with_categories existe'
         ELSE '❌ Vue brand_with_categories manquante'
    END as vue_status;

-- Tester la vue
SELECT COUNT(*) as nombre_de_marques FROM public.brand_with_categories;

SELECT '=== CORRECTION DES TYPES TERMINÉE AVEC SUCCÈS ===' as section;

