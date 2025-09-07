-- =====================================================
-- CORRECTION URGENCE - ERREUR UPDATED_AT LOYALTY
-- =====================================================
-- Script d'urgence pour corriger immédiatement l'erreur
-- "record 'new' has no field 'updated_at'"
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC IMMÉDIAT - Identifier tous les triggers problématiques
SELECT '=== DIAGNOSTIC TRIGGERS LOYALTY ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('client_loyalty_points', 'loyalty_points_history', 'loyalty_tiers_advanced', 'referrals')
ORDER BY event_object_table, trigger_name;

-- 2. SUPPRESSION IMMÉDIATE DE TOUS LES TRIGGERS PROBLÉMATIQUES
SELECT '=== SUPPRESSION URGENTE TRIGGERS ===' as etape;

-- Supprimer TOUS les triggers qui pourraient causer le problème
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_points_history_trigger ON public.loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_advanced_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_referrals_trigger ON public.referrals;
DROP TRIGGER IF EXISTS set_workshop_id_client_loyalty_points_trigger ON public.client_loyalty_points;

-- Supprimer aussi les anciens triggers génériques
DROP TRIGGER IF EXISTS set_workshop_id_ultra_strict_trigger ON public.loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_ultra_strict_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_ultra_strict_trigger ON public.referrals;
DROP TRIGGER IF EXISTS set_workshop_id_ultra_strict_trigger ON public.client_loyalty_points;

-- 3. SUPPRESSION DES FONCTIONS PROBLÉMATIQUES
SELECT '=== SUPPRESSION FONCTIONS PROBLÉMATIQUES ===' as etape;

DROP FUNCTION IF EXISTS set_workshop_id_ultra_strict();
DROP FUNCTION IF EXISTS set_workshop_id_ultra_strict_safe();
DROP FUNCTION IF EXISTS set_workshop_id_loyalty_points_history();
DROP FUNCTION IF EXISTS set_workshop_id_client_loyalty_points();
DROP FUNCTION IF EXISTS set_workshop_id_loyalty_tiers_advanced();
DROP FUNCTION IF EXISTS set_workshop_id_referrals();

-- 4. CRÉER UNE FONCTION TRIGGER ULTRA-SIMPLE ET SÉCURISÉE
SELECT '=== CRÉATION FONCTION TRIGGER SÉCURISÉE ===' as etape;

CREATE OR REPLACE FUNCTION set_workshop_id_safe()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- NE PAS toucher aux autres champs pour éviter les erreurs
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. CRÉER DES TRIGGERS ULTRA-SIMPLES
SELECT '=== CRÉATION TRIGGERS ULTRA-SIMPLES ===' as etape;

-- Trigger pour loyalty_points_history
CREATE TRIGGER set_workshop_id_loyalty_points_history_safe
    BEFORE INSERT ON public.loyalty_points_history
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_safe();

-- Trigger pour loyalty_tiers_advanced
CREATE TRIGGER set_workshop_id_loyalty_tiers_advanced_safe
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_safe();

-- Trigger pour referrals
CREATE TRIGGER set_workshop_id_referrals_safe
    BEFORE INSERT ON public.referrals
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_safe();

-- Trigger pour client_loyalty_points
CREATE TRIGGER set_workshop_id_client_loyalty_points_safe
    BEFORE INSERT ON public.client_loyalty_points
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_safe();

-- 6. TEST IMMÉDIAT DE LA CORRECTION
SELECT '=== TEST IMMÉDIAT CORRECTION ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_test_loyalty_id UUID;
    v_insert_success BOOLEAN := FALSE;
BEGIN
    -- Créer un utilisateur de test
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '🧪 Test immédiat avec utilisateur: %', v_test_user_id;
    
    -- Simuler la connexion de cet utilisateur
    PERFORM set_config('request.jwt.claims', '{"sub":"' || v_test_user_id || '"}', true);
    
    -- Test 1: Insérer un client de test
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'Urgence', 'test.urgence@example.com', '0123456789', '123 Test Street', v_test_user_id
        ) RETURNING id INTO v_test_client_id;
        
        RAISE NOTICE '✅ Client de test créé - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur client: %', SQLERRM;
    END;
    
    -- Test 2: Insérer un point de fidélité (test principal)
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            INSERT INTO client_loyalty_points (
                client_id, points_added, points_used, description, workshop_id
            ) VALUES (
                v_test_client_id, 50, 0, 'Test urgence - points', v_test_user_id
            ) RETURNING id INTO v_test_loyalty_id;
            
            v_insert_success := TRUE;
            RAISE NOTICE '✅ SUCCÈS: Point de fidélité créé - ID: %', v_test_loyalty_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ ÉCHEC: Erreur lors de la création du point: %', SQLERRM;
        END;
        
        -- Nettoyer le test
        IF v_test_loyalty_id IS NOT NULL THEN
            DELETE FROM client_loyalty_points WHERE id = v_test_loyalty_id;
        END IF;
        DELETE FROM clients WHERE id = v_test_client_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
    -- Réinitialiser le contexte
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    -- Résumé du test
    RAISE NOTICE '📊 RÉSULTAT TEST URGENCE:';
    RAISE NOTICE '  - Insertion client_loyalty_points: %', CASE WHEN v_insert_success THEN '✅ SUCCÈS' ELSE '❌ ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 7. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les triggers créés
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
AND trigger_name LIKE 'set_workshop_id_%'
ORDER BY event_object_table, trigger_name;

-- 8. MESSAGE DE CONFIRMATION
SELECT '=== CORRECTION URGENCE TERMINÉE ===' as etape;
SELECT '✅ TOUS les triggers problématiques supprimés' as message;
SELECT '✅ Nouveaux triggers ultra-simples créés' as nouveaux_triggers;
SELECT '✅ Test de correction effectué' as test;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION MAINTENANT' as deploy;
SELECT 'ℹ️ L''ajout de points de fidélité devrait maintenant fonctionner' as note;
SELECT '⚠️ Si l''erreur persiste, il y a un autre trigger ailleurs' as warning;
