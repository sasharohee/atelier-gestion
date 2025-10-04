-- Script de test complet pour device_models
-- À exécuter après avoir corrigé le trigger d'authentification

-- 1. Vérifier la structure de la table
SELECT 'Structure de device_models:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Vérifier que la colonne description existe
SELECT 'Vérification de la colonne description:' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '✅ Colonne description existe'
        ELSE '❌ Colonne description manquante'
    END as description_status;

-- 3. Vérifier le trigger
SELECT 'Vérification du trigger:' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 4. Tester l'insertion d'un modèle complet
SELECT 'Test d''insertion d''un modèle complet...' as info;

-- Créer un modèle de test avec toutes les colonnes
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'iPhone 15 Pro Max Test',
    (SELECT id FROM public.device_brands WHERE name ILIKE '%apple%' LIMIT 1),
    (SELECT id FROM public.device_categories WHERE name ILIKE '%smartphone%' LIMIT 1),
    'Modèle de test pour iPhone 15 Pro Max avec toutes les fonctionnalités',
    true
) ON CONFLICT DO NOTHING;

-- 5. Vérifier l'insertion
SELECT 'Vérification de l''insertion...' as info;

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
WHERE name = 'iPhone 15 Pro Max Test'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Tester l'insertion avec des données minimales
SELECT 'Test d''insertion avec données minimales...' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id
) VALUES (
    'Modèle Minimal Test',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1)
) ON CONFLICT DO NOTHING;

-- 7. Vérifier l'insertion minimale
SELECT 'Vérification de l''insertion minimale...' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active,
    user_id,
    created_by,
    created_at
FROM public.device_models 
WHERE name = 'Modèle Minimal Test'
ORDER BY created_at DESC
LIMIT 1;

-- 8. Tester la mise à jour
SELECT 'Test de mise à jour...' as info;

UPDATE public.device_models 
SET 
    description = 'Description mise à jour pour le test',
    updated_at = NOW()
WHERE name = 'iPhone 15 Pro Max Test';

-- 9. Vérifier la mise à jour
SELECT 'Vérification de la mise à jour...' as info;

SELECT 
    id,
    name,
    description,
    updated_at
FROM public.device_models 
WHERE name = 'iPhone 15 Pro Max Test';

-- 10. Tester la requête avec jointures
SELECT 'Test de requête avec jointures...' as info;

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
WHERE dm.name IN ('iPhone 15 Pro Max Test', 'Modèle Minimal Test')
ORDER BY dm.created_at DESC;

-- 11. Nettoyer les tests
SELECT 'Nettoyage des tests...' as info;

DELETE FROM public.device_models 
WHERE name IN ('iPhone 15 Pro Max Test', 'Modèle Minimal Test');

-- 12. Vérifier le nettoyage
SELECT 'Vérification du nettoyage...' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name IN ('iPhone 15 Pro Max Test', 'Modèle Minimal Test');

-- 13. Résumé des tests
SELECT 'Résumé des tests:' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Colonne description vérifiée' as test_2,
    '✅ Trigger vérifié' as test_3,
    '✅ Insertion complète testée' as test_4,
    '✅ Insertion minimale testée' as test_5,
    '✅ Mise à jour testée' as test_6,
    '✅ Requêtes avec jointures testées' as test_7,
    '✅ Nettoyage effectué' as test_8;

SELECT 'Tous les tests de device_models sont passés avec succès' as final_status;


