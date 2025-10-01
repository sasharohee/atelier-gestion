-- Script complet pour corriger l'isolation des données des marques
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier et ajouter les colonnes manquantes à device_brands
DO $$
BEGIN
    -- Ajouter user_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'user_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.device_brands 
        ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à device_brands';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans device_brands';
    END IF;

    -- Ajouter created_by si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'created_by'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.device_brands 
        ADD COLUMN created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_brands';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_brands';
    END IF;

    -- Ajouter updated_by si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'updated_by'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.device_brands 
        ADD COLUMN updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Colonne updated_by ajoutée à device_brands';
    ELSE
        RAISE NOTICE '✅ Colonne updated_by existe déjà dans device_brands';
    END IF;
END $$;

-- 2. Assigner les marques existantes au premier utilisateur
DO $$
DECLARE
    first_user_id UUID;
BEGIN
    -- Récupérer le premier utilisateur
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
        -- Mettre à jour les marques sans user_id
        UPDATE public.device_brands 
        SET 
            user_id = first_user_id,
            created_by = first_user_id,
            updated_by = first_user_id
        WHERE user_id IS NULL;
        
        RAISE NOTICE '✅ Marques existantes assignées à l''utilisateur: %', first_user_id;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour assigner les marques existantes';
    END IF;
END $$;

-- 3. Supprimer la vue existante si elle existe
DROP VIEW IF EXISTS public.brand_with_categories;

-- 4. Recréer la vue brand_with_categories avec user_id
CREATE VIEW public.brand_with_categories AS
SELECT 
    b.id,
    b.name,
    b.description,
    b.logo,
    b.is_active,
    b.user_id,
    b.created_by,
    b.updated_by,
    b.created_at,
    b.updated_at,
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
    ) as categories
FROM public.device_brands b
LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id
LEFT JOIN public.device_categories c ON bc.category_id = c.id
GROUP BY 
    b.id, 
    b.name, 
    b.description, 
    b.logo, 
    b.is_active, 
    b.user_id,
    b.created_by,
    b.updated_by,
    b.created_at, 
    b.updated_at;

-- 5. Activer RLS sur device_brands
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;

-- 6. Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can create their own brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can update their own brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can delete their own brands" ON public.device_brands;

-- 7. Créer les nouvelles politiques RLS
-- Politique pour SELECT (lecture)
CREATE POLICY "Users can view their own brands" ON public.device_brands
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour INSERT (création)
CREATE POLICY "Users can create their own brands" ON public.device_brands
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour UPDATE (modification)
CREATE POLICY "Users can update their own brands" ON public.device_brands
    FOR UPDATE USING (auth.uid() = user_id);

-- Politique pour DELETE (suppression)
CREATE POLICY "Users can delete their own brands" ON public.device_brands
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Supprimer les anciennes fonctions RPC
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT, UUID[]);

-- 9. Recréer les fonctions RPC avec la bonne signature
-- Fonction upsert_brand mise à jour
CREATE FUNCTION public.upsert_brand(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
    id TEXT,
    name TEXT,
    description TEXT,
    logo TEXT,
    is_active BOOLEAN,
    user_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    categories JSON
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
    brand_record RECORD;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;

    -- Upsert de la marque
    INSERT INTO public.device_brands (
        id, 
        name, 
        description, 
        logo, 
        is_active,
        user_id,
        created_by,
        updated_by,
        created_at, 
        updated_at
    ) VALUES (
        p_id, 
        p_name, 
        p_description, 
        p_logo, 
        TRUE,
        current_user_id,
        current_user_id,
        current_user_id,
        NOW(), 
        NOW()
    )
    ON CONFLICT (id) 
    DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_by = current_user_id,
        updated_at = NOW();

    -- Mettre à jour les catégories si fournies
    IF p_category_ids IS NOT NULL THEN
        PERFORM public.update_brand_categories(p_id, p_category_ids);
    END IF;

    -- Retourner la marque avec ses catégories
    SELECT * INTO brand_record
    FROM public.brand_with_categories
    WHERE brand_with_categories.id = p_id
    AND brand_with_categories.user_id = current_user_id;

    IF FOUND THEN
        RETURN QUERY SELECT 
            brand_record.id,
            brand_record.name,
            brand_record.description,
            brand_record.logo,
            brand_record.is_active,
            brand_record.user_id,
            brand_record.created_at,
            brand_record.updated_at,
            brand_record.categories;
    ELSE
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;
END;
$$;

-- Fonction update_brand_categories mise à jour
CREATE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
    current_category_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;

    -- Vérifier que la marque appartient à l'utilisateur
    IF NOT EXISTS (
        SELECT 1 
        FROM public.device_brands 
        WHERE id = p_brand_id 
        AND user_id = current_user_id
    ) THEN
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;

    -- Supprimer les associations existantes
    DELETE FROM public.brand_categories 
    WHERE brand_id = p_brand_id;

    -- Ajouter les nouvelles associations
    IF p_category_ids IS NOT NULL THEN
        FOREACH current_category_id IN ARRAY p_category_ids
        LOOP
            -- Vérifier que la catégorie existe
            IF EXISTS (
                SELECT 1 
                FROM public.device_categories 
                WHERE id = current_category_id
            ) THEN
                INSERT INTO public.brand_categories (brand_id, category_id)
                VALUES (p_brand_id, current_category_id);
            END IF;
        END LOOP;
    END IF;
END;
$$;

-- 10. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as info;

-- Structure de device_brands
SELECT 'Structure device_brands:' as check_type;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Structure de brand_with_categories
SELECT 'Structure brand_with_categories:' as check_type;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'brand_with_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Politiques RLS
SELECT 'Politiques RLS:' as check_type;
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'device_brands'
ORDER BY policyname;

-- Données avec user_id
SELECT 'Données avec user_id:' as check_type;
SELECT id, name, user_id, created_at 
FROM public.device_brands 
ORDER BY created_at DESC 
LIMIT 5;

SELECT '✅ Isolation des données des marques configurée avec succès !' as result;
