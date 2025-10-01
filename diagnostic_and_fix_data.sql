-- Script de diagnostic et correction des données
-- À exécuter dans Supabase SQL Editor

-- 1. DIAGNOSTIC : Vérifier l'état actuel des tables
SELECT '=== DIAGNOSTIC DES TABLES ===' as info;

SELECT 'Table device_categories:' as table_name;
SELECT COUNT(*) as total_count, 
       COUNT(CASE WHEN user_id IS NULL THEN 1 END) as without_user_id,
       COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as with_user_id
FROM public.device_categories;

SELECT 'Table device_brands:' as table_name;
SELECT COUNT(*) as total_count,
       COUNT(CASE WHEN user_id IS NULL THEN 1 END) as without_user_id,
       COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as with_user_id
FROM public.device_brands;

SELECT 'Table device_models:' as table_name;
SELECT COUNT(*) as total_count,
       COUNT(CASE WHEN user_id IS NULL THEN 1 END) as without_user_id,
       COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as with_user_id
FROM public.device_models;

-- 2. CORRECTION : Créer des données de test avec user_id
SELECT '=== CORRECTION DES DONNÉES ===' as info;

-- Créer un utilisateur de test (utilisez votre vrai user_id)
-- Remplacez '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a' par votre vrai user_id
DO $$
DECLARE
    test_user_id TEXT := '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a';
BEGIN
    -- Supprimer les anciennes données de test
    DELETE FROM public.brand_categories WHERE brand_id IN ('1', '2', '3', '4', '5');
    DELETE FROM public.device_brands WHERE id IN ('1', '2', '3', '4', '5');
    DELETE FROM public.device_categories WHERE name = 'Électronique';
    
    -- Créer une catégorie de test avec user_id
    INSERT INTO public.device_categories (name, description, icon, is_active, user_id, created_by)
    VALUES ('Électronique', 'Catégorie par défaut pour les appareils électroniques', 'smartphone', true, test_user_id, test_user_id)
    ON CONFLICT DO NOTHING;
    
    -- Créer les marques de test avec user_id
    INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by)
    VALUES 
        ('1', 'Apple', 'Fabricant américain de produits électroniques premium', '', true, test_user_id, test_user_id),
        ('2', 'Samsung', 'Fabricant sud-coréen d''électronique grand public', '', true, test_user_id, test_user_id),
        ('3', 'Google', 'Entreprise américaine de technologie', '', true, test_user_id, test_user_id),
        ('4', 'Microsoft', 'Entreprise américaine de technologie', '', true, test_user_id, test_user_id),
        ('5', 'Sony', 'Conglomérat japonais d''électronique', '', true, test_user_id, test_user_id)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        user_id = EXCLUDED.user_id,
        updated_at = NOW();
    
    -- Créer les relations marque-catégorie
    INSERT INTO public.brand_categories (brand_id, category_id)
    SELECT 
        brand_id,
        (SELECT id FROM public.device_categories WHERE name = 'Électronique' AND user_id = test_user_id LIMIT 1)
    FROM (VALUES 
        ('1'), ('2'), ('3'), ('4'), ('5')
    ) AS brands(brand_id)
    ON CONFLICT (brand_id, category_id) DO NOTHING;
    
    RAISE NOTICE 'Données de test créées avec user_id: %', test_user_id;
END $$;

-- 3. VÉRIFICATION : Vérifier que les données sont correctement créées
SELECT '=== VÉRIFICATION DES DONNÉES ===' as info;

SELECT 'Catégories créées:' as info;
SELECT id, name, description, user_id FROM public.device_categories WHERE user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a';

SELECT 'Marques créées:' as info;
SELECT id, name, description, user_id FROM public.device_brands WHERE user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a' ORDER BY name;

SELECT 'Relations marque-catégorie:' as info;
SELECT db.name as brand_name, dc.name as category_name
FROM public.brand_categories bc
LEFT JOIN public.device_brands db ON bc.brand_id = db.id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
WHERE db.user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a';

-- 4. TEST : Vérifier que les vues fonctionnent
SELECT '=== TEST DES VUES ===' as info;

-- Tester la vue brand_with_categories
SELECT 'Test de la vue brand_with_categories:' as info;
SELECT id, name, description, categories FROM public.brand_with_categories LIMIT 3;

SELECT '✅ Script de diagnostic et correction terminé !' as result;
SELECT '💡 Rechargez votre application pour voir les données.' as note;
