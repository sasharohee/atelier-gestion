-- Script pour vérifier la structure actuelle des tables
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier la structure de la table device_brands
SELECT '=== STRUCTURE DE device_brands ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier si la vue brand_with_categories existe
SELECT '=== VÉRIFICATION VUE brand_with_categories ===' as info;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.views 
            WHERE table_name = 'brand_with_categories' 
            AND table_schema = 'public'
        ) THEN '✅ Vue brand_with_categories existe'
        ELSE '❌ Vue brand_with_categories manquante'
    END as status;

-- 3. Si la vue existe, vérifier sa structure
SELECT '=== STRUCTURE DE LA VUE brand_with_categories ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'brand_with_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Vérifier les données actuelles
SELECT '=== DONNÉES ACTUELLES device_brands ===' as info;
SELECT id, name, user_id, created_at 
FROM public.device_brands 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Vérifier si RLS est activé
SELECT '=== VÉRIFICATION RLS ===' as info;
SELECT 
    relname,
    relrowsecurity,
    relforcerowsecurity
FROM pg_class 
WHERE relname = 'device_brands';

-- 6. Vérifier les politiques RLS existantes
SELECT '=== POLITIQUES RLS EXISTANTES ===' as info;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'device_brands'
ORDER BY policyname;
