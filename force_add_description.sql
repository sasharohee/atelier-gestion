-- Script pour forcer l'ajout de la colonne description
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'état actuel
SELECT 'État actuel de device_models:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne description (force l'ajout)
ALTER TABLE public.device_models 
ADD COLUMN description TEXT;

-- 3. Vérifier que la colonne a été ajoutée
SELECT 'Vérification après ajout:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND column_name = 'description';

-- 4. Tester immédiatement l'insertion
SELECT 'Test d''insertion immédiat...' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Description Column',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test de la colonne description ajoutée',
    true
);

-- 5. Vérifier l'insertion
SELECT 'Vérification de l''insertion:' as info;

SELECT 
    id,
    name,
    description,
    created_at
FROM public.device_models 
WHERE name = 'Test Description Column'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Description Column';

SELECT 'Colonne description ajoutée et testée avec succès' as final_status;


