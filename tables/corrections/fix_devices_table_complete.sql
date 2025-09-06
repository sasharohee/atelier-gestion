-- =====================================================
-- CORRECTION COMPLÈTE DE LA TABLE DEVICES
-- =====================================================
-- Date: 2025-01-23
-- Problème: "Could not find the 'brand' column of 'devices' in the schema cache"
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
SELECT '=== STRUCTURE ACTUELLE DEVICES ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

-- 2. AJOUTER TOUTES LES COLONNES MANQUANTES
DO $$
BEGIN
    -- Ajouter user_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans la table devices';
    END IF;

    -- Ajouter brand si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'brand'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN brand TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne brand ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne brand existe déjà dans la table devices';
    END IF;

    -- Ajouter model si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'model'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN model TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne model ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne model existe déjà dans la table devices';
    END IF;

    -- Ajouter serial_number si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'serial_number'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN serial_number TEXT;
        RAISE NOTICE '✅ Colonne serial_number ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne serial_number existe déjà dans la table devices';
    END IF;

    -- Ajouter type si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'type'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN type TEXT NOT NULL DEFAULT 'other';
        RAISE NOTICE '✅ Colonne type ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne type existe déjà dans la table devices';
    END IF;

    -- Ajouter specifications si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN specifications JSONB;
        RAISE NOTICE '✅ Colonne specifications ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne specifications existe déjà dans la table devices';
    END IF;

    -- Ajouter created_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans la table devices';
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à la table devices';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans la table devices';
    END IF;
END $$;

-- 3. CRÉER LES INDEX NÉCESSAIRES
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_brand ON public.devices(brand);
CREATE INDEX IF NOT EXISTS idx_devices_type ON public.devices(type);

-- 4. ACTIVER RLS SI PAS DÉJÀ ACTIVÉ
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- 5. CRÉER LES POLITIQUES RLS SI MANQUANTES
DO $$
BEGIN
    -- Politique de lecture
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can view own devices'
    ) THEN
        CREATE POLICY "Users can view own devices" ON public.devices 
            FOR SELECT USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de lecture créée';
    END IF;

    -- Politique d'insertion
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can create own devices'
    ) THEN
        CREATE POLICY "Users can create own devices" ON public.devices 
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique d''insertion créée';
    END IF;

    -- Politique de mise à jour
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can update own devices'
    ) THEN
        CREATE POLICY "Users can update own devices" ON public.devices 
            FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de mise à jour créée';
    END IF;

    -- Politique de suppression
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'devices' 
            AND policyname = 'Users can delete own devices'
    ) THEN
        CREATE POLICY "Users can delete own devices" ON public.devices 
            FOR DELETE USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de suppression créée';
    END IF;
END $$;

-- 6. RAFRAÎCHIR LE CACHE POSTGREST (CRITIQUE)
NOTIFY pgrst, 'reload schema';

-- 7. ATTENDRE UN MOMENT POUR LA SYNCHRONISATION
SELECT pg_sleep(2);

-- 8. VÉRIFIER LA STRUCTURE FINALE
SELECT '=== STRUCTURE FINALE DEVICES ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

-- 9. TEST D'INSERTION COMPLET
DO $$
DECLARE
    test_device_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, utilisation d''un ID par défaut';
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Test d'insertion avec toutes les colonnes
    INSERT INTO public.devices (
        brand, model, serial_number, type, specifications, user_id
    ) VALUES (
        'Apple', 'iPhone 15', 'SN123456789', 'smartphone', '{"color": "black", "storage": "128GB"}', current_user_id
    ) RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Test d''insertion complet réussi. Device ID: %', test_device_id;
    
    -- Vérifier que l'appareil a été créé
    IF EXISTS (SELECT 1 FROM public.devices WHERE id = test_device_id) THEN
        RAISE NOTICE '✅ Appareil trouvé en base de données';
    ELSE
        RAISE NOTICE '❌ Appareil non trouvé en base de données';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT 'CORRECTION COMPLÈTE TERMINÉE' as status;
