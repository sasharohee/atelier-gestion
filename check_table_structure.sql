-- Script pour vérifier la structure des tables
-- À exécuter dans Supabase SQL Editor

-- Vérifier la structure de device_categories
SELECT 'Structure de device_categories:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'device_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier la structure de device_brands
SELECT 'Structure de device_brands:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier la structure de device_models
SELECT 'Structure de device_models:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier la structure de brand_categories
SELECT 'Structure de brand_categories:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les contraintes de clés étrangères
SELECT 'Contraintes de clés étrangères:' as info;
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND tc.table_name IN ('device_categories', 'device_brands', 'device_models', 'brand_categories');
