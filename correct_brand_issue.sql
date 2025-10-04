-- Script corrigé pour résoudre le problème de la colonne "brand"
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle
SELECT '=== STRUCTURE ACTUELLE DE DEVICE_MODELS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Identifier les colonnes NOT NULL
SELECT '=== COLONNES NOT NULL ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 3. Vérifier les données de référence
SELECT '=== DONNÉES DE RÉFÉRENCE ===' as info;

-- Marques disponibles
SELECT 
    'Marques disponibles:' as info,
    COUNT(*) as count
FROM public.device_brands
WHERE is_active = true;

SELECT 
    id,
    name
FROM public.device_brands 
WHERE is_active = true
LIMIT 3;

-- Catégories disponibles
SELECT 
    'Catégories disponibles:' as info,
    COUNT(*) as count
FROM public.device_categories
WHERE is_active = true;

SELECT 
    id,
    name
FROM public.device_categories 
WHERE is_active = true
LIMIT 3;

-- 4. Tester l'insertion simple
SELECT '=== TEST INSERTION SIMPLE ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Simple Model',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test d''insertion simple',
    true
);

-- 5. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active,
    created_at
FROM public.device_models 
WHERE name = 'Test Simple Model'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Simple Model';

-- 7. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Simple Model';

SELECT 'Test d''insertion simple réussi' as final_status;


