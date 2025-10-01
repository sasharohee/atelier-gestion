-- Script pour restaurer les données en utilisant les fonctions RPC existantes
-- À exécuter dans Supabase SQL Editor

-- 1. Créer une catégorie par défaut directement
INSERT INTO public.device_categories (name, description, icon, is_active, user_id, created_by)
VALUES ('Électronique', 'Catégorie par défaut pour les appareils électroniques', 'smartphone', true, NULL, NULL)
ON CONFLICT DO NOTHING;

-- 2. Utiliser la fonction upsert_brand pour créer les marques
SELECT public.upsert_brand(
    '1', 
    'Apple', 
    'Fabricant américain de produits électroniques premium', 
    '', 
    ARRAY[(SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)]
);

SELECT public.upsert_brand(
    '2', 
    'Samsung', 
    'Fabricant sud-coréen d''électronique grand public', 
    '', 
    ARRAY[(SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)]
);

SELECT public.upsert_brand(
    '3', 
    'Google', 
    'Entreprise américaine de technologie', 
    '', 
    ARRAY[(SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)]
);

SELECT public.upsert_brand(
    '4', 
    'Microsoft', 
    'Entreprise américaine de technologie', 
    '', 
    ARRAY[(SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)]
);

SELECT public.upsert_brand(
    '5', 
    'Sony', 
    'Conglomérat japonais d''électronique', 
    '', 
    ARRAY[(SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)]
);

-- 3. Créer les modèles en utilisant une approche directe avec user_id NULL
-- (Cela devrait contourner la fonction d'authentification)
INSERT INTO public.device_models (name, brand_id, category_id, is_active, user_id, created_by)
SELECT 
    model_name,
    brand_id,
    (SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1),
    true,
    NULL,
    NULL
FROM (VALUES 
    ('iPhone 15', '1'),
    ('Galaxy S24', '2'),
    ('Pixel 8', '3'),
    ('Surface Pro 9', '4'),
    ('WH-1000XM5', '5')
) AS models(model_name, brand_id)
ON CONFLICT DO NOTHING;

-- 4. Vérifier les données créées
SELECT 'Vérification des catégories:' as info;
SELECT id, name, description FROM public.device_categories;

SELECT 'Vérification des marques:' as info;
SELECT id, name, description FROM public.device_brands ORDER BY name;

SELECT 'Vérification des modèles:' as info;
SELECT 
    dm.name, 
    db.name as brand_name, 
    dc.name as category_name 
FROM public.device_models dm
LEFT JOIN public.device_brands db ON dm.brand_id = db.id
LEFT JOIN public.device_categories dc ON dm.category_id = dc.id;

SELECT 'Vérification des relations marque-catégorie:' as info;
SELECT db.name as brand_name, dc.name as category_name
FROM public.brand_categories bc
LEFT JOIN public.device_brands db ON bc.brand_id = db.id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id;

SELECT '✅ Script exécuté avec succès !' as result;
