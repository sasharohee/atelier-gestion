-- Script simple pour corriger le problème de la colonne "brand"
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle
SELECT 'Structure actuelle de device_models:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Identifier le problème exact
SELECT 'Colonnes NOT NULL identifiées:' as info;

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
SELECT 'Données de référence disponibles:' as info;

SELECT 
    'Marques:' as type,
    COUNT(*) as count
FROM public.device_brands
WHERE is_active = true
UNION ALL
SELECT 
    'Catégories:' as type,
    COUNT(*) as count
FROM public.device_categories
WHERE is_active = true;

-- 4. Tester l'insertion avec les colonnes minimales requises
SELECT 'Test d''insertion avec colonnes minimales...' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Minimal Model',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test avec colonnes minimales',
    true
);

-- 5. Vérifier l'insertion
SELECT 'Vérification de l''insertion:' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active,
    created_at
FROM public.device_models 
WHERE name = 'Test Minimal Model'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Minimal Model';

-- 7. Vérifier le nettoyage
SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Minimal Model';

SELECT 'Test d''insertion minimal réussi' as final_status;


