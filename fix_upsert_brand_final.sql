-- ============================================================================
-- CORRECTION FINALE UPSERT_BRAND - ADAPTÉE À LA STRUCTURE ACTUELLE
-- ============================================================================

SELECT '=== CORRECTION FINALE UPSERT_BRAND ===' as section;

-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE BRAND_CATEGORIES
-- ============================================================================
SELECT '=== VÉRIFICATION STRUCTURE BRAND_CATEGORIES ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. SUPPRIMER TOUTES LES FONCTIONS PROBLÉMATIQUES
-- ============================================================================
SELECT '=== SUPPRESSION DES FONCTIONS PROBLÉMATIQUES ===' as section;

DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.upsert_brand_simple(TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.create_brand_basic(TEXT, TEXT, TEXT, TEXT);

-- 3. CRÉER UNE FONCTION UPSERT_BRAND SIMPLE ET ROBUSTE
-- ============================================================================
SELECT '=== CRÉATION FONCTION UPSERT_BRAND ROBUSTE ===' as section;

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
    
    -- Vérifier que le nom n'est pas vide
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RAISE EXCEPTION 'Le nom de la marque est requis';
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
    
    -- Mettre à jour les catégories si fournies
    IF p_category_ids IS NOT NULL THEN
        -- Supprimer les anciennes associations
        DELETE FROM public.brand_categories 
        WHERE brand_id = v_brand_id AND user_id = v_user_id;
        
        -- Ajouter les nouvelles associations
        -- Vérifier si la colonne created_by existe
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'brand_categories' 
            AND column_name = 'created_by' 
            AND table_schema = 'public'
        ) THEN
            -- Structure avec created_by
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            SELECT v_brand_id, unnest(p_category_ids), v_user_id, v_user_id;
        ELSE
            -- Structure sans created_by
            INSERT INTO public.brand_categories (brand_id, category_id, user_id)
            SELECT v_brand_id, unnest(p_category_ids), v_user_id;
        END IF;
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
                    'id', c.id,
                    'name', c.name,
                    'description', c.description,
                    'icon', c.icon,
                    'is_active', c.is_active,
                    'created_at', c.created_at,
                    'updated_at', c.updated_at
                )
            ) FILTER (WHERE c.id IS NOT NULL),
            '[]'::json
        ) as categories,
        b.created_at,
        b.updated_at
    FROM public.device_brands b
    LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id AND bc.user_id = v_user_id
    LEFT JOIN public.device_categories c ON bc.category_id = c.id AND c.user_id = v_user_id
    WHERE b.id = v_brand_id AND b.user_id = v_user_id
    GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.created_at, b.updated_at;
END;
$$;

-- 4. CRÉER UNE FONCTION UPSERT_BRAND_SIMPLE POUR LE FALLBACK
-- ============================================================================
SELECT '=== CRÉATION FONCTION UPSERT_BRAND_SIMPLE ===' as section;

CREATE OR REPLACE FUNCTION public.upsert_brand_simple(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_ids TEXT[] DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_brand_id TEXT;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    -- Vérifier que le nom n'est pas vide
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RAISE EXCEPTION 'Le nom de la marque est requis';
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
    
    -- Mettre à jour les catégories si fournies
    IF p_category_ids IS NOT NULL THEN
        -- Supprimer les anciennes associations
        DELETE FROM public.brand_categories 
        WHERE brand_id = v_brand_id AND user_id = v_user_id;
        
        -- Ajouter les nouvelles associations
        -- Vérifier si la colonne created_by existe
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'brand_categories' 
            AND column_name = 'created_by' 
            AND table_schema = 'public'
        ) THEN
            -- Structure avec created_by
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            SELECT v_brand_id, unnest(p_category_ids), v_user_id, v_user_id;
        ELSE
            -- Structure sans created_by
            INSERT INTO public.brand_categories (brand_id, category_id, user_id)
            SELECT v_brand_id, unnest(p_category_ids), v_user_id;
        END IF;
    END IF;
    
    -- Retourner la marque en JSON
    SELECT json_build_object(
        'id', b.id,
        'name', b.name,
        'description', b.description,
        'logo', b.logo,
        'is_active', b.is_active,
        'created_at', b.created_at,
        'updated_at', b.updated_at
    ) INTO v_result
    FROM public.device_brands b
    WHERE b.id = v_brand_id AND b.user_id = v_user_id;
    
    RETURN v_result;
END;
$$;

-- 5. CRÉER UNE FONCTION CREATE_BRAND_BASIC POUR LE DERNIER FALLBACK
-- ============================================================================
SELECT '=== CRÉATION FONCTION CREATE_BRAND_BASIC ===' as section;

CREATE OR REPLACE FUNCTION public.create_brand_basic(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT ''
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    -- Vérifier que le nom n'est pas vide
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RAISE EXCEPTION 'Le nom de la marque est requis';
    END IF;
    
    -- Insérer la marque
    INSERT INTO public.device_brands (
        id, name, description, logo, is_active, user_id, created_by, updated_at
    ) VALUES (
        p_id, p_name, p_description, p_logo, true, v_user_id, v_user_id, NOW()
    );
    
    -- Retourner la marque en JSON
    SELECT json_build_object(
        'id', b.id,
        'name', b.name,
        'description', b.description,
        'logo', b.logo,
        'is_active', b.is_active,
        'created_at', b.created_at,
        'updated_at', b.updated_at
    ) INTO v_result
    FROM public.device_brands b
    WHERE b.id = p_id AND b.user_id = v_user_id;
    
    RETURN v_result;
END;
$$;

-- 6. ACCORDER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand_simple(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_brand_basic(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 7. VÉRIFIER QUE LES FONCTIONS EXISTENT
-- ============================================================================
SELECT '=== VÉRIFICATION DES FONCTIONS ===' as section;

SELECT 
    routine_name, 
    routine_type, 
    data_type 
FROM information_schema.routines 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic')
AND routine_schema = 'public'
ORDER BY routine_name;

-- 8. VÉRIFIER LES PERMISSIONS
-- ============================================================================
SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as section;

SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic')
AND routine_schema = 'public'
ORDER BY routine_name, grantee;

SELECT '✅ Correction finale terminée avec succès' as status;
