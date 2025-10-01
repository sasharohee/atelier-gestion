-- Script simple pour restaurer les données par défaut
-- À exécuter dans Supabase SQL Editor

-- 1. Désactiver temporairement RLS pour permettre l'insertion
ALTER TABLE public.device_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories DISABLE ROW LEVEL SECURITY;

-- 2. Créer une catégorie par défaut
INSERT INTO public.device_categories (name, description, icon, is_active, user_id, created_by)
VALUES ('Électronique', 'Catégorie par défaut pour les appareils électroniques', 'smartphone', true, NULL, NULL)
ON CONFLICT DO NOTHING;

-- 3. Créer les marques par défaut
INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by)
VALUES 
    ('1', 'Apple', 'Fabricant américain de produits électroniques premium', '', true, NULL, NULL),
    ('2', 'Samsung', 'Fabricant sud-coréen d''électronique grand public', '', true, NULL, NULL),
    ('3', 'Google', 'Entreprise américaine de technologie', '', true, NULL, NULL),
    ('4', 'Microsoft', 'Entreprise américaine de technologie', '', true, NULL, NULL),
    ('5', 'Sony', 'Conglomérat japonais d''électronique', '', true, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    logo = EXCLUDED.logo,
    updated_at = NOW();

-- 4. Créer les relations marque-catégorie
INSERT INTO public.brand_categories (brand_id, category_id)
SELECT 
    brand_id,
    (SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)
FROM (VALUES 
    ('1'), ('2'), ('3'), ('4'), ('5')
) AS brands(brand_id)
ON CONFLICT (brand_id, category_id) DO NOTHING;

-- 5. Créer les modèles d'exemple (sans specifications pour éviter les problèmes de type)
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

-- 6. Vérifier les données créées
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
