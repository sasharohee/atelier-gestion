-- ============================================================================
-- SCRIPT DE CORRECTION FINALE DE L'AMBIGUÏTÉ DE COLONNE DANS UPSERT_BRAND (CORRIGÉ)
-- ============================================================================
-- Ce script corrige définitivement l'erreur "column reference 'id' is ambiguous"
-- ============================================================================

SELECT '=== CORRECTION FINALE DE L''AMBIGUÏTÉ DE COLONNE (CORRIGÉ) ===' as section;

-- 1. SUPPRIMER TOUTES LES VERSIONS DE LA FONCTION UPSERT_BRAND
-- ============================================================================
SELECT '=== SUPPRESSION DE TOUTES LES VERSIONS ===' as section;

DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT);

SELECT '✅ Toutes les versions de la fonction upsert_brand supprimées' as status;

-- 2. CRÉER LA FONCTION UPSERT_BRAND CORRIGÉE SANS AMBIGUÏTÉ
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
    -- CORRECTION: Utiliser des qualifications de table complètes
    RETURN QUERY
    SELECT 
        device_brands.id,
        device_brands.name,
        device_brands.description,
        device_brands.logo,
        device_brands.is_active,
        COALESCE(
            json_agg(
                json_build_object(
                    'id', device_categories.id,
                    'name', device_categories.name,
                    'description', device_categories.description,
                    'icon', device_categories.icon,
                    'is_active', device_categories.is_active,
                    'created_at', device_categories.created_at,
                    'updated_at', device_categories.updated_at
                )
            ) FILTER (WHERE device_categories.id IS NOT NULL),
            '[]'::json
        ) as categories,
        device_brands.created_at,
        device_brands.updated_at
    FROM public.device_brands
    LEFT JOIN public.brand_categories ON device_brands.id = brand_categories.brand_id AND brand_categories.user_id = v_user_id
    LEFT JOIN public.device_categories ON brand_categories.category_id = device_categories.id AND device_categories.user_id = v_user_id
    WHERE device_brands.id = v_brand_id AND device_brands.user_id = v_user_id
    GROUP BY device_brands.id, device_brands.name, device_brands.description, device_brands.logo, device_brands.is_active, device_brands.created_at, device_brands.updated_at;
END;
$$;

SELECT '✅ Fonction upsert_brand créée sans ambiguïté de colonne' as status;

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

-- 4. VÉRIFIER LES PARAMÈTRES DE LA FONCTION
-- ============================================================================
SELECT '=== PARAMÈTRES DE LA FONCTION ===' as section;

SELECT 
    parameter_name,
    data_type,
    parameter_mode,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'upsert_brand'
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- 5. ACCORDER LES PERMISSIONS
-- ============================================================================
SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

GRANT EXECUTE ON FUNCTION public.upsert_brand(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- 6. VÉRIFIER LES PERMISSIONS
-- ============================================================================
SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as section;

SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public'
ORDER BY grantee;

-- 7. VÉRIFIER LA DÉFINITION DE LA FONCTION (CORRIGÉ)
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA DÉFINITION ===' as section;

-- Vérifier que la fonction contient les qualifications de table complètes
SELECT 
    CASE 
        WHEN pg_get_functiondef(oid) LIKE '%device_brands.id%' 
        AND pg_get_functiondef(oid) LIKE '%device_categories.id%'
        AND pg_get_functiondef(oid) LIKE '%brand_categories.brand_id%'
        THEN '✅ Fonction contient les qualifications de table complètes'
        ELSE '❌ Fonction ne contient pas les qualifications de table complètes'
    END as fonction_avec_qualifications
FROM pg_proc 
WHERE proname = 'upsert_brand' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 8. VÉRIFIER LES TYPES DE COLONNES
-- ============================================================================
SELECT '=== VÉRIFICATION DES TYPES DE COLONNES ===' as section;

-- Vérifier que les types des colonnes sont corrects
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories', 'device_categories')
AND column_name IN ('id', 'brand_id', 'category_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- 9. VÉRIFIER LES CONTRAINTES
-- ============================================================================
SELECT '=== VÉRIFICATION DES CONTRAINTES ===' as section;

-- Vérifier que les contraintes de clé étrangère existent
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
AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- 10. VÉRIFIER LES DONNÉES
-- ============================================================================
SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Compter les marques existantes
SELECT COUNT(*) as nombre_de_marques FROM public.device_brands;

-- Compter les catégories existantes
SELECT COUNT(*) as nombre_de_categories FROM public.device_categories;

-- Compter les associations marque-catégorie
SELECT COUNT(*) as nombre_d_associations FROM public.brand_categories;

-- 11. TEST DE LA FONCTION (si un utilisateur est connecté)
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

-- 12. RÉSUMÉ DE LA CORRECTION
-- ============================================================================
SELECT '=== RÉSUMÉ DE LA CORRECTION ===' as section;

-- Vérifier que la fonction existe et est accessible
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'upsert_brand'
            AND routine_schema = 'public'
        ) THEN '✅ Fonction upsert_brand existe'
        ELSE '❌ Fonction upsert_brand manquante'
    END as fonction_status;

-- Vérifier que les permissions sont accordées
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routine_privileges 
            WHERE routine_name = 'upsert_brand'
            AND routine_schema = 'public'
            AND grantee = 'authenticated'
        ) THEN '✅ Permissions accordées'
        ELSE '❌ Permissions manquantes'
    END as permissions_status;

SELECT '✅ Correction finale de l''ambiguïté de colonne terminée avec succès' as status;

SELECT '=== CORRECTION FINALE TERMINÉE ===' as section;















