-- Script de test pour vérifier la migration V6
-- À exécuter après la migration pour vérifier que tout fonctionne

-- 1. Vérifier que les tables existent
SELECT 'Vérification des tables créées...' as step;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_categories' AND table_schema = 'public')
        THEN '✅ Table device_categories créée'
        ELSE '❌ Table device_categories manquante'
    END as device_categories_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'brand_categories' AND table_schema = 'public')
        THEN '✅ Table brand_categories créée'
        ELSE '❌ Table brand_categories manquante'
    END as brand_categories_status;

-- 2. Vérifier que la vue existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'brand_with_categories' AND schemaname = 'public')
        THEN '✅ Vue brand_with_categories créée'
        ELSE '❌ Vue brand_with_categories manquante'
    END as view_status;

-- 3. Vérifier les politiques RLS
SELECT 'Vérification des politiques RLS...' as step;

SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('device_categories', 'brand_categories')
ORDER BY tablename, policyname;

-- 4. Tester la vue
SELECT 'Test de la vue brand_with_categories...' as step;

SELECT COUNT(*) as total_brands FROM public.brand_with_categories;

-- 5. Afficher la structure de la vue
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'brand_with_categories'
AND schemaname = 'public';

-- 6. Tester avec des données (si elles existent)
SELECT 
    id,
    name,
    user_id,
    categories
FROM public.brand_with_categories 
LIMIT 5;


