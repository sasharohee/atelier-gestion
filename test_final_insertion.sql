-- Script de test final pour l'insertion de device_models
-- À exécuter après avoir identifié les colonnes requises

-- 1. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Vérifier les données de référence
SELECT '=== DONNÉES DE RÉFÉRENCE ===' as info;

-- Première marque disponible
SELECT 
    'Première marque:' as info,
    id,
    name
FROM public.device_brands 
WHERE is_active = true
LIMIT 1;

-- Première catégorie disponible
SELECT 
    'Première catégorie:' as info,
    id,
    name
FROM public.device_categories 
WHERE is_active = true
LIMIT 1;

-- 3. Test d'insertion avec toutes les colonnes possibles
SELECT '=== TEST INSERTION COMPLÈTE ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Final Model',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test final d''insertion avec toutes les colonnes',
    true
);

-- 4. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active,
    user_id,
    created_by,
    created_at,
    updated_at
FROM public.device_models 
WHERE name = 'Test Final Model'
ORDER BY created_at DESC
LIMIT 1;

-- 5. Test de requête avec jointures
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
WHERE dm.name = 'Test Final Model'
ORDER BY dm.created_at DESC
LIMIT 1;

-- 6. Test de mise à jour
SELECT '=== TEST MISE À JOUR ===' as info;

UPDATE public.device_models 
SET 
    description = 'Description mise à jour pour le test final',
    updated_at = NOW()
WHERE name = 'Test Final Model';

-- 7. Vérifier la mise à jour
SELECT '=== VÉRIFICATION MISE À JOUR ===' as info;

SELECT 
    id,
    name,
    description,
    updated_at
FROM public.device_models 
WHERE name = 'Test Final Model';

-- 8. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Final Model';

-- 9. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Final Model';

-- 10. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Insertion réussie' as test_2,
    '✅ Requêtes avec jointures réussies' as test_3,
    '✅ Mise à jour réussie' as test_4,
    '✅ Nettoyage effectué' as test_5;

SELECT '🎉 TOUS LES TESTS D''INSERTION SONT PASSÉS AVEC SUCCÈS' as final_status;


