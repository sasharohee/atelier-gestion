-- =====================================================
-- CORRECTION COMPLÈTE DE LA TABLE CLIENTS
-- =====================================================
-- Date: 2025-01-23
-- Problème: "Could not find the 'notes' column of 'clients' in the schema cache"
-- =====================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
SELECT '=== STRUCTURE ACTUELLE CLIENTS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- 2. AJOUTER TOUTES LES COLONNES MANQUANTES
DO $$
BEGIN
    -- Ajouter user_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans la table clients';
    END IF;

    -- Ajouter first_name si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'first_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN first_name TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne first_name ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne first_name existe déjà dans la table clients';
    END IF;

    -- Ajouter last_name si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'last_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN last_name TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne last_name ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne last_name existe déjà dans la table clients';
    END IF;

    -- Ajouter email si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'email'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email TEXT NOT NULL DEFAULT '';
        RAISE NOTICE '✅ Colonne email ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne email existe déjà dans la table clients';
    END IF;

    -- Ajouter phone si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'phone'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN phone TEXT;
        RAISE NOTICE '✅ Colonne phone ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne phone existe déjà dans la table clients';
    END IF;

    -- Ajouter address si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'address'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN address TEXT;
        RAISE NOTICE '✅ Colonne address ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne address existe déjà dans la table clients';
    END IF;

    -- Ajouter notes si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN notes TEXT;
        RAISE NOTICE '✅ Colonne notes ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne notes existe déjà dans la table clients';
    END IF;

    -- Ajouter created_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans la table clients';
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à la table clients';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans la table clients';
    END IF;
END $$;

-- 3. CRÉER LES INDEX NÉCESSAIRES
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_email ON public.clients(email);

-- 4. ACTIVER RLS SI PAS DÉJÀ ACTIVÉ
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- 5. CRÉER LES POLITIQUES RLS SI MANQUANTES
DO $$
BEGIN
    -- Politique de lecture
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can view own clients'
    ) THEN
        CREATE POLICY "Users can view own clients" ON public.clients 
            FOR SELECT USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de lecture créée';
    END IF;

    -- Politique d'insertion
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can create own clients'
    ) THEN
        CREATE POLICY "Users can create own clients" ON public.clients 
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique d''insertion créée';
    END IF;

    -- Politique de mise à jour
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can update own clients'
    ) THEN
        CREATE POLICY "Users can update own clients" ON public.clients 
            FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de mise à jour créée';
    END IF;

    -- Politique de suppression
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'clients' 
            AND policyname = 'Users can delete own clients'
    ) THEN
        CREATE POLICY "Users can delete own clients" ON public.clients 
            FOR DELETE USING (auth.uid() = user_id);
        RAISE NOTICE '✅ Politique de suppression créée';
    END IF;
END $$;

-- 6. RAFRAÎCHIR LE CACHE POSTGREST (CRITIQUE)
NOTIFY pgrst, 'reload schema';

-- 7. ATTENDRE UN MOMENT POUR LA SYNCHRONISATION
SELECT pg_sleep(2);

-- 8. VÉRIFIER LA STRUCTURE FINALE
SELECT '=== STRUCTURE FINALE CLIENTS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- 9. TEST D'INSERTION COMPLET
DO $$
DECLARE
    test_client_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, utilisation d''un ID par défaut';
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Test d'insertion avec toutes les colonnes
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, notes, user_id
    ) VALUES (
        'Test Complet', 'Client', 'test.complet@example.com', '0123456789', '123 Test St', 'Notes de test complètes', current_user_id
    ) RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Test d''insertion complet réussi. Client ID: %', test_client_id;
    
    -- Vérifier que le client a été créé
    IF EXISTS (SELECT 1 FROM public.clients WHERE id = test_client_id) THEN
        RAISE NOTICE '✅ Client trouvé en base de données';
    ELSE
        RAISE NOTICE '❌ Client non trouvé en base de données';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM public.clients WHERE id = test_client_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT 'CORRECTION COMPLÈTE TERMINÉE' as status;
