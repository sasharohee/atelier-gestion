-- =====================================================
-- CORRECTION DE LA TABLE DEVICE_MODELS
-- =====================================================
-- Date: 2025-01-23
-- Problème: "Could not find the 'common_issues' column of 'device_models' in the schema cache"
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
SELECT '=== STRUCTURE ACTUELLE DEVICE_MODELS ===' as section;

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

-- 2. AJOUTER TOUTES LES COLONNES MANQUANTES
DO $$
BEGIN
    -- Ajouter brand si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'brand'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN brand TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne brand ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne brand existe déjà dans la table device_models';
    END IF;

    -- Ajouter model si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'model'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN model TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne model ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne model existe déjà dans la table device_models';
    END IF;

    -- Ajouter type si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'type'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN type TEXT NOT NULL DEFAULT 'other';
        RAISE NOTICE '✅ Colonne type ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne type existe déjà dans la table device_models';
    END IF;

    -- Ajouter year si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'year'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN year INTEGER NOT NULL DEFAULT 2024;
        RAISE NOTICE '✅ Colonne year ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne year existe déjà dans la table device_models';
    END IF;

    -- Ajouter specifications si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN specifications JSONB DEFAULT '{}';
        RAISE NOTICE '✅ Colonne specifications ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne specifications existe déjà dans la table device_models';
    END IF;

    -- Ajouter common_issues si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'common_issues'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN common_issues TEXT[] DEFAULT '{}';
        RAISE NOTICE '✅ Colonne common_issues ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne common_issues existe déjà dans la table device_models';
    END IF;

    -- Ajouter repair_difficulty si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'repair_difficulty'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN repair_difficulty TEXT DEFAULT 'medium';
        RAISE NOTICE '✅ Colonne repair_difficulty ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne repair_difficulty existe déjà dans la table device_models';
    END IF;

    -- Ajouter parts_availability si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'parts_availability'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN parts_availability TEXT DEFAULT 'medium';
        RAISE NOTICE '✅ Colonne parts_availability ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne parts_availability existe déjà dans la table device_models';
    END IF;

    -- Ajouter is_active si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne is_active ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne is_active existe déjà dans la table device_models';
    END IF;

    -- Ajouter created_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans la table device_models';
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à la table device_models';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans la table device_models';
    END IF;
END $$;

-- 3. CRÉER LES INDEX NÉCESSAIRES
CREATE INDEX IF NOT EXISTS idx_device_models_brand ON public.device_models(brand);
CREATE INDEX IF NOT EXISTS idx_device_models_type ON public.device_models(type);
CREATE INDEX IF NOT EXISTS idx_device_models_is_active ON public.device_models(is_active);

-- 4. RAFRAÎCHIR LE CACHE POSTGREST (CRITIQUE)
NOTIFY pgrst, 'reload schema';

-- 5. ATTENDRE UN MOMENT POUR LA SYNCHRONISATION
SELECT pg_sleep(2);

-- 6. VÉRIFIER LA STRUCTURE FINALE
SELECT '=== STRUCTURE FINALE DEVICE_MODELS ===' as section;

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

-- 7. TEST D'INSERTION
DO $$
DECLARE
    test_model_id UUID;
BEGIN
    -- Test d'insertion avec toutes les colonnes
    INSERT INTO public.device_models (
        brand, model, type, year, specifications, common_issues, repair_difficulty, parts_availability, is_active
    ) VALUES (
        'Apple', 'iPhone 15', 'smartphone', 2024, '{"screen": "6.1 inch", "processor": "A17 Pro"}', ARRAY['Écran cassé', 'Batterie défaillante'], 'medium', 'high', true
    ) RETURNING id INTO test_model_id;
    
    RAISE NOTICE '✅ Test d''insertion réussi. Model ID: %', test_model_id;
    
    -- Vérifier que le modèle a été créé
    IF EXISTS (SELECT 1 FROM public.device_models WHERE id = test_model_id) THEN
        RAISE NOTICE '✅ Modèle trouvé en base de données';
    ELSE
        RAISE NOTICE '❌ Modèle non trouvé en base de données';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM public.device_models WHERE id = test_model_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT 'CORRECTION DEVICE_MODELS TERMINÉE' as status;
