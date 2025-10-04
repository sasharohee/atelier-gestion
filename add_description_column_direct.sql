-- Script direct pour ajouter la colonne description à device_models
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle de la table
SELECT 'Structure actuelle de device_models:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne description si elle n'existe pas
DO $$
BEGIN
    -- Vérifier si la colonne description existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'description'
    ) THEN
        -- Ajouter la colonne description
        ALTER TABLE public.device_models 
        ADD COLUMN description TEXT;
        
        RAISE NOTICE '✅ Colonne description ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne description existe déjà dans device_models';
    END IF;
END $$;

-- 3. Vérifier la structure après modification
SELECT 'Structure après ajout de description:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 4. Tester l'insertion avec description
SELECT 'Test d''insertion avec description...' as test_step;

-- Créer un modèle de test avec description
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active,
    user_id,
    created_by
) VALUES (
    'Test Model With Description',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Description de test pour vérifier la colonne',
    true,
    auth.uid(),
    auth.uid()
) ON CONFLICT DO NOTHING;

-- 5. Vérifier l'insertion
SELECT 'Vérification de l''insertion...' as test_step;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
WHERE name = 'Test Model With Description'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Model With Description';

-- 7. Vérifier le nettoyage
SELECT 'Vérification du nettoyage...' as test_step;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Model With Description';

SELECT 'Colonne description ajoutée avec succès' as final_status;


