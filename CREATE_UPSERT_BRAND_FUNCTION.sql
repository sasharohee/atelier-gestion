-- ============================================================================
-- SCRIPT RAPIDE - CRÉATION DE LA FONCTION UPSERT_BRAND
-- ============================================================================
-- Ce script crée uniquement la fonction upsert_brand manquante
-- ============================================================================

SELECT '=== CRÉATION DE LA FONCTION UPSERT_BRAND ===' as section;

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

-- 2. SUPPRIMER LA FONCTION EXISTANTE SI ELLE EXISTE
-- ============================================================================
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- 3. CRÉER LA FONCTION UPSERT_BRAND
-- ============================================================================
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
        WHERE brand_id = v_brand_id AND user_id = v_user_id;
        
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
    LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id AND bc.user_id = v_user_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id AND dc.user_id = v_user_id
    WHERE b.id = v_brand_id AND b.user_id = v_user_id
    GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.created_at, b.updated_at;
    
    RETURN NEXT;
END;
$$;

SELECT '✅ Fonction upsert_brand créée' as status;

-- 4. ACCORDER LES PERMISSIONS
-- ============================================================================
GRANT EXECUTE ON FUNCTION public.upsert_brand TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- 5. VÉRIFICATION
-- ============================================================================
SELECT '=== VÉRIFICATION ===' as section;

-- Vérifier que la fonction existe
SELECT 
    routine_name, 
    routine_type, 
    data_type 
FROM information_schema.routines 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';

SELECT '=== FONCTION UPSERT_BRAND CRÉÉE AVEC SUCCÈS ===' as section;

