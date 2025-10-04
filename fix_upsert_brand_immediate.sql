-- ============================================================================
-- CORRECTION IMMÉDIATE DE L'AMBIGUÏTÉ UPSERT_BRAND
-- ============================================================================

SELECT '=== CORRECTION IMMÉDIATE UPSERT_BRAND ===' as section;

-- 1. SUPPRIMER LA FONCTION PROBLÉMATIQUE
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT);

-- 2. CRÉER UNE FONCTION UPSERT_BRAND SIMPLE ET SANS AMBIGUÏTÉ
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
        INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
        SELECT v_brand_id, unnest(p_category_ids), v_user_id, v_user_id;
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

-- 3. CRÉER UNE FONCTION UPSERT_BRAND_SIMPLE POUR LE FALLBACK
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
        INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
        SELECT v_brand_id, unnest(p_category_ids), v_user_id, v_user_id;
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

-- 4. CRÉER UNE FONCTION CREATE_BRAND_BASIC POUR LE DERNIER FALLBACK
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

-- 5. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand_simple(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_brand_basic(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 6. VÉRIFIER QUE LES FONCTIONS EXISTENT
SELECT '=== VÉRIFICATION DES FONCTIONS ===' as section;

SELECT 
    routine_name, 
    routine_type, 
    data_type 
FROM information_schema.routines 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic')
AND routine_schema = 'public'
ORDER BY routine_name;

SELECT '✅ Correction immédiate terminée avec succès' as status;
