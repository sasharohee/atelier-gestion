-- Script pour s'assurer que la colonne description existe
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier si la colonne description existe
SELECT '=== VÉRIFICATION DE LA COLONNE DESCRIPTION ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'device_models' 
            AND column_name = 'description'
            AND table_schema = 'public'
        ) THEN '✅ Colonne description existe'
        ELSE '❌ Colonne description manquante'
    END as status;

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
        
        RAISE NOTICE '✅ Colonne description ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne description existe déjà dans device_models';
    END IF;
END $$;

-- 3. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE DE device_models ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Mettre à jour les modèles existants qui ont une description vide
UPDATE public.device_models 
SET description = COALESCE(description, '') 
WHERE description IS NULL;

-- 5. Vérifier les données
SELECT '=== DONNÉES ACTUELLES ===' as info;

SELECT id, name, description, brand_id, category_id 
FROM public.device_models 
LIMIT 5;

SELECT '✅ Table device_models prête pour les descriptions !' as result;
