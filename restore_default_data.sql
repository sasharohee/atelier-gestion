-- Script pour restaurer les données par défaut
-- À exécuter dans Supabase SQL Editor

-- 1. Désactiver temporairement RLS pour permettre l'insertion
ALTER TABLE public.device_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories DISABLE ROW LEVEL SECURITY;

-- 2. Nettoyer les données existantes (optionnel)
-- DELETE FROM public.brand_categories;
-- DELETE FROM public.device_models;
-- DELETE FROM public.device_brands;
-- DELETE FROM public.device_categories;

-- 3. Créer une catégorie par défaut
INSERT INTO public.device_categories (name, description, icon, is_active, user_id, created_by)
VALUES ('Électronique', 'Catégorie par défaut pour les appareils électroniques', 'smartphone', true, NULL, NULL)
ON CONFLICT DO NOTHING;

-- 4. Récupérer l'ID de la catégorie créée
DO $$
DECLARE
    v_category_id UUID;
BEGIN
    -- Récupérer l'ID de la catégorie Électronique
    SELECT id INTO v_category_id FROM public.device_categories 
    WHERE name = 'Électronique' LIMIT 1;
    
    -- 5. Créer les marques par défaut
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
    
    -- 6. Créer les relations marque-catégorie
    IF v_category_id IS NOT NULL THEN
        INSERT INTO public.brand_categories (brand_id, category_id)
        VALUES 
            ('1', v_category_id),
            ('2', v_category_id),
            ('3', v_category_id),
            ('4', v_category_id),
            ('5', v_category_id)
        ON CONFLICT (brand_id, category_id) DO NOTHING;
        
        RAISE NOTICE '✅ Relations marque-catégorie créées';
    END IF;
    
    RAISE NOTICE '✅ Données par défaut restaurées avec succès';
END $$;

-- 7. Créer quelques modèles d'exemple
INSERT INTO public.device_models (name, description, specifications, brand_id, category_id, is_active, user_id, created_by)
SELECT 
    model_name,
    model_description,
    model_specifications,
    brand_id,
    (SELECT id FROM public.device_categories WHERE name = 'Électronique' LIMIT 1),
    true,
    NULL,
    NULL
FROM (VALUES 
    ('iPhone 15', 'Dernier smartphone d''Apple', 'Écran 6.1", A17 Pro, 128GB', '1'),
    ('Galaxy S24', 'Smartphone Android haut de gamme', 'Écran 6.2", Snapdragon 8 Gen 3, 256GB', '2'),
    ('Pixel 8', 'Smartphone Google avec IA', 'Écran 6.2", Tensor G3, 128GB', '3'),
    ('Surface Pro 9', 'Tablette 2-en-1 Microsoft', 'Écran 13", Intel i7, 512GB', '4'),
    ('WH-1000XM5', 'Casque audio sans fil Sony', 'Réduction de bruit, 30h autonomie', '5')
) AS models(model_name, model_description, model_specifications, brand_id)
ON CONFLICT DO NOTHING;

-- 8. Vérifier les données créées
SELECT 'Vérification des catégories:' as info;
SELECT id, name, description FROM public.device_categories;

SELECT 'Vérification des marques:' as info;
SELECT id, name, description FROM public.device_brands ORDER BY name;

SELECT 'Vérification des modèles:' as info;
SELECT dm.name, db.name as brand_name, dc.name as category_name 
FROM public.device_models dm
LEFT JOIN public.device_brands db ON dm.brand_id = db.id
LEFT JOIN public.device_categories dc ON dm.category_id = dc.id;

SELECT 'Vérification des relations marque-catégorie:' as info;
SELECT db.name as brand_name, dc.name as category_name
FROM public.brand_categories bc
LEFT JOIN public.device_brands db ON bc.brand_id = db.id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id;

-- 9. Réactiver RLS (optionnel - décommentez si vous voulez réactiver la sécurité)
-- ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;

SELECT '✅ Script exécuté avec succès !' as result;
