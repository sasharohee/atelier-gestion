-- ============================================================================
-- SCRIPT DE CORRECTION DU TYPE ID DANS DEVICE_BRANDS
-- ============================================================================
-- Ce script corrige définitivement le conflit de type UUID vs TEXT
-- ============================================================================

SELECT '=== CORRECTION DU TYPE ID DANS DEVICE_BRANDS ===' as section;

-- 1. VÉRIFIER LE TYPE ACTUEL DE LA COLONNE ID
-- ============================================================================
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND column_name = 'id'
AND table_schema = 'public';

-- 2. SAUVEGARDER LES DONNÉES EXISTANTES
-- ============================================================================
SELECT '=== SAUVEGARDE DES DONNÉES ===' as section;

-- Créer une table de sauvegarde
CREATE TABLE IF NOT EXISTS device_brands_backup_type_fix AS 
SELECT * FROM device_brands WHERE false;

-- Vider la table de sauvegarde
DELETE FROM device_brands_backup_type_fix;

-- Copier les données existantes
INSERT INTO device_brands_backup_type_fix 
SELECT * FROM device_brands;

SELECT COUNT(*) as backup_count FROM device_brands_backup_type_fix;

-- 3. CORRIGER LE TYPE DE LA COLONNE ID
-- ============================================================================
SELECT '=== CORRECTION DU TYPE ID ===' as section;

-- Supprimer les contraintes de clé primaire d'abord
ALTER TABLE public.device_brands DROP CONSTRAINT IF EXISTS device_brands_pkey;

-- Changer le type de UUID vers TEXT
ALTER TABLE public.device_brands ALTER COLUMN id TYPE TEXT;

-- Recréer la contrainte de clé primaire composite
ALTER TABLE public.device_brands ADD CONSTRAINT device_brands_pkey PRIMARY KEY (id, user_id);

SELECT '✅ Type de device_brands.id corrigé de UUID vers TEXT' as status;

-- 4. CORRIGER LE TYPE DE BRAND_CATEGORIES.BRAND_ID SI NÉCESSAIRE
-- ============================================================================
SELECT '=== CORRECTION DU TYPE BRAND_ID ===' as section;

-- Vérifier le type actuel
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND column_name = 'brand_id'
AND table_schema = 'public';

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

-- 5. RECRÉER LES FONCTIONS RPC AVEC LES BONS TYPES
-- ============================================================================
SELECT '=== RECRÉATION DES FONCTIONS RPC ===' as section;

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT, TEXT[]);

-- Créer la fonction update_brand_categories
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids TEXT[]
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_category_id TEXT;
BEGIN
    -- Vérifier l'authentification
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Non authentifié');
    END IF;

    -- Supprimer les associations existantes pour cette marque
    DELETE FROM public.brand_categories 
    WHERE brand_id = p_brand_id AND user_id = v_user_id;

    -- Ajouter les nouvelles associations
    IF p_category_ids IS NOT NULL AND array_length(p_category_ids, 1) > 0 THEN
        FOREACH v_category_id IN ARRAY p_category_ids
        LOOP
            INSERT INTO public.brand_categories (brand_id, category_id, user_id, created_by)
            VALUES (p_brand_id, v_category_id::UUID, v_user_id, v_user_id)
            ON CONFLICT (brand_id, category_id) DO NOTHING;
        END LOOP;
    END IF;

    RETURN json_build_object('success', true, 'message', 'Catégories mises à jour');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Créer la fonction upsert_brand_simple
CREATE OR REPLACE FUNCTION public.upsert_brand_simple(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT ''
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Vérifier l'authentification
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Non authentifié');
    END IF;

    -- Vérifier que le nom n'est pas vide
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Le nom de la marque est requis');
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

    -- Retourner la marque créée/mise à jour
    SELECT json_build_object(
        'success', true,
        'id', p_id,
        'name', p_name,
        'description', p_description,
        'logo', p_logo,
        'is_active', true,
        'user_id', v_user_id,
        'created_at', NOW(),
        'updated_at', NOW()
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer la fonction create_brand_basic
CREATE OR REPLACE FUNCTION public.create_brand_basic(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT ''
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Vérifier l'authentification
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Non authentifié');
    END IF;

    -- Vérifier que le nom n'est pas vide
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Le nom de la marque est requis');
    END IF;

    -- Insérer la marque
    INSERT INTO public.device_brands (
        id, name, description, logo, is_active, user_id, created_by, updated_at
    ) VALUES (
        p_id, p_name, p_description, p_logo, true, v_user_id, v_user_id, NOW()
    );

    -- Retourner la marque créée
    SELECT json_build_object(
        'success', true,
        'id', p_id,
        'name', p_name,
        'description', p_description,
        'logo', p_logo,
        'is_active', true,
        'user_id', v_user_id,
        'created_at', NOW(),
        'updated_at', NOW()
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. ACCORDER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.update_brand_categories(TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand_simple(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_brand_basic(TEXT, TEXT, TEXT, TEXT) TO authenticated;

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

-- Vérifier que les fonctions existent
SELECT 
    routine_name, 
    routine_type, 
    data_type 
FROM information_schema.routines 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic', 'update_brand_categories')
AND routine_schema = 'public'
ORDER BY routine_name;

-- Vérifier que les données sont toujours là
SELECT COUNT(*) as nombre_de_marques FROM public.device_brands;

SELECT '✅ Correction du type ID terminée avec succès' as status;

SELECT '=== CORRECTION TERMINÉE ===' as section;


