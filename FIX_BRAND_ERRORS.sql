-- ============================================================================
-- SCRIPT DE CORRECTION DES ERREURS DE MARQUES
-- ============================================================================
-- Ce script résout les erreurs suivantes :
-- 1. Vue 'brand_with_categories' manquante (404 Not Found)
-- 2. Fonction 'upsert_brand' manquante (404 Not Found)
-- ============================================================================

-- 1. CRÉER LA TABLE BRAND_CATEGORIES (si elle n'existe pas)
-- ============================================================================
SELECT '=== CRÉATION DE LA TABLE BRAND_CATEGORIES ===' as section;

-- Créer la table brand_categories si elle n'existe pas
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

-- Créer la table device_categories si elle n'existe pas
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

-- Créer la table device_brands si elle n'existe pas
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

-- 2. CRÉER LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== CRÉATION DE LA VUE BRAND_WITH_CATEGORIES ===' as section;

-- Supprimer la vue si elle existe déjà
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Créer la vue brand_with_categories
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

-- 3. CRÉER LA FONCTION UPSERT_BRAND
-- ============================================================================
SELECT '=== CRÉATION DE LA FONCTION UPSERT_BRAND ===' as section;

-- Supprimer la fonction si elle existe déjà
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- Créer la fonction upsert_brand
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
    v_categories JSON;
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
        WHERE brand_id = v_brand_id;
        
        -- Ajouter les nouvelles associations
        FOREACH v_category_id IN ARRAY p_category_ids
        LOOP
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            VALUES (v_brand_id, v_category_id::UUID, v_user_id, v_user_id)
            ON CONFLICT (brand_id, category_id) DO NOTHING;
        END LOOP;
    END IF;
    
    -- Récupérer la marque avec ses catégories pour le retour
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
    INTO 
        id, name, description, logo, is_active, categories, created_at, updated_at
    FROM public.device_brands b
    LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
    WHERE b.id = v_brand_id AND b.user_id = v_user_id
    GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.created_at, b.updated_at;
    
    RETURN NEXT;
END;
$$;

-- 4. CRÉER LA FONCTION UPDATE_BRAND_CATEGORIES
-- ============================================================================
SELECT '=== CRÉATION DE LA FONCTION UPDATE_BRAND_CATEGORIES ===' as section;

-- Supprimer la fonction si elle existe déjà
DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT, TEXT[]);

-- Créer la fonction update_brand_categories
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids TEXT[]
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
    v_category_id TEXT;
    v_categories JSON;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    -- Vérifier que la marque existe et appartient à l'utilisateur
    IF NOT EXISTS (SELECT 1 FROM public.device_brands WHERE id = p_brand_id AND user_id = v_user_id) THEN
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;
    
    -- Supprimer les associations existantes
    DELETE FROM public.brand_categories 
    WHERE brand_id = p_brand_id;
    
    -- Ajouter les nouvelles associations
    IF p_category_ids IS NOT NULL THEN
        FOREACH v_category_id IN ARRAY p_category_ids
        LOOP
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            VALUES (p_brand_id, v_category_id::UUID, v_user_id, v_user_id)
            ON CONFLICT (brand_id, category_id) DO NOTHING;
        END LOOP;
    END IF;
    
    -- Retourner la marque mise à jour avec ses catégories
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
    INTO 
        id, name, description, logo, is_active, categories, created_at, updated_at
    FROM public.device_brands b
    LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
    WHERE b.id = p_brand_id AND b.user_id = v_user_id
    GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.created_at, b.updated_at;
    
    RETURN NEXT;
END;
$$;

-- 5. CONFIGURER LES POLITIQUES RLS (Row Level Security)
-- ============================================================================
SELECT '=== CONFIGURATION DES POLITIQUES RLS ===' as section;

-- Activer RLS sur les tables si ce n'est pas déjà fait
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;

-- Politique pour device_brands
DROP POLICY IF EXISTS "Users can manage their own brands" ON public.device_brands;
CREATE POLICY "Users can manage their own brands" ON public.device_brands
    FOR ALL USING (user_id = auth.uid());

-- Politique pour brand_categories
DROP POLICY IF EXISTS "Users can manage their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can manage their own brand categories" ON public.brand_categories
    FOR ALL USING (user_id = auth.uid());

-- 6. ACCORDER LES PERMISSIONS NÉCESSAIRES
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

-- Permissions pour la vue
GRANT SELECT ON public.brand_with_categories TO authenticated;

-- Permissions pour les fonctions
GRANT EXECUTE ON FUNCTION public.upsert_brand TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_brand_categories TO authenticated;

-- 7. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que la vue existe
SELECT 
    schemaname, 
    viewname, 
    definition 
FROM pg_views 
WHERE viewname = 'brand_with_categories' 
AND schemaname = 'public';

-- Vérifier que les fonctions existent
SELECT 
    routine_name, 
    routine_type, 
    data_type 
FROM information_schema.routines 
WHERE routine_name IN ('upsert_brand', 'update_brand_categories')
AND routine_schema = 'public';

SELECT '=== SCRIPT TERMINÉ AVEC SUCCÈS ===' as section;
