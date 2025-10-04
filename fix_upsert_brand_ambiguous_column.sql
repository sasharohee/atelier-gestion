-- ============================================================================
-- SCRIPT DE CORRECTION DE L'AMBIGUÏTÉ DE COLONNE DANS UPSERT_BRAND
-- ============================================================================
-- Ce script corrige l'erreur "column reference 'id' is ambiguous"
-- ============================================================================

SELECT '=== CORRECTION DE L''AMBIGUÏTÉ DE COLONNE DANS UPSERT_BRAND ===' as section;

-- 1. SUPPRIMER LA FONCTION UPSERT_BRAND EXISTANTE
-- ============================================================================
SELECT '=== SUPPRESSION DE LA FONCTION EXISTANTE ===' as section;

DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- 2. CRÉER LA FONCTION UPSERT_BRAND CORRIGÉE
-- ============================================================================
SELECT '=== CRÉATION DE LA FONCTION UPSERT_BRAND CORRIGÉE ===' as section;

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
        PERFORM public.update_brand_categories(v_brand_id, p_category_ids);
    END IF;
    
    -- Retourner la marque avec ses catégories
    -- CORRECTION: Utiliser des alias explicites pour éviter l'ambiguïté
    RETURN QUERY
    SELECT 
        b.id as brand_id,
        b.name as brand_name,
        b.description as brand_description,
        b.logo as brand_logo,
        b.is_active as brand_is_active,
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
        b.created_at as brand_created_at,
        b.updated_at as brand_updated_at
    FROM public.device_brands b
    LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id AND bc.user_id = v_user_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id AND dc.user_id = v_user_id
    WHERE b.id = v_brand_id AND b.user_id = v_user_id
    GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.created_at, b.updated_at;
END;
$$;

SELECT '✅ Fonction upsert_brand corrigée pour éviter l''ambiguïté de colonne' as status;

-- 3. VÉRIFIER QUE LA FONCTION EXISTE
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA FONCTION ===' as section;

SELECT 
    routine_name, 
    routine_type, 
    data_type 
FROM information_schema.routines 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';

-- 4. ACCORDER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- 5. TEST DE LA FONCTION (si un utilisateur est connecté)
-- ============================================================================
SELECT '=== TEST DE LA FONCTION ===' as section;

-- Note: Ce test ne fonctionnera que si un utilisateur est authentifié
-- Décommentez les lignes suivantes pour tester :

-- Test avec des paramètres simples
-- SELECT 'Test avec paramètres simples...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_' || extract(epoch from now()), 'Test Brand', 'Description test', '', NULL);

-- Test avec des catégories (si des catégories existent)
-- SELECT 'Test avec catégories...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_cat_' || extract(epoch from now()), 'Test Brand avec Catégories', 'Description test', '', ARRAY['category_id_1', 'category_id_2']);

SELECT '✅ Correction de l''ambiguïté de colonne terminée avec succès' as status;

SELECT '=== CORRECTION TERMINÉE ===' as section;


