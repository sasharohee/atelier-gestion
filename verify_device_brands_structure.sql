-- Script pour vérifier la structure de la table device_brands
-- À exécuter avant la migration pour comprendre les colonnes disponibles

-- 1. Vérifier la structure de device_brands
SELECT 'Structure de la table device_brands:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes
SELECT 'Contraintes de la table device_brands:' as info;

SELECT 
    constraint_name,
    constraint_type,
    column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'device_brands' 
AND tc.table_schema = 'public';

-- 3. Vérifier les index
SELECT 'Index de la table device_brands:' as info;

SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'device_brands' 
AND schemaname = 'public';

-- 4. Tester une requête simple
SELECT 'Test de requête simple:' as info;

SELECT 
    id,
    name,
    user_id,
    created_at,
    updated_at
FROM public.device_brands 
LIMIT 3;


