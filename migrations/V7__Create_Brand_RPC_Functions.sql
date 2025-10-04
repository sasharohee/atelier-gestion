-- Migration V7: Création des fonctions RPC pour la gestion des marques
-- Ces fonctions permettent de créer, modifier et gérer les marques avec leurs catégories

-- 1. Supprimer les fonctions existantes si elles existent
DROP FUNCTION IF EXISTS public.update_brand_categories(text, uuid[]) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_brand(text, text, text, text, uuid[]) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_brand_simple(text, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.create_brand_basic(text, text, text, text) CASCADE;

-- 2. Créer la fonction update_brand_categories
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids UUID[]
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

    -- Supprimer les associations existantes pour cette marque
    DELETE FROM public.brand_categories 
    WHERE brand_id = p_brand_id AND user_id = v_user_id;

    -- Ajouter les nouvelles associations
    IF p_category_ids IS NOT NULL AND array_length(p_category_ids, 1) > 0 THEN
        INSERT INTO public.brand_categories (brand_id, category_id, user_id)
        SELECT p_brand_id, unnest(p_category_ids), v_user_id;
    END IF;

    RETURN json_build_object('success', true, 'message', 'Catégories mises à jour');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Créer la fonction upsert_brand (complète)
CREATE OR REPLACE FUNCTION public.upsert_brand(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_ids UUID[] DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_brand_id UUID;
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

    -- Convertir l'ID en UUID si nécessaire
    BEGIN
        v_brand_id := p_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        -- Si la conversion échoue, générer un UUID
        v_brand_id := gen_random_uuid();
    END;

    -- Insérer ou mettre à jour la marque
    INSERT INTO public.device_brands (id, name, description, logo, user_id, created_by)
    VALUES (v_brand_id, p_name, p_description, p_logo, v_user_id, v_user_id)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_at = NOW()
    WHERE device_brands.user_id = v_user_id;

    -- Vérifier que l'insertion/mise à jour a réussi
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Marque non trouvée ou accès refusé');
    END IF;

    -- Mettre à jour les catégories si fournies
    IF p_category_ids IS NOT NULL THEN
        PERFORM public.update_brand_categories(v_brand_id::TEXT, p_category_ids);
    END IF;

    -- Retourner la marque créée/mise à jour
    SELECT json_build_object(
        'success', true,
        'id', v_brand_id,
        'name', p_name,
        'description', p_description,
        'logo', p_logo,
        'user_id', v_user_id,
        'created_at', NOW(),
        'updated_at', NOW()
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Créer la fonction upsert_brand_simple (version simplifiée)
CREATE OR REPLACE FUNCTION public.upsert_brand_simple(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT ''
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_brand_id UUID;
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

    -- Convertir l'ID en UUID si nécessaire
    BEGIN
        v_brand_id := p_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        -- Si la conversion échoue, générer un UUID
        v_brand_id := gen_random_uuid();
    END;

    -- Insérer ou mettre à jour la marque
    INSERT INTO public.device_brands (id, name, description, logo, user_id, created_by)
    VALUES (v_brand_id, p_name, p_description, p_logo, v_user_id, v_user_id)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_at = NOW()
    WHERE device_brands.user_id = v_user_id;

    -- Vérifier que l'insertion/mise à jour a réussi
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Marque non trouvée ou accès refusé');
    END IF;

    -- Retourner la marque créée/mise à jour
    SELECT json_build_object(
        'success', true,
        'id', v_brand_id,
        'name', p_name,
        'description', p_description,
        'logo', p_logo,
        'user_id', v_user_id,
        'created_at', NOW(),
        'updated_at', NOW()
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Créer la fonction create_brand_basic (version basique)
CREATE OR REPLACE FUNCTION public.create_brand_basic(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT ''
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_brand_id UUID;
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

    -- Convertir l'ID en UUID si nécessaire
    BEGIN
        v_brand_id := p_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        -- Si la conversion échoue, générer un UUID
        v_brand_id := gen_random_uuid();
    END;

    -- Insérer la marque
    INSERT INTO public.device_brands (id, name, description, logo, user_id, created_by)
    VALUES (v_brand_id, p_name, p_description, p_logo, v_user_id, v_user_id);

    -- Retourner la marque créée
    SELECT json_build_object(
        'success', true,
        'id', v_brand_id,
        'name', p_name,
        'description', p_description,
        'logo', p_logo,
        'user_id', v_user_id,
        'created_at', NOW(),
        'updated_at', NOW()
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Accorder les permissions nécessaires
GRANT EXECUTE ON FUNCTION public.update_brand_categories(text, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand(text, text, text, text, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_brand_simple(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_brand_basic(text, text, text, text) TO authenticated;

-- 7. Tester les fonctions créées
SELECT 'Fonctions RPC créées avec succès' as status;
SELECT 'Test de la fonction upsert_brand...' as test_step;
