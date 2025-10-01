-- ============================================================================
-- SCRIPT DE CORRECTION DES DÉPENDANCES DE CONTRAINTES
-- ============================================================================
-- Ce script corrige les problèmes de dépendances avec device_models
-- ============================================================================

SELECT '=== CORRECTION DES DÉPENDANCES DE CONTRAINTES ===' as section;

-- 1. VÉRIFIER LES DÉPENDANCES EXISTANTES
-- ============================================================================
SELECT '=== VÉRIFICATION DES DÉPENDANCES ===' as section;

-- Vérifier les contraintes de clés étrangères sur device_models
SELECT 
    tc.constraint_name,
    tc.table_name,
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
    AND tc.table_name = 'device_models'
    AND tc.table_schema = 'public';

-- Vérifier les types actuels
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'device_models', 'brand_categories')
AND column_name IN ('id', 'brand_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- 2. GÉRER LES DÉPENDANCES AVEC DEVICE_MODELS
-- ============================================================================
SELECT '=== GESTION DES DÉPENDANCES AVEC DEVICE_MODELS ===' as section;

-- Vérifier si device_models existe et a une contrainte vers device_brands
DO $$
BEGIN
    -- Si device_models existe et a une contrainte brand_id vers device_brands
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'device_models' 
        AND kcu.column_name = 'brand_id'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
    ) THEN
        -- Supprimer la contrainte de clé étrangère avec CASCADE
        ALTER TABLE public.device_models DROP CONSTRAINT IF EXISTS device_models_brand_id_fkey CASCADE;
        RAISE NOTICE '✅ Contrainte device_models_brand_id_fkey supprimée';
    END IF;
END $$;

-- 3. CORRIGER LE TYPE DE DEVICE_BRANDS.ID
-- ============================================================================
SELECT '=== CORRECTION DU TYPE DEVICE_BRANDS.ID ===' as section;

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
        -- Supprimer les contraintes de clé primaire
        ALTER TABLE public.device_brands DROP CONSTRAINT IF EXISTS device_brands_pkey CASCADE;
        
        -- Changer le type
        ALTER TABLE public.device_brands ALTER COLUMN id TYPE TEXT;
        
        -- Recréer la contrainte de clé primaire composite
        ALTER TABLE public.device_brands ADD CONSTRAINT device_brands_pkey PRIMARY KEY (id, user_id);
        
        RAISE NOTICE '✅ Type de device_brands.id corrigé de UUID vers TEXT';
    ELSE
        RAISE NOTICE '✅ Type de device_brands.id déjà correct (TEXT)';
    END IF;
END $$;

-- 4. CORRIGER LE TYPE DE BRAND_CATEGORIES.BRAND_ID
-- ============================================================================
SELECT '=== CORRECTION DU TYPE BRAND_CATEGORIES.BRAND_ID ===' as section;

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
        -- Supprimer les contraintes d'unicité
        ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_brand_id_category_id_key CASCADE;
        
        -- Changer le type
        ALTER TABLE public.brand_categories ALTER COLUMN brand_id TYPE TEXT;
        
        -- Recréer la contrainte d'unicité
        ALTER TABLE public.brand_categories ADD CONSTRAINT brand_categories_brand_id_category_id_key UNIQUE (brand_id, category_id);
        
        RAISE NOTICE '✅ Type de brand_categories.brand_id corrigé de UUID vers TEXT';
    ELSE
        RAISE NOTICE '✅ Type de brand_categories.brand_id déjà correct (TEXT)';
    END IF;
END $$;

-- 5. CORRIGER LE TYPE DE DEVICE_MODELS.BRAND_ID SI NÉCESSAIRE
-- ============================================================================
SELECT '=== CORRECTION DU TYPE DEVICE_MODELS.BRAND_ID ===' as section;

-- Vérifier et corriger device_models.brand_id si la table existe
DO $$
BEGIN
    -- Vérifier si la table device_models existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'device_models' 
        AND table_schema = 'public'
    ) THEN
        -- Vérifier si brand_id existe et est de type UUID
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'device_models' 
            AND column_name = 'brand_id' 
            AND data_type = 'uuid'
            AND table_schema = 'public'
        ) THEN
            -- Changer le type
            ALTER TABLE public.device_models ALTER COLUMN brand_id TYPE TEXT;
            RAISE NOTICE '✅ Type de device_models.brand_id corrigé de UUID vers TEXT';
        ELSE
            RAISE NOTICE '✅ Type de device_models.brand_id déjà correct ou colonne inexistante';
        END IF;
        
        -- Recréer la contrainte de clé étrangère si elle n'existe pas
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE table_name = 'device_models' 
            AND constraint_name = 'device_models_brand_id_fkey'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE public.device_models 
            ADD CONSTRAINT device_models_brand_id_fkey 
            FOREIGN KEY (brand_id, user_id) REFERENCES public.device_brands(id, user_id) ON DELETE CASCADE;
            RAISE NOTICE '✅ Contrainte device_models_brand_id_fkey recréée';
        END IF;
    ELSE
        RAISE NOTICE '✅ Table device_models n''existe pas, pas de correction nécessaire';
    END IF;
END $$;

-- 6. RECRÉER LA FONCTION UPSERT_BRAND
-- ============================================================================
SELECT '=== RECRÉATION DE LA FONCTION UPSERT_BRAND ===' as section;

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

-- 7. RECRÉER LA VUE
-- ============================================================================
SELECT '=== RECRÉATION DE LA VUE ===' as section;

-- Supprimer la vue existante
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Recréer la vue
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
LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id AND bc.user_id = b.user_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id AND dc.user_id = b.user_id
GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.user_id, b.created_at, b.updated_at;

SELECT '✅ Vue brand_with_categories créée' as status;

-- 8. CONFIGURER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.upsert_brand TO authenticated;
GRANT SELECT ON public.brand_with_categories TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- 9. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les types après correction
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories', 'device_models')
AND column_name IN ('id', 'brand_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- Vérifier que la fonction existe
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'upsert_brand' AND routine_schema = 'public')
         THEN '✅ Fonction upsert_brand'
         ELSE '❌ Fonction upsert_brand MANQUANTE'
    END as fonction_status;

-- Vérifier que la vue existe
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'brand_with_categories' AND table_schema = 'public')
         THEN '✅ Vue brand_with_categories'
         ELSE '❌ Vue brand_with_categories MANQUANTE'
    END as vue_status;

-- Tester la vue
SELECT COUNT(*) as nombre_de_marques FROM public.brand_with_categories;

SELECT '=== CORRECTION DES DÉPENDANCES TERMINÉE AVEC SUCCÈS ===' as section;

