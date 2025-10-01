-- Script pour corriger la table device_models
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier la structure actuelle de la table
SELECT '=== STRUCTURE ACTUELLE DE device_models ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne description si elle n'existe pas
DO $$
BEGIN
    -- Vérifier si la colonne description existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND column_name = 'description'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne description
        ALTER TABLE public.device_models 
        ADD COLUMN description TEXT DEFAULT '';
        
        RAISE NOTICE 'Colonne description ajoutée à device_models';
    ELSE
        RAISE NOTICE 'Colonne description existe déjà dans device_models';
    END IF;
END $$;

-- 3. Vérifier la structure après modification
SELECT '=== STRUCTURE APRÈS MODIFICATION ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as info;

SELECT COUNT(*) as total_models FROM public.device_models;

SELECT id, name, description, brand_id, category_id, is_active 
FROM public.device_models 
LIMIT 3;

SELECT '✅ Table device_models corrigée !' as result;
SELECT '💡 La colonne description a été ajoutée si nécessaire.' as note;
