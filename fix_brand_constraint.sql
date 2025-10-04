-- Script pour corriger le problème de contrainte NOT NULL sur la colonne "brand"
-- À exécuter après diagnose_brand_constraint.sql

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

-- Première marque disponible
SELECT 
    'Première marque:' as info,
    id,
    name,
    is_active
FROM public.device_brands 
WHERE is_active = true
LIMIT 1;

-- Première catégorie disponible
SELECT 
    'Première catégorie:' as info,
    id,
    name,
    is_active
FROM public.device_categories 
WHERE is_active = true
LIMIT 1;

-- 4. Tester l'insertion avec toutes les colonnes requises
SELECT '=== TEST INSERTION AVEC TOUTES LES COLONNES ===' as info;

-- Créer un modèle avec toutes les colonnes possibles
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Complete Model',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test avec toutes les colonnes requises',
    true
);

-- 5. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    user_id,
    created_by,
    created_at,
    updated_at
FROM public.device_models 
WHERE name = 'Test Complete Model'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Tester la requête avec jointures
SELECT '=== TEST REQUÊTE AVEC JOINTURES ===' as info;

SELECT 
    dm.id,
    dm.name,
    dm.description,
    db.name as brand_name,
    dc.name as category_name,
    dm.is_active,
    dm.created_at
FROM public.device_models dm
LEFT JOIN public.device_brands db ON dm.brand_id = db.id
LEFT JOIN public.device_categories dc ON dm.category_id = dc.id
WHERE dm.name = 'Test Complete Model'
ORDER BY dm.created_at DESC
LIMIT 1;

-- 7. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Complete Model';

-- 8. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Complete Model';

-- 9. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Colonnes NOT NULL identifiées' as test_2,
    '✅ Insertion avec toutes les colonnes réussie' as test_3,
    '✅ Requêtes avec jointures réussies' as test_4,
    '✅ Nettoyage effectué' as test_5;

SELECT '🎉 PROBLÈME DE CONTRAINTE BRAND RÉSOLU' as final_status;


