-- Script de vérification du schéma de device_models
-- À exécuter pour vérifier que toutes les colonnes nécessaires existent

-- 1. Vérifier toutes les colonnes de device_models
SELECT 'Colonnes de device_models:' as info;

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
        ELSE '❌ Colonne description manquante'
    END as description_status;

-- 3. Vérifier les autres colonnes importantes
SELECT 'Vérification des colonnes importantes:' as info;

SELECT 
    column_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = column_name
        )
        THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as status
FROM (VALUES 
    ('id'),
    ('name'),
    ('brand_id'),
    ('category_id'),
    ('description'),
    ('is_active'),
    ('user_id'),
    ('created_by'),
    ('created_at'),
    ('updated_at')
) AS required_columns(column_name);

-- 4. Tester une requête SELECT simple
SELECT 'Test de requête SELECT...' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active
FROM public.device_models 
LIMIT 1;

-- 5. Vérifier les contraintes et index
SELECT 'Contraintes et index:' as info;

SELECT 
    constraint_name,
    constraint_type,
    column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'device_models' 
AND tc.table_schema = 'public';

-- 6. Vérifier les triggers
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

-- 7. Résumé de la vérification
SELECT 'Vérification terminée' as final_status;


