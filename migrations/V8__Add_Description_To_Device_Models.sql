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

-- 3. Migration terminée avec succès
SELECT 'Migration V8 terminée avec succès' as final_status;


