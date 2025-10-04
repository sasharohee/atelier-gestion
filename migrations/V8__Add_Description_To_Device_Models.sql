-- Migration V8: Ajout de la colonne description à device_models
-- Cette colonne est nécessaire pour le bon fonctionnement de l'application

-- 1. Vérifier si la colonne description existe déjà
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

-- 2. Vérifier la structure de la table après modification
SELECT 'Structure de la table device_models après modification:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 3. Tester l'insertion avec la colonne description
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
    'Test Model',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Description de test pour vérifier la colonne',
    true,
    auth.uid(),
    auth.uid()
) ON CONFLICT DO NOTHING;

-- 4. Vérifier l'insertion
SELECT 'Vérification de l''insertion...' as test_step;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active
FROM public.device_models 
WHERE name = 'Test Model'
AND user_id = auth.uid();

-- 5. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Model'
AND user_id = auth.uid();

SELECT 'Test terminé avec succès' as final_status;


