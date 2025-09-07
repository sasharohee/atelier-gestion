-- =====================================================
-- CORRECTION NOUVEAUX COMPTES RÉPARATEURS
-- =====================================================
-- Script pour corriger les problèmes d'isolation
-- spécifiques aux nouveaux comptes de réparateurs
-- Date: 2025-01-23
-- =====================================================

-- 1. Nettoyer les données problématiques
SELECT '=== NETTOYAGE DONNÉES PROBLÉMATIQUES ===' as etape;

-- Supprimer les clients sans user_id valide
DELETE FROM clients 
WHERE user_id IS NULL 
   OR user_id = '00000000-0000-0000-0000-000000000000'::UUID
   OR user_id NOT IN (SELECT id FROM auth.users);

SELECT 'Clients problématiques supprimés' as resultat;

-- 2. Vérifier et corriger la structure de la table
SELECT '=== VÉRIFICATION STRUCTURE TABLE ===' as etape;

-- S'assurer que la colonne user_id existe et est correcte
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Rendre la colonne NOT NULL pour forcer l'isolation
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;

-- 3. Activer RLS de manière FORCÉE
SELECT '=== ACTIVATION RLS FORCÉE ===' as etape;

-- Désactiver temporairement RLS pour nettoyer
ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;

-- Réactiver RLS
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- 4. Supprimer TOUTES les politiques existantes
SELECT '=== NETTOYAGE COMPLET DES POLITIQUES ===' as etape;

-- Supprimer toutes les politiques possibles
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
DROP POLICY IF EXISTS "clients_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_all_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_rls_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_secure_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_select_ultra_strict" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_ultra_strict" ON public.clients;
DROP POLICY IF EXISTS "clients_update_ultra_strict" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_ultra_strict" ON public.clients;

-- 5. Créer des politiques RLS ULTRA-STRICTES
SELECT '=== CRÉATION POLITIQUES ULTRA-STRICTES ===' as etape;

-- Politique SELECT ultra-stricte
CREATE POLICY "clients_select_ultra_strict" ON public.clients
    FOR SELECT 
    USING (
        user_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND user_id IS NOT NULL
    );

-- Politique INSERT ultra-stricte
CREATE POLICY "clients_insert_ultra_strict" ON public.clients
    FOR INSERT 
    WITH CHECK (
        user_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND user_id IS NOT NULL
    );

-- Politique UPDATE ultra-stricte
CREATE POLICY "clients_update_ultra_strict" ON public.clients
    FOR UPDATE 
    USING (
        user_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND user_id IS NOT NULL
    )
    WITH CHECK (
        user_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND user_id IS NOT NULL
    );

-- Politique DELETE ultra-stricte
CREATE POLICY "clients_delete_ultra_strict" ON public.clients
    FOR DELETE 
    USING (
        user_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND user_id IS NOT NULL
    );

-- 6. Créer un trigger ultra-strict pour définir automatiquement user_id
SELECT '=== CRÉATION TRIGGER ULTRA-STRICT ===' as etape;

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS set_client_user_id_trigger ON public.clients;
DROP TRIGGER IF EXISTS set_client_user_id_ultra_strict_trigger ON public.clients;
DROP FUNCTION IF EXISTS set_client_user_id();
DROP FUNCTION IF EXISTS set_client_user_id_ultra_strict();

-- Fonction ultra-stricte pour clients
CREATE OR REPLACE FUNCTION set_client_user_id_ultra_strict()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer user_id à l'utilisateur connecté
    NEW.user_id := auth.uid();
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
CREATE TRIGGER set_client_user_id_ultra_strict_trigger
    BEFORE INSERT ON public.clients
    FOR EACH ROW EXECUTE FUNCTION set_client_user_id_ultra_strict();

-- 7. Créer une fonction pour initialiser les nouveaux comptes
SELECT '=== CRÉATION FONCTION INITIALISATION ===' as etape;

-- Fonction pour initialiser un nouveau compte de réparateur
CREATE OR REPLACE FUNCTION initialize_new_repairer_account(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id) THEN
        RAISE EXCEPTION 'Utilisateur non trouvé: %', user_id;
    END IF;
    
    -- Créer des données de démonstration pour le nouveau compte
    INSERT INTO clients (
        first_name, last_name, email, phone, address, user_id, created_by
    ) VALUES 
    (
        'Client', 'Démonstration', 'demo@example.com', '0123456789', '123 Rue de la Démo', user_id, user_id
    );
    
    RAISE NOTICE 'Compte initialisé pour l''utilisateur: %', user_id;
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Erreur lors de l''initialisation: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Test d'isolation pour les nouveaux comptes
SELECT '=== TEST ISOLATION NOUVEAUX COMPTES ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_insert_success BOOLEAN := FALSE;
    v_select_success BOOLEAN := FALSE;
    v_other_user_success BOOLEAN := FALSE;
BEGIN
    -- Créer un utilisateur de test
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '🧪 Test avec utilisateur fictif: %', v_test_user_id;
    
    -- Simuler la connexion de cet utilisateur
    PERFORM set_config('request.jwt.claims', '{"sub":"' || v_test_user_id || '"}', true);
    
    -- Test 1: Insérer un client
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address
        ) VALUES (
            'Test', 'NouveauCompte', 'test.nouveau@example.com', '0123456789', '123 Test Street'
        ) RETURNING id INTO v_test_client_id;
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Insertion réussie - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion: %', SQLERRM;
    END;
    
    -- Test 2: Vérifier que le client est visible
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            IF EXISTS (
                SELECT 1 FROM clients 
                WHERE id = v_test_client_id AND user_id = v_test_user_id
            ) THEN
                v_select_success := TRUE;
                RAISE NOTICE '✅ Client visible après insertion';
            ELSE
                RAISE NOTICE '❌ Client non visible après insertion';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
        END;
        
        -- Test 3: Vérifier qu'on ne peut pas voir les clients d'autres utilisateurs
        BEGIN
            IF EXISTS (
                SELECT 1 FROM clients 
                WHERE user_id != v_test_user_id
                LIMIT 1
            ) THEN
                v_other_user_success := TRUE;
                RAISE NOTICE '❌ PROBLÈME: Vous pouvez voir des clients d''autres utilisateurs';
            ELSE
                RAISE NOTICE '✅ Isolation parfaite: aucun client d''autre utilisateur visible';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors du test d''isolation: %', SQLERRM;
        END;
        
        -- Nettoyer le test
        DELETE FROM clients WHERE id = v_test_client_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
    -- Réinitialiser le contexte
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test pour nouveau compte:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Isolation: %', CASE WHEN NOT v_other_user_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 9. Vérification finale
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
        WHEN qual LIKE '%user_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict'
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '⚠️ Standard'
        ELSE '❌ Autre condition'
    END as type_isolation
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

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS ultra-strict activé' as message;
SELECT '✅ Politiques ultra-strictes créées' as politiques;
SELECT '✅ Trigger ultra-strict créé' as trigger;
SELECT '✅ Fonction d''initialisation créée' as fonction;
SELECT '✅ Données problématiques nettoyées' as nettoyage;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Isolation maximale appliquée pour nouveaux comptes' as note;
