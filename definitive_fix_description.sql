-- Script définitif pour ajouter la colonne description
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'état actuel
SELECT '=== ÉTAT ACTUEL DE DEVICE_MODELS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne description (force absolue)
ALTER TABLE public.device_models 
ADD COLUMN description TEXT;

-- 3. Vérifier immédiatement l'ajout
SELECT '=== VÉRIFICATION APRÈS AJOUT ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND column_name = 'description';

-- 4. Tester l'insertion immédiatement
SELECT '=== TEST INSERTION IMMÉDIAT ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Definitive Fix',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test de la correction définitive',
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
    created_at
FROM public.device_models 
WHERE name = 'Test Definitive Fix'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Definitive Fix';

-- 7. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Definitive Fix';

-- 8. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

SELECT '✅ COLONNE DESCRIPTION AJOUTÉE DÉFINITIVEMENT' as final_status;


