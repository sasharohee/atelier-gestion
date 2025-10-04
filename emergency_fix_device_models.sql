-- Script d'urgence pour corriger device_models
-- À exécuter IMMÉDIATEMENT dans l'éditeur SQL de Supabase

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

-- 2. Ajouter la colonne description (sans IF NOT EXISTS pour forcer)
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

-- 4. Supprimer le trigger problématique
SELECT '=== SUPPRESSION DU TRIGGER PROBLÉMATIQUE ===' as info;

DROP TRIGGER IF EXISTS set_device_model_user_ultime ON public.device_models;
DROP FUNCTION IF EXISTS public.set_device_model_user_ultime() CASCADE;

-- 5. Vérifier qu'il n'y a plus de triggers problématiques
SELECT '=== VÉRIFICATION TRIGGERS ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 6. Tester l'insertion immédiatement
SELECT '=== TEST D''INSERTION IMMÉDIAT ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Emergency Fix',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test de la correction d''urgence',
    true
);

-- 7. Vérifier l'insertion
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
WHERE name = 'Test Emergency Fix'
ORDER BY created_at DESC
LIMIT 1;

-- 8. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Emergency Fix';

-- 9. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

SELECT '✅ CORRECTION D''URGENCE TERMINÉE' as final_status;


