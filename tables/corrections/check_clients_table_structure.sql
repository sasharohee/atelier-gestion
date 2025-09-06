-- =====================================================
-- VÉRIFICATION ET CORRECTION DE LA TABLE CLIENTS
-- =====================================================
-- Date: 2025-01-23
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

-- 2. AJOUTER LA COLONNE NOTES SI MANQUANTE
DO $$
BEGIN
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
END $$;

-- 3. RAFRAÎCHIR LE CACHE POSTGREST
NOTIFY pgrst, 'reload schema';

-- 4. VÉRIFIER LA STRUCTURE FINALE
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

-- 5. TEST D'INSERTION AVEC NOTES
DO $$
DECLARE
    test_client_id UUID;
BEGIN
    -- Test d'insertion avec notes
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, notes, user_id
    ) VALUES (
        'Test Notes', 'Client', 'test.notes@example.com', '0123456789', '123 Test St', 'Notes de test', auth.uid()
    ) RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Test d''insertion avec notes réussi. Client ID: %', test_client_id;
    
    -- Nettoyer le test
    DELETE FROM public.clients WHERE id = test_client_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;
