-- Script pour créer les fonctions RPC manquantes
-- À exécuter dans Supabase SQL Editor

-- 1. Supprimer les anciennes fonctions si elles existent
DROP FUNCTION IF EXISTS public.upsert_brand(text, text, text, text, uuid[]);
DROP FUNCTION IF EXISTS public.update_brand_categories(text, uuid[]);

-- 2. Créer la fonction upsert_brand
CREATE OR REPLACE FUNCTION public.upsert_brand(
    p_id text,
    p_name text,
    p_description text DEFAULT '',
    p_logo text DEFAULT '',
    p_category_ids uuid[] DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result_brand json;
    current_category_id uuid;
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;

    -- Insérer ou mettre à jour la marque
    INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by, updated_at)
    VALUES (p_id, p_name, p_description, p_logo, true, auth.uid(), auth.uid(), NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_at = NOW();

    -- Supprimer les anciennes relations de catégories
    DELETE FROM public.brand_categories WHERE brand_id = p_id;

    -- Ajouter les nouvelles relations de catégories si fournies
    IF p_category_ids IS NOT NULL THEN
        FOREACH current_category_id IN ARRAY p_category_ids
        LOOP
            -- Vérifier que la catégorie existe
            IF EXISTS (SELECT 1 FROM public.device_categories WHERE id = current_category_id) THEN
                INSERT INTO public.brand_categories (brand_id, category_id)
                VALUES (p_id, current_category_id)
                ON CONFLICT (brand_id, category_id) DO NOTHING;
            END IF;
        END LOOP;
    END IF;

    -- Retourner la marque avec ses catégories
    SELECT json_build_object(
        'id', db.id,
        'name', db.name,
        'description', db.description,
        'logo', db.logo,
        'is_active', db.is_active,
        'categories', COALESCE(
            (SELECT json_agg(
                json_build_object(
                    'id', dc.id,
                    'name', dc.name,
                    'description', dc.description,
                    'icon', dc.icon,
                    'is_active', dc.is_active
                )
            )
            FROM public.brand_categories bc
            JOIN public.device_categories dc ON bc.category_id = dc.id
            WHERE bc.brand_id = db.id),
            '[]'::json
        )
    ) INTO result_brand
    FROM public.device_brands db
    WHERE db.id = p_id;

    RETURN result_brand;
END;
$$;

-- 3. Créer la fonction update_brand_categories
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id text,
    p_category_ids uuid[]
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_category_id uuid;
    result_brand json;
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;

    -- Vérifier que la marque existe
    IF NOT EXISTS (SELECT 1 FROM public.device_brands WHERE id = p_brand_id) THEN
        RAISE EXCEPTION 'Marque non trouvée';
    END IF;

    -- Supprimer les anciennes relations
    DELETE FROM public.brand_categories WHERE brand_id = p_brand_id;

    -- Ajouter les nouvelles relations
    IF p_category_ids IS NOT NULL THEN
        FOREACH current_category_id IN ARRAY p_category_ids
        LOOP
            -- Vérifier que la catégorie existe
            IF EXISTS (SELECT 1 FROM public.device_categories WHERE id = current_category_id) THEN
                INSERT INTO public.brand_categories (brand_id, category_id)
                VALUES (p_brand_id, current_category_id)
                ON CONFLICT (brand_id, category_id) DO NOTHING;
            END IF;
        END LOOP;
    END IF;

    -- Retourner la marque mise à jour
    SELECT json_build_object(
        'id', db.id,
        'name', db.name,
        'description', db.description,
        'logo', db.logo,
        'is_active', db.is_active,
        'categories', COALESCE(
            (SELECT json_agg(
                json_build_object(
                    'id', dc.id,
                    'name', dc.name,
                    'description', dc.description,
                    'icon', dc.icon,
                    'is_active', dc.is_active
                )
            )
            FROM public.brand_categories bc
            JOIN public.device_categories dc ON bc.category_id = dc.id
            WHERE bc.brand_id = db.id),
            '[]'::json
        )
    ) INTO result_brand
    FROM public.device_brands db
    WHERE db.id = p_brand_id;

    RETURN result_brand;
END;
$$;

-- 4. Créer la vue brand_with_categories si elle n'existe pas
DROP VIEW IF EXISTS public.brand_with_categories;

CREATE VIEW public.brand_with_categories AS
SELECT 
    db.id,
    db.name,
    db.description,
    db.logo,
    db.is_active,
    db.created_at,
    db.updated_at,
    COALESCE(
        (SELECT json_agg(
            json_build_object(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description,
                'icon', dc.icon,
                'is_active', dc.is_active,
                'created_at', dc.created_at,
                'updated_at', dc.updated_at
            )
        )
        FROM public.brand_categories bc
        JOIN public.device_categories dc ON bc.category_id = dc.id
        WHERE bc.brand_id = db.id),
        '[]'::json
    ) as categories
FROM public.device_brands db;

-- 5. Vérifier que les fonctions ont été créées
SELECT '=== FONCTIONS RPC CRÉÉES ===' as info;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
AND p.proname IN ('upsert_brand', 'update_brand_categories')
ORDER BY p.proname;

SELECT '✅ Fonctions RPC créées avec succès !' as result;
SELECT '💡 Vous pouvez maintenant créer et modifier des marques.' as note;
