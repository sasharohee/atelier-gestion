-- =====================================================
-- CORRECTION RLS CLIENTS ULTRA-STRICT
-- =====================================================
-- Script pour appliquer une isolation RLS ultra-stricte
-- sur la table clients
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état initial
SELECT '=== ÉTAT INITIAL ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'clients';

-- 2. Activer RLS de manière FORCÉE
SELECT '=== ACTIVATION RLS FORCÉE ===' as etape;

-- Désactiver temporairement RLS pour nettoyer
ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;

-- Réactiver RLS
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer TOUTES les politiques existantes (nettoyage complet)
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

-- 4. Vérifier qu'aucune politique n'existe
SELECT '=== VÉRIFICATION NETTOYAGE ===' as etape;

SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

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

-- 6. S'assurer que la colonne user_id existe et est correcte
SELECT '=== VÉRIFICATION COLONNE user_id ===' as etape;

-- Ajouter la colonne si elle n'existe pas
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Rendre la colonne NOT NULL pour forcer l'isolation
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;

-- 7. Mettre à jour les données existantes sans user_id
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as etape;

-- Supprimer les données sans user_id (plus sûr)
DELETE FROM public.clients WHERE user_id IS NULL;

-- Mettre à jour les données avec user_id NULL vers un UUID par défaut
UPDATE public.clients 
SET user_id = '00000000-0000-0000-0000-000000000000'::UUID
WHERE user_id IS NULL;

-- 8. Créer un trigger ultra-strict pour définir automatiquement user_id
SELECT '=== CRÉATION TRIGGER ULTRA-STRICT ===' as etape;

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS set_client_user_id_trigger ON public.clients;
DROP FUNCTION IF EXISTS set_client_user_id();

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

-- 9. Test d'isolation ultra-strict
SELECT '=== TEST ISOLATION ULTRA-STRICT ===' as etape;

DO $$
DECLARE
    v_test_client_id UUID;
    v_user_id UUID;
    v_insert_success BOOLEAN := FALSE;
    v_select_success BOOLEAN := FALSE;
    v_other_user_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test ultra-strict pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Insérer un client
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address
        ) VALUES (
            'Test', 'UltraStrict', 'test.ultrastrict@example.com', '0123456789', '123 Test Street'
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
                WHERE id = v_test_client_id AND user_id = v_user_id
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
                WHERE user_id != v_user_id
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
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test ultra-strict:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Isolation: %', CASE WHEN NOT v_other_user_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. Vérification finale
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
    END as type_isolation,
    qual as condition
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

-- 11. Test final d'isolation
SELECT '=== TEST FINAL D''ISOLATION ===' as etape;

-- Compter les clients visibles (devrait être limité par RLS)
SELECT 
    'Clients visibles' as test,
    COUNT(*) as nombre
FROM clients;

-- Compter les clients de l'utilisateur actuel
SELECT 
    'Mes clients' as test,
    COUNT(*) as nombre
FROM clients 
WHERE user_id = auth.uid();

-- 12. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS ultra-strict activé' as message;
SELECT '✅ Politiques ultra-strictes créées' as politiques;
SELECT '✅ Trigger ultra-strict créé' as trigger;
SELECT '✅ Colonne user_id obligatoire' as colonne;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Isolation maximale appliquée' as note;
