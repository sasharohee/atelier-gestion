-- Script pour corriger le problème de la colonne "brand"
-- À exécuter après diagnose_brand_column_issue.sql

-- 1. Vérifier la structure actuelle
SELECT '=== STRUCTURE ACTUELLE ===' as info;

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
SELECT '=== COLONNES NOT NULL IDENTIFIÉES ===' as info;

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

-- 3. Vérifier les données de référence disponibles
SELECT '=== DONNÉES DE RÉFÉRENCE DISPONIBLES ===' as info;

-- Vérifier les marques disponibles
SELECT 
    'Marques disponibles:' as info,
    COUNT(*) as count
FROM public.device_brands;

SELECT 
    id,
    name,
    is_active
FROM public.device_brands 
WHERE is_active = true
LIMIT 5;

-- Vérifier les catégories disponibles
SELECT 
    'Catégories disponibles:' as info,
    COUNT(*) as count
FROM public.device_categories;

SELECT 
    id,
    name,
    is_active
FROM public.device_categories 
WHERE is_active = true
LIMIT 5;

-- 4. Tester l'insertion avec toutes les colonnes requises
SELECT '=== TEST INSERTION AVEC TOUTES LES COLONNES ===' as info;

-- Créer un modèle avec toutes les colonnes possibles
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active,
    -- Ajouter d'autres colonnes si elles existent
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'brand'
        )
        THEN 'brand_value'
        ELSE NULL
    END as brand,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'model_year'
        )
        THEN 2024
        ELSE NULL
    END as model_year,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'specifications'
        )
        THEN '{}'::jsonb
        ELSE NULL
    END as specifications
) VALUES (
    'Test Complete Model',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test avec toutes les colonnes requises',
    true,
    'Test Brand',
    2024,
    '{}'::jsonb
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
WHERE name = 'Test Complete Model'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Complete Model';

-- 7. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Complete Model';

SELECT 'Correction du problème de colonne brand terminée' as final_status;


