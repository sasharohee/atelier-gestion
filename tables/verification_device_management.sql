-- =====================================================
-- SCRIPT DE VÉRIFICATION DES TABLES DE GESTION D'APPAREILS
-- =====================================================
-- Vérifie que les tables et fonctionnalités sont correctement créées
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFIER L'EXISTENCE DES TABLES
SELECT '=== VÉRIFICATION DE L''EXISTENCE DES TABLES ===' as etape;

SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as statut
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('device_categories', 'device_brands', 'device_models');

-- 2. VÉRIFIER LA STRUCTURE DES TABLES
SELECT '=== VÉRIFICATION DE LA STRUCTURE DES TABLES ===' as etape;

-- Structure de device_categories
SELECT 'device_categories' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'device_categories'
ORDER BY ordinal_position;

-- Structure de device_brands
SELECT 'device_brands' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'device_brands'
ORDER BY ordinal_position;

-- Structure de device_models
SELECT 'device_models' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES INDEX
SELECT '=== VÉRIFICATION DES INDEX ===' as etape;

SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND tablename IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tablename, indexname;

-- 4. VÉRIFIER LES TRIGGERS
SELECT '=== VÉRIFICATION DES TRIGGERS ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND event_object_table IN ('device_categories', 'device_brands', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 5. VÉRIFIER LES POLITIQUES RLS
SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as etape;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tablename, policyname;

-- 6. VÉRIFIER LES DONNÉES DE TEST
SELECT '=== VÉRIFICATION DES DONNÉES DE TEST ===' as etape;

-- Compter les enregistrements
SELECT 
    'device_categories' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.device_categories
UNION ALL
SELECT 
    'device_brands' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.device_brands
UNION ALL
SELECT 
    'device_models' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.device_models;

-- Afficher les catégories
SELECT 'Catégories créées:' as info;
SELECT 
    id,
    name,
    description,
    icon,
    is_active,
    created_at
FROM public.device_categories
ORDER BY name;

-- Afficher les marques avec leurs catégories
SELECT 'Marques créées:' as info;
SELECT 
    b.id,
    b.name as marque,
    c.name as categorie,
    b.description,
    b.is_active,
    b.created_at
FROM public.device_brands b
LEFT JOIN public.device_categories c ON b.category_id = c.id
ORDER BY b.name;

-- Afficher les modèles avec leurs relations
SELECT 'Modèles créés:' as info;
SELECT 
    m.id,
    m.name as modele,
    b.name as marque,
    c.name as categorie,
    m.year,
    m.repair_difficulty,
    m.parts_availability,
    m.is_active,
    m.created_at
FROM public.device_models m
LEFT JOIN public.device_brands b ON m.brand_id = b.id
LEFT JOIN public.device_categories c ON m.category_id = c.id
ORDER BY m.name;

-- 7. TESTER LES RELATIONS
SELECT '=== TEST DES RELATIONS ===' as etape;

-- Test: Compter les marques par catégorie
SELECT 
    c.name as categorie,
    COUNT(b.id) as nombre_marques
FROM public.device_categories c
LEFT JOIN public.device_brands b ON c.id = b.category_id
GROUP BY c.id, c.name
ORDER BY c.name;

-- Test: Compter les modèles par marque
SELECT 
    b.name as marque,
    c.name as categorie,
    COUNT(m.id) as nombre_modeles
FROM public.device_brands b
LEFT JOIN public.device_categories c ON b.category_id = c.id
LEFT JOIN public.device_models m ON b.id = m.brand_id
GROUP BY b.id, b.name, c.name
ORDER BY b.name;

-- Test: Compter les modèles par catégorie
SELECT 
    c.name as categorie,
    COUNT(m.id) as nombre_modeles
FROM public.device_categories c
LEFT JOIN public.device_models m ON c.id = m.category_id
GROUP BY c.id, c.name
ORDER BY c.name;

-- 8. VÉRIFIER LES CONTRAINTES
SELECT '=== VÉRIFICATION DES CONTRAINTES ===' as etape;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
    AND tc.table_name IN ('device_categories', 'device_brands', 'device_models')
ORDER BY tc.table_name, tc.constraint_type;

-- 9. TEST DE PERFORMANCE SIMPLE
SELECT '=== TEST DE PERFORMANCE ===' as etape;

-- Test de recherche par nom
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM public.device_categories WHERE name ILIKE '%smartphone%';

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM public.device_brands WHERE name ILIKE '%apple%';

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM public.device_models WHERE name ILIKE '%iphone%';

-- 10. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

SELECT 
    '✅ Tables créées' as verification,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_categories') 
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_brands')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_models')
        THEN 'SUCCÈS'
        ELSE 'ÉCHEC'
    END as statut
UNION ALL
SELECT 
    '✅ RLS activé' as verification,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'device_categories' AND rowsecurity = true)
        AND EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'device_brands' AND rowsecurity = true)
        AND EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'device_models' AND rowsecurity = true)
        THEN 'SUCCÈS'
        ELSE 'ÉCHEC'
    END as statut
UNION ALL
SELECT 
    '✅ Données de test' as verification,
    CASE 
        WHEN (SELECT COUNT(*) FROM public.device_categories) > 0
        AND (SELECT COUNT(*) FROM public.device_brands) > 0
        AND (SELECT COUNT(*) FROM public.device_models) > 0
        THEN 'SUCCÈS'
        ELSE 'ÉCHEC'
    END as statut;

SELECT '=== SCRIPT DE VÉRIFICATION TERMINÉ ===' as etape;
