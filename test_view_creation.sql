-- Script de test pour vérifier la création de la vue brand_with_categories
-- À exécuter après la migration V6

-- 1. Vérifier que la vue existe
SELECT 'Vérification de la vue brand_with_categories...' as step;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'brand_with_categories' AND schemaname = 'public')
        THEN '✅ Vue brand_with_categories créée avec succès'
        ELSE '❌ Vue brand_with_categories manquante'
    END as view_status;

-- 2. Afficher la définition de la vue
SELECT 'Définition de la vue:' as step;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'brand_with_categories'
AND schemaname = 'public';

-- 3. Tester la vue avec un COUNT
SELECT 'Test de la vue (COUNT):' as step;

SELECT COUNT(*) as total_brands FROM public.brand_with_categories;

-- 4. Tester la vue avec des données (si elles existent)
SELECT 'Test de la vue (données):' as step;

SELECT 
    id,
    name,
    user_id,
    categories
FROM public.brand_with_categories 
LIMIT 3;

-- 5. Vérifier les colonnes de la vue
SELECT 'Colonnes de la vue:' as step;

SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'brand_with_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;


