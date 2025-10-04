-- ============================================================================
-- SCRIPT DE CORRECTION DU TYPE ID DANS DEVICE_BRANDS AVEC GESTION DES VUES
-- ============================================================================
-- Ce script corrige définitivement le conflit de type UUID vs TEXT
-- en gérant les vues et contraintes de clé étrangère
-- ============================================================================

SELECT '=== CORRECTION DU TYPE ID DANS DEVICE_BRANDS AVEC VUES ===' as section;

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

-- 2. IDENTIFIER LES VUES QUI DÉPENDENT DE DEVICE_BRANDS
-- ============================================================================
SELECT '=== IDENTIFICATION DES VUES DÉPENDANTES ===' as section;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name LIKE '%brand%'
ORDER BY table_name;

-- 3. IDENTIFIER LES CONTRAINTES QUI DÉPENDENT DE LA CLÉ PRIMAIRE
-- ============================================================================
SELECT '=== IDENTIFICATION DES CONTRAINTES DÉPENDANTES ===' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND ccu.table_name = 'device_brands'
AND ccu.column_name = 'id'
AND tc.table_schema = 'public';

-- 4. SAUVEGARDER LES DONNÉES ET DÉFINITIONS EXISTANTES
-- ============================================================================
SELECT '=== SAUVEGARDE DES DONNÉES ET DÉFINITIONS ===' as section;

-- Créer des tables de sauvegarde
CREATE TABLE IF NOT EXISTS device_brands_backup_type_fix AS 
SELECT * FROM device_brands WHERE false;

CREATE TABLE IF NOT EXISTS device_models_backup_type_fix AS 
SELECT * FROM device_models WHERE false;

CREATE TABLE IF NOT EXISTS brand_categories_backup_type_fix AS 
SELECT * FROM brand_categories WHERE false;

-- Vider les tables de sauvegarde
DELETE FROM device_brands_backup_type_fix;
DELETE FROM device_models_backup_type_fix;
DELETE FROM brand_categories_backup_type_fix;

-- Copier les données existantes
INSERT INTO device_brands_backup_type_fix 
SELECT * FROM device_brands;

INSERT INTO device_models_backup_type_fix 
SELECT * FROM device_models;

INSERT INTO brand_categories_backup_type_fix 
SELECT * FROM brand_categories;

SELECT 
    (SELECT COUNT(*) FROM device_brands_backup_type_fix) as device_brands_backup_count,
    (SELECT COUNT(*) FROM device_models_backup_type_fix) as device_models_backup_count,
    (SELECT COUNT(*) FROM brand_categories_backup_type_fix) as brand_categories_backup_count;

-- 5. SAUVEGARDER LA DÉFINITION DE LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== SAUVEGARDE DE LA VUE BRAND_WITH_CATEGORIES ===' as section;

-- Créer une table temporaire pour stocker la définition de la vue
CREATE TEMP TABLE IF NOT EXISTS view_definition_backup (
    view_name TEXT,
    view_definition TEXT
);

-- Supprimer l'ancienne définition si elle existe
DELETE FROM view_definition_backup WHERE view_name = 'brand_with_categories';

-- Insérer la définition actuelle de la vue
INSERT INTO view_definition_backup (view_name, view_definition)
SELECT 
    'brand_with_categories',
    pg_get_viewdef('public.brand_with_categories'::regclass, true);

SELECT '✅ Définition de la vue brand_with_categories sauvegardée' as status;

-- 6. SUPPRIMER TEMPORAIREMENT LES VUES ET CONTRAINTES
-- ============================================================================
SELECT '=== SUPPRESSION TEMPORAIRE DES VUES ET CONTRAINTES ===' as section;

-- Supprimer la vue brand_with_categories
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Supprimer les contraintes de clé étrangère qui dépendent de device_brands.id
ALTER TABLE public.device_models DROP CONSTRAINT IF EXISTS device_models_brand_id_fkey;
ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_brand_id_fkey;

SELECT '✅ Vues et contraintes supprimées temporairement' as status;

-- 7. CORRIGER LE TYPE DE LA COLONNE ID
-- ============================================================================
SELECT '=== CORRECTION DU TYPE ID ===' as section;

-- Supprimer la contrainte de clé primaire
ALTER TABLE public.device_brands DROP CONSTRAINT IF EXISTS device_brands_pkey;

-- Changer le type de UUID vers TEXT
ALTER TABLE public.device_brands ALTER COLUMN id TYPE TEXT;

-- Recréer la contrainte de clé primaire composite
ALTER TABLE public.device_brands ADD CONSTRAINT device_brands_pkey PRIMARY KEY (id, user_id);

SELECT '✅ Type de device_brands.id corrigé de UUID vers TEXT' as status;

-- 8. CORRIGER LE TYPE DE BRAND_CATEGORIES.BRAND_ID
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

-- 9. RECRÉER LES CONTRAINTES DE CLÉ ÉTRANGÈRE
-- ============================================================================
SELECT '=== RECRÉATION DES CONTRAINTES DE CLÉ ÉTRANGÈRE ===' as section;

-- Recréer la contrainte pour device_models.brand_id
ALTER TABLE public.device_models 
ADD CONSTRAINT device_models_brand_id_fkey 
FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE;

-- Recréer la contrainte pour brand_categories.brand_id
ALTER TABLE public.brand_categories 
ADD CONSTRAINT brand_categories_brand_id_fkey 
FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE;

SELECT '✅ Contraintes de clé étrangère recréées' as status;

-- 10. RECRÉER LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== RECRÉATION DE LA VUE BRAND_WITH_CATEGORIES ===' as section;

-- Recréer la vue avec les bons types
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

-- 11. RECRÉER LES FONCTIONS RPC AVEC LES BONS TYPES
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

-- 12. ACCORDER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.update_brand_categories(TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand_simple(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_brand_basic(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Accorder les permissions sur la vue
GRANT SELECT ON public.brand_with_categories TO authenticated;

-- 13. VÉRIFICATION FINALE
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

-- Vérifier que la vue existe
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'brand_with_categories'
AND table_schema = 'public';

-- Vérifier que les contraintes de clé étrangère sont recréées
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND ccu.table_name = 'device_brands'
AND ccu.column_name = 'id'
AND tc.table_schema = 'public';

-- Vérifier que les données sont toujours là
SELECT 
    (SELECT COUNT(*) FROM public.device_brands) as nombre_de_marques,
    (SELECT COUNT(*) FROM public.device_models) as nombre_de_modeles,
    (SELECT COUNT(*) FROM public.brand_categories) as nombre_d_associations,
    (SELECT COUNT(*) FROM public.brand_with_categories) as nombre_de_marques_dans_la_vue;

SELECT '✅ Correction du type ID avec gestion des vues et contraintes terminée avec succès' as status;

SELECT '=== CORRECTION TERMINÉE ===' as section;


