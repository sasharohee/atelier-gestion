-- =====================================================
-- CORRECTION ISOLATION POINTS DE FIDÉLITÉ COMPLÈTE
-- =====================================================
-- Script pour corriger l'isolation des données
-- dans toutes les tables liées aux points de fidélité
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état initial des tables de fidélité
SELECT '=== ÉTAT INITIAL TABLES FIDÉLITÉ ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename;

-- 2. Analyser les contraintes de clés étrangères pour les tables de fidélité
SELECT '=== CONTRAINTES CLÉS ÉTRANGÈRES FIDÉLITÉ ===' as etape;

SELECT 
    tc.table_name as table_cible,
    kcu.column_name as colonne_cible,
    ccu.table_name AS table_source,
    ccu.column_name AS colonne_source,
    tc.constraint_name as nom_contrainte
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND (ccu.table_name = 'clients' OR tc.table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points'))
ORDER BY tc.table_name, kcu.column_name;

-- 3. S'assurer que les colonnes workshop_id existent AVANT tout nettoyage
SELECT '=== CRÉATION COLONNES WORKSHOP_ID ===' as etape;

-- Ajouter workshop_id à loyalty_points_history si elle n'existe pas
ALTER TABLE public.loyalty_points_history ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Ajouter workshop_id à loyalty_tiers_advanced si elle n'existe pas
ALTER TABLE public.loyalty_tiers_advanced ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Ajouter workshop_id à referrals si elle n'existe pas
ALTER TABLE public.referrals ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Ajouter workshop_id à client_loyalty_points si elle n'existe pas
ALTER TABLE public.client_loyalty_points ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

SELECT 'Colonnes workshop_id créées ou vérifiées' as resultat;

-- 4. Nettoyer les données problématiques de manière sécurisée
SELECT '=== NETTOYAGE DONNÉES PROBLÉMATIQUES SÉCURISÉ ===' as etape;

-- Désactiver temporairement les contraintes de clés étrangères
SET session_replication_role = replica;

-- Supprimer les données orphelines dans loyalty_points_history
DELETE FROM loyalty_points_history 
WHERE client_id IS NULL 
   OR client_id NOT IN (SELECT id FROM clients);

-- Supprimer les données orphelines dans referrals
DELETE FROM referrals 
WHERE referrer_client_id IS NULL 
   OR referrer_client_id NOT IN (SELECT id FROM clients)
   OR referred_client_id IS NULL 
   OR referred_client_id NOT IN (SELECT id FROM clients);

-- Supprimer les données orphelines dans client_loyalty_points
DELETE FROM client_loyalty_points 
WHERE client_id IS NULL 
   OR client_id NOT IN (SELECT id FROM clients);

-- Réactiver les contraintes de clés étrangères
SET session_replication_role = DEFAULT;

SELECT 'Données orphelines supprimées des tables de fidélité' as resultat;

-- 4. Activer RLS sur toutes les tables de fidélité
SELECT '=== ACTIVATION RLS TABLES FIDÉLITÉ ===' as etape;

-- Activer RLS sur loyalty_points_history
ALTER TABLE public.loyalty_points_history ENABLE ROW LEVEL SECURITY;

-- Activer RLS sur loyalty_tiers_advanced
ALTER TABLE public.loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;

-- Activer RLS sur referrals
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- Activer RLS sur client_loyalty_points
ALTER TABLE public.client_loyalty_points ENABLE ROW LEVEL SECURITY;

-- 5. Supprimer toutes les politiques existantes sur les tables de fidélité
SELECT '=== NETTOYAGE POLITIQUES FIDÉLITÉ ===' as etape;

-- Supprimer les politiques sur loyalty_points_history
DROP POLICY IF EXISTS "loyalty_points_history_select_policy" ON public.loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_insert_policy" ON public.loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_update_policy" ON public.loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_delete_policy" ON public.loyalty_points_history;

-- Supprimer les politiques sur loyalty_tiers_advanced
DROP POLICY IF EXISTS "loyalty_tiers_advanced_select_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_insert_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_update_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_delete_policy" ON public.loyalty_tiers_advanced;

-- Supprimer les politiques sur referrals
DROP POLICY IF EXISTS "referrals_select_policy" ON public.referrals;
DROP POLICY IF EXISTS "referrals_insert_policy" ON public.referrals;
DROP POLICY IF EXISTS "referrals_update_policy" ON public.referrals;
DROP POLICY IF EXISTS "referrals_delete_policy" ON public.referrals;

-- Supprimer les politiques sur client_loyalty_points
DROP POLICY IF EXISTS "client_loyalty_points_select_policy" ON public.client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_insert_policy" ON public.client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_update_policy" ON public.client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_delete_policy" ON public.client_loyalty_points;

-- 6. Créer des politiques RLS ultra-strictes pour loyalty_points_history
SELECT '=== CRÉATION POLITIQUES LOYALTY_POINTS_HISTORY ===' as etape;

CREATE POLICY "loyalty_points_history_select_ultra_strict" ON public.loyalty_points_history
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_points_history_insert_ultra_strict" ON public.loyalty_points_history
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_points_history_update_ultra_strict" ON public.loyalty_points_history
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_points_history_delete_ultra_strict" ON public.loyalty_points_history
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- 7. Créer des politiques RLS ultra-strictes pour loyalty_tiers_advanced
SELECT '=== CRÉATION POLITIQUES LOYALTY_TIERS_ADVANCED ===' as etape;

CREATE POLICY "loyalty_tiers_advanced_select_ultra_strict" ON public.loyalty_tiers_advanced
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_advanced_insert_ultra_strict" ON public.loyalty_tiers_advanced
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_advanced_update_ultra_strict" ON public.loyalty_tiers_advanced
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_advanced_delete_ultra_strict" ON public.loyalty_tiers_advanced
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- 8. Créer des politiques RLS ultra-strictes pour referrals
SELECT '=== CRÉATION POLITIQUES REFERRALS ===' as etape;

CREATE POLICY "referrals_select_ultra_strict" ON public.referrals
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "referrals_insert_ultra_strict" ON public.referrals
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "referrals_update_ultra_strict" ON public.referrals
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "referrals_delete_ultra_strict" ON public.referrals
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- 9. Créer des politiques RLS ultra-strictes pour client_loyalty_points
SELECT '=== CRÉATION POLITIQUES CLIENT_LOYALTY_POINTS ===' as etape;

CREATE POLICY "client_loyalty_points_select_ultra_strict" ON public.client_loyalty_points
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "client_loyalty_points_insert_ultra_strict" ON public.client_loyalty_points
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "client_loyalty_points_update_ultra_strict" ON public.client_loyalty_points
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "client_loyalty_points_delete_ultra_strict" ON public.client_loyalty_points
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- 10. Vérifier que les colonnes workshop_id existent
SELECT '=== VÉRIFICATION COLONNES WORKSHOP_ID ===' as etape;

-- Vérifier que les colonnes existent
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
AND column_name = 'workshop_id'
ORDER BY table_name;

-- 11. Créer des triggers pour définir automatiquement workshop_id
SELECT '=== CRÉATION TRIGGERS WORKSHOP_ID ===' as etape;

-- Fonction pour définir workshop_id automatiquement
CREATE OR REPLACE FUNCTION set_workshop_id_ultra_strict()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_points_history_trigger ON public.loyalty_points_history;
CREATE TRIGGER set_workshop_id_loyalty_points_history_trigger
    BEFORE INSERT ON public.loyalty_points_history
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_ultra_strict();

DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_advanced_trigger ON public.loyalty_tiers_advanced;
CREATE TRIGGER set_workshop_id_loyalty_tiers_advanced_trigger
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_ultra_strict();

DROP TRIGGER IF EXISTS set_workshop_id_referrals_trigger ON public.referrals;
CREATE TRIGGER set_workshop_id_referrals_trigger
    BEFORE INSERT ON public.referrals
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_ultra_strict();

DROP TRIGGER IF EXISTS set_workshop_id_client_loyalty_points_trigger ON public.client_loyalty_points;
CREATE TRIGGER set_workshop_id_client_loyalty_points_trigger
    BEFORE INSERT ON public.client_loyalty_points
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_ultra_strict();

-- 12. Test d'isolation pour les tables de fidélité
SELECT '=== TEST ISOLATION TABLES FIDÉLITÉ ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_test_loyalty_id UUID;
    v_insert_success BOOLEAN := FALSE;
    v_select_success BOOLEAN := FALSE;
    v_other_user_success BOOLEAN := FALSE;
BEGIN
    -- Créer un utilisateur de test
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '🧪 Test avec utilisateur fictif: %', v_test_user_id;
    
    -- Simuler la connexion de cet utilisateur
    PERFORM set_config('request.jwt.claims', '{"sub":"' || v_test_user_id || '"}', true);
    
    -- Test 1: Insérer un client de test
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'Loyalty', 'test.loyalty@example.com', '0123456789', '123 Test Street', v_test_user_id
        ) RETURNING id INTO v_test_client_id;
        
        RAISE NOTICE '✅ Client de test créé - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la création du client: %', SQLERRM;
    END;
    
    -- Test 2: Insérer un point de fidélité
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            INSERT INTO loyalty_points_history (
                client_id, points_change, description, type, workshop_id
            ) VALUES (
                v_test_client_id, 100, 'Test de points', 'earned', v_test_user_id
            ) RETURNING id INTO v_test_loyalty_id;
            
            v_insert_success := TRUE;
            RAISE NOTICE '✅ Point de fidélité créé - ID: %', v_test_loyalty_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de la création du point: %', SQLERRM;
        END;
        
        -- Test 3: Vérifier que le point est visible
        IF v_test_loyalty_id IS NOT NULL THEN
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM loyalty_points_history 
                    WHERE id = v_test_loyalty_id AND workshop_id = v_test_user_id
                ) THEN
                    v_select_success := TRUE;
                    RAISE NOTICE '✅ Point de fidélité visible après insertion';
                ELSE
                    RAISE NOTICE '❌ Point de fidélité non visible après insertion';
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
            END;
            
            -- Test 4: Vérifier qu'on ne peut pas voir les points d'autres utilisateurs
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM loyalty_points_history 
                    WHERE workshop_id != v_test_user_id
                    LIMIT 1
                ) THEN
                    v_other_user_success := TRUE;
                    RAISE NOTICE '❌ PROBLÈME: Vous pouvez voir des points d''autres utilisateurs';
                ELSE
                    RAISE NOTICE '✅ Isolation parfaite: aucun point d''autre utilisateur visible';
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Erreur lors du test d''isolation: %', SQLERRM;
            END;
            
            -- Nettoyer le test
            DELETE FROM loyalty_points_history WHERE id = v_test_loyalty_id;
            DELETE FROM clients WHERE id = v_test_client_id;
            RAISE NOTICE '✅ Test nettoyé';
        END IF;
    END IF;
    
    -- Réinitialiser le contexte
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test pour points de fidélité:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Isolation: %', CASE WHEN NOT v_other_user_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 13. Vérification finale
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
AND tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict'
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '⚠️ Standard'
        ELSE '❌ Autre condition'
    END as type_isolation
FROM pg_policies 
WHERE tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename, policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY event_object_table, trigger_name;

-- 14. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS ultra-strict activé sur toutes les tables de fidélité' as message;
SELECT '✅ Politiques ultra-strictes créées' as politiques;
SELECT '✅ Triggers ultra-stricts créés' as triggers;
SELECT '✅ Données orphelines nettoyées' as nettoyage;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Isolation maximale appliquée aux points de fidélité' as note;
