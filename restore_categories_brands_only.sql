-- Script simple pour restaurer seulement les catégories et marques
-- À exécuter dans Supabase SQL Editor

-- 1. Créer une catégorie par défaut
INSERT INTO public.device_categories (name, description, icon, is_active, user_id, created_by)
VALUES ('Électronique', 'Catégorie par défaut pour les appareils électroniques', 'smartphone', true, NULL, NULL)
ON CONFLICT DO NOTHING;

-- 2. Créer les marques par défaut
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

-- 3. Créer les relations marque-catégorie
INSERT INTO public.brand_categories (brand_id, category_id)
SELECT 
    brand_id,
    (SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1)
FROM (VALUES 
    ('1'), ('2'), ('3'), ('4'), ('5')
) AS brands(brand_id)
ON CONFLICT (brand_id, category_id) DO NOTHING;

-- 4. Vérifier les données créées
SELECT 'Vérification des catégories:' as info;
SELECT id, name, description FROM public.device_categories;

SELECT 'Vérification des marques:' as info;
SELECT id, name, description FROM public.device_brands ORDER BY name;

SELECT 'Vérification des relations marque-catégorie:' as info;
SELECT db.name as brand_name, dc.name as category_name
FROM public.brand_categories bc
LEFT JOIN public.device_brands db ON bc.brand_id = db.id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id;

SELECT '✅ Catégories et marques créées avec succès !' as result;
SELECT '💡 Les modèles peuvent être ajoutés plus tard via l''interface utilisateur.' as note;
