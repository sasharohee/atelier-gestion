-- ============================================================================
-- SCRIPT DE CORRECTION FINALE - TOUTES LES ERREURS DE MARQUES
-- ============================================================================
-- Ce script résout définitivement toutes les erreurs de marques
-- Inclut la correction des types UUID/TEXT
-- ============================================================================

SELECT '=== CORRECTION FINALE DE TOUTES LES ERREURS DE MARQUES ===' as section;

-- 1. CRÉER LES TABLES AVEC LES BONS TYPES
-- ============================================================================
SELECT '=== CRÉATION DES TABLES AVEC LES BONS TYPES ===' as section;

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

-- Créer device_brands avec id de type TEXT
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

-- Créer brand_categories avec brand_id de type TEXT
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

SELECT '✅ Tables créées avec les bons types' as status;

-- 2. CORRIGER LES TYPES SI LES TABLES EXISTAIENT DÉJÀ
-- ============================================================================
SELECT '=== CORRECTION DES TYPES EXISTANTS ===' as section;

-- Corriger device_brands.id si nécessaire
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
    END IF;
END $$;

-- Corriger brand_categories.brand_id si nécessaire
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
    END IF;
END $$;

SELECT '✅ Types corrigés' as status;

-- 3. CRÉER LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== CRÉATION DE LA VUE ===' as section;

-- Supprimer la vue si elle existe
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Créer la vue avec les types corrects
CREATE VIEW public.brand_with_categories AS
SELECT 
    b.id as id,
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

-- 4. CRÉER LA FONCTION UPSERT_BRAND AVEC LES BONS TYPES
-- ============================================================================
SELECT '=== CRÉATION DE LA FONCTION UPSERT_BRAND ===' as section;

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- Créer la fonction avec les types corrects
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
    
    -- Insérer ou mettre à jour la marque
    INSERT INTO public.device_brands (
        id, name, description, logo, is_active, user_id, created_by, updated_at
    ) VALUES (
        p_id, p_name, p_description, p_logo, true, v_user_id, v_user_id, NOW()
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
            VALUES (v_brand_id, v_category_id::UUID, v_user_id, v_user_id)
            ON CONFLICT (brand_id, category_id) DO NOTHING;
        END LOOP;
    END IF;
    
    -- Retourner la marque avec ses catégories
    RETURN QUERY
    SELECT 
        b.id,
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

SELECT '✅ Fonction upsert_brand créée avec les bons types' as status;

-- 5. CONFIGURER RLS ET PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION RLS ET PERMISSIONS ===' as section;

-- Activer RLS
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS
DROP POLICY IF EXISTS "Users can manage their own brands" ON public.device_brands;
CREATE POLICY "Users can manage their own brands" ON public.device_brands
    FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can manage their own brand categories" ON public.brand_categories
    FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own device categories" ON public.device_categories;
CREATE POLICY "Users can manage their own device categories" ON public.device_categories
    FOR ALL USING (user_id = auth.uid());

-- Accorder les permissions
GRANT SELECT ON public.brand_with_categories TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand TO authenticated;

SELECT '✅ RLS et permissions configurés' as status;

-- 6. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les types
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories')
AND column_name IN ('id', 'brand_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- Vérifier la fonction
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'upsert_brand' AND routine_schema = 'public')
         THEN '✅ Fonction upsert_brand'
         ELSE '❌ Fonction upsert_brand MANQUANTE'
    END as fonction_status;

-- Vérifier la vue
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'brand_with_categories' AND table_schema = 'public')
         THEN '✅ Vue brand_with_categories'
         ELSE '❌ Vue brand_with_categories MANQUANTE'
    END as vue_status;

-- Tester la vue
SELECT COUNT(*) as nombre_de_marques FROM public.brand_with_categories;

SELECT '=== CORRECTION FINALE TERMINÉE AVEC SUCCÈS ===' as section;

