-- Script pour vérifier la structure de la table device_models
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier la structure de la table device_models
SELECT '=== STRUCTURE DE LA TABLE device_models ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes de clés étrangères
SELECT '=== CONTRAINTES DE CLÉS ÉTRANGÈRES ===' as info;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'device_models'
AND tc.table_schema = 'public';

-- 3. Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as info;

SELECT COUNT(*) as total_models FROM public.device_models;

SELECT * FROM public.device_models LIMIT 3;
