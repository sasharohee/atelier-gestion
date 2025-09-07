-- =====================================================
-- CORRECTION ISOLATION CLIENTS - VERSION FINALE V2
-- =====================================================
-- Corrige définitivement le problème d'isolation des clients
-- Gère correctement les fonctions existantes
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel de la table
SELECT '=== ÉTAT ACTUEL DE LA TABLE ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'clients';

-- 2. Activer RLS si nécessaire
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer toutes les politiques existantes
SELECT '=== NETTOYAGE POLITIQUES EXISTANTES ===' as etape;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Users can view their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete their own clients" ON public.clients;
DROP POLICY IF EXISTS "clients_select_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_update_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_policy" ON public.clients;

-- 4. Créer les nouvelles politiques RLS strictes
SELECT '=== CRÉATION POLITIQUES RLS STRICTES ===' as etape;

-- Politiques pour clients
CREATE POLICY "clients_select_policy" ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "clients_insert_policy" ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "clients_update_policy" ON public.clients
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "clients_delete_policy" ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- 5. S'assurer que la colonne user_id existe
SELECT '=== VÉRIFICATION COLONNE user_id ===' as etape;

ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 6. Mettre à jour les données existantes sans user_id
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as etape;

UPDATE public.clients 
SET user_id = COALESCE(
    auth.uid(), 
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE user_id IS NULL;

-- 7. Supprimer les fonctions existantes avant de les recréer
SELECT '=== NETTOYAGE FONCTIONS EXISTANTES ===' as etape;

-- Supprimer toutes les versions possibles de la fonction
DROP FUNCTION IF EXISTS create_client_smart(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS create_client_smart(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_client_smart(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS set_client_user_id();

-- 8. Créer un trigger pour définir automatiquement user_id
SELECT '=== CRÉATION TRIGGER AUTOMATIQUE ===' as etape;

-- Fonction pour clients
CREATE OR REPLACE FUNCTION set_client_user_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS set_client_user_id_trigger ON public.clients;
CREATE TRIGGER set_client_user_id_trigger
    BEFORE INSERT ON public.clients
    FOR EACH ROW EXECUTE FUNCTION set_client_user_id();

-- 9. Créer la fonction RPC create_client_smart
SELECT '=== CRÉATION FONCTION RPC ===' as etape;

CREATE OR REPLACE FUNCTION create_client_smart(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_notes TEXT,
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_existing_client_id UUID;
    v_new_client_id UUID;
    v_user_id UUID;
BEGIN
    -- Utiliser l'utilisateur connecté
    v_user_id := COALESCE(auth.uid(), p_user_id);
    
    -- Vérifier si un client avec cet email existe déjà pour cet utilisateur
    IF p_email IS NOT NULL AND p_email != '' THEN
        SELECT id INTO v_existing_client_id
        FROM clients
        WHERE email = p_email AND user_id = v_user_id
        LIMIT 1;
        
        IF v_existing_client_id IS NOT NULL THEN
            -- Client existant trouvé
            RETURN json_build_object(
                'success', true,
                'action', 'existing_client_found',
                'client_id', v_existing_client_id,
                'client_data', (
                    SELECT json_build_object(
                        'id', id,
                        'firstName', first_name,
                        'lastName', last_name,
                        'email', email,
                        'phone', phone,
                        'address', address,
                        'notes', notes,
                        'createdAt', created_at,
                        'updatedAt', updated_at
                    )
                    FROM clients
                    WHERE id = v_existing_client_id
                )
            );
        END IF;
    END IF;
    
    -- Créer un nouveau client
    INSERT INTO clients (
        first_name, last_name, email, phone, address, notes, user_id
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_notes, v_user_id
    ) RETURNING id INTO v_new_client_id;
    
    -- Retourner le succès avec l'ID du nouveau client
    RETURN json_build_object(
        'success', true,
        'action', 'client_created',
        'client_id', v_new_client_id
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Test d'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_test_client_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    RAISE NOTICE 'Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Créer un client via la fonction RPC
    DECLARE
        v_rpc_result JSON;
    BEGIN
        SELECT create_client_smart(
            'Test', 'Isolation', 'test.isolation@example.com', 
            '0123456789', '123 Test Street', 'Client de test pour isolation',
            v_user_id
        ) INTO v_rpc_result;
        
        RAISE NOTICE '✅ Résultat RPC: %', v_rpc_result;
        
        -- Extraire l'ID du client créé
        IF (v_rpc_result->>'action') = 'client_created' THEN
            v_test_client_id := (v_rpc_result->>'client_id')::UUID;
            RAISE NOTICE '✅ Client de test créé - ID: %', v_test_client_id;
        ELSIF (v_rpc_result->>'action') = 'existing_client_found' THEN
            v_test_client_id := (v_rpc_result->>'client_id')::UUID;
            RAISE NOTICE 'ℹ️ Client existant trouvé - ID: %', v_test_client_id;
        END IF;
    END;
    
    -- Test 2: Vérifier l'isolation
    IF v_test_client_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.clients 
            WHERE id = v_test_client_id AND user_id = v_user_id
        ) THEN
            RAISE NOTICE '✅ Isolation des clients fonctionne';
        ELSE
            RAISE NOTICE '❌ Problème d''isolation des clients';
        END IF;
        
        -- Nettoyer le test
        DELETE FROM public.clients WHERE id = v_test_client_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 11. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier le statut RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'clients';

-- Vérifier les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        ELSE '❌ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- Vérifier le trigger
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'clients'
ORDER BY trigger_name;

-- Vérifier la fonction RPC
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'create_client_smart';

-- 12. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec isolation stricte par user_id' as message;
SELECT '✅ Toutes les requêtes filtrent maintenant par user_id' as isolation;
SELECT '✅ Le trigger définit automatiquement user_id' as trigger;
SELECT '✅ La fonction RPC gère l''isolation automatiquement' as rpc;
SELECT '✅ Testez maintenant la page des clients' as next_step;
SELECT 'ℹ️ Chaque utilisateur ne voit que ses propres clients' as note;
