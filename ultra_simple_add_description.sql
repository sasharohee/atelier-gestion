-- Script ultra-simple pour ajouter la colonne description
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Ajouter la colonne description (sans vérification)
ALTER TABLE public.device_models 
ADD COLUMN description TEXT;

-- 2. Vérifier que la colonne a été ajoutée
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND column_name = 'description';

-- 3. Tester immédiatement
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Ultra Simple',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test ultra simple',
    true
);

-- 4. Vérifier l'insertion
SELECT 
    id,
    name,
    description,
    created_at
FROM public.device_models 
WHERE name = 'Test Ultra Simple'
ORDER BY created_at DESC
LIMIT 1;

-- 5. Nettoyer
DELETE FROM public.device_models 
WHERE name = 'Test Ultra Simple';

SELECT 'Colonne description ajoutée avec succès' as status;


