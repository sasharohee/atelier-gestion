-- Script pour vérifier la structure actuelle de device_models
-- À exécuter pour diagnostiquer les problèmes

-- 1. Vérifier toutes les colonnes de device_models
SELECT 'Structure actuelle de device_models:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Vérifier spécifiquement la colonne description
SELECT 'Vérification de la colonne description:' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '✅ Colonne description existe'
        ELSE '❌ Colonne description manquante - DOIT ÊTRE AJOUTÉE'
    END as description_status;

-- 3. Vérifier les colonnes requises par l'application
SELECT 'Colonnes requises par l''application:' as info;

SELECT 
    'name' as required_column,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'name'
        )
        THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status
UNION ALL
SELECT 
    'brand_id' as required_column,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'brand_id'
        )
        THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status
UNION ALL
SELECT 
    'category_id' as required_column,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'category_id'
        )
        THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status
UNION ALL
SELECT 
    'description' as required_column,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status
UNION ALL
SELECT 
    'is_active' as required_column,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'is_active'
        )
        THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status;

-- 4. Vérifier les contraintes
SELECT 'Contraintes sur device_models:' as info;

SELECT 
    constraint_name,
    constraint_type,
    column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'device_models' 
AND tc.table_schema = 'public';

-- 5. Vérifier les triggers
SELECT 'Triggers sur device_models:' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 6. Vérifier les index
SELECT 'Index sur device_models:' as info;

SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'device_models'
AND schemaname = 'public';

-- 7. Tester une requête SELECT simple
SELECT 'Test de requête SELECT...' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
LIMIT 1;

-- 8. Résumé des problèmes
SELECT 'Résumé des problèmes identifiés:' as info;

SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'description'
        )
        THEN '❌ PROBLÈME: Colonne description manquante'
        ELSE '✅ Colonne description présente'
    END as problem_1,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'name'
        )
        THEN '❌ PROBLÈME: Colonne name manquante'
        ELSE '✅ Colonne name présente'
    END as problem_2,
    
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'brand_id'
        )
        THEN '❌ PROBLÈME: Colonne brand_id manquante'
        ELSE '✅ Colonne brand_id présente'
    END as problem_3;

SELECT 'Vérification terminée' as final_status;


