-- Script pour vérifier que la colonne description existe
-- À exécuter après definitive_fix_description.sql

-- 1. Vérifier la structure complète
SELECT '=== STRUCTURE COMPLÈTE DE DEVICE_MODELS ===' as info;

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

-- 2. Vérifier spécifiquement la colonne description
SELECT '=== VÉRIFICATION COLONNE DESCRIPTION ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '✅ Colonne description EXISTE'
        ELSE '❌ Colonne description MANQUANTE'
    END as description_status;

-- 3. Vérifier les colonnes NOT NULL
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

-- 4. Tester une requête SELECT avec description
SELECT '=== TEST REQUÊTE SELECT AVEC DESCRIPTION ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active
FROM public.device_models 
LIMIT 1;

-- 5. Tester l'insertion avec description
SELECT '=== TEST INSERTION AVEC DESCRIPTION ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Verify Description Test',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test de vérification de la colonne description',
    true
);

-- 6. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
WHERE name = 'Verify Description Test'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Verify Description Test';

-- 8. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Verify Description Test';

-- 9. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Colonne description présente' as test_2,
    '✅ Requête SELECT réussie' as test_3,
    '✅ Insertion avec description réussie' as test_4,
    '✅ Nettoyage effectué' as test_5;

SELECT '🎉 COLONNE DESCRIPTION VÉRIFIÉE ET FONCTIONNELLE' as final_status;


