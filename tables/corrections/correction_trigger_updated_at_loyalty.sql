-- =====================================================
-- CORRECTION TRIGGER UPDATED_AT LOYALTY POINTS
-- =====================================================
-- Script pour corriger l'erreur "record 'new' has no field 'updated_at'"
-- dans les triggers de fidélité
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier la structure des tables de fidélité
SELECT '=== VÉRIFICATION STRUCTURE TABLES FIDÉLITÉ ===' as etape;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('client_loyalty_points', 'loyalty_points_history', 'loyalty_tiers_advanced', 'referrals')
AND column_name IN ('created_at', 'updated_at', 'workshop_id')
ORDER BY table_name, column_name;

-- 2. Créer une fonction trigger corrigée qui vérifie l'existence des champs
CREATE OR REPLACE FUNCTION set_workshop_id_ultra_strict_safe()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir created_at seulement s'il existe
    IF TG_TABLE_NAME = 'client_loyalty_points' OR 
       TG_TABLE_NAME = 'loyalty_points_history' OR 
       TG_TABLE_NAME = 'loyalty_tiers_advanced' OR 
       TG_TABLE_NAME = 'referrals' THEN
        
        -- Vérifier si created_at existe et le définir
        BEGIN
            NEW.created_at := COALESCE(NEW.created_at, NOW());
        EXCEPTION WHEN undefined_column THEN
            -- Le champ n'existe pas, on continue
            NULL;
        END;
        
        -- Vérifier si updated_at existe et le définir
        BEGIN
            NEW.updated_at := NOW();
        EXCEPTION WHEN undefined_column THEN
            -- Le champ n'existe pas, on continue
            NULL;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Alternative plus simple : fonction spécifique par table
CREATE OR REPLACE FUNCTION set_workshop_id_loyalty_points_history()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps (cette table a les deux champs)
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_workshop_id_client_loyalty_points()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir created_at seulement (cette table n'a pas updated_at)
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_workshop_id_loyalty_tiers_advanced()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps (cette table a les deux champs)
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_workshop_id_referrals()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir created_at seulement (cette table n'a pas updated_at)
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Supprimer les anciens triggers
SELECT '=== SUPPRESSION ANCIENS TRIGGERS ===' as etape;

DROP TRIGGER IF EXISTS set_workshop_id_loyalty_points_history_trigger ON public.loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_advanced_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_referrals_trigger ON public.referrals;
DROP TRIGGER IF EXISTS set_workshop_id_client_loyalty_points_trigger ON public.client_loyalty_points;

-- 5. Créer les nouveaux triggers avec les fonctions spécifiques
SELECT '=== CRÉATION NOUVEAUX TRIGGERS ===' as etape;

-- Trigger pour loyalty_points_history
CREATE TRIGGER set_workshop_id_loyalty_points_history_trigger
    BEFORE INSERT ON public.loyalty_points_history
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_loyalty_points_history();

-- Trigger pour loyalty_tiers_advanced
CREATE TRIGGER set_workshop_id_loyalty_tiers_advanced_trigger
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_loyalty_tiers_advanced();

-- Trigger pour referrals
CREATE TRIGGER set_workshop_id_referrals_trigger
    BEFORE INSERT ON public.referrals
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_referrals();

-- Trigger pour client_loyalty_points
CREATE TRIGGER set_workshop_id_client_loyalty_points_trigger
    BEFORE INSERT ON public.client_loyalty_points
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_client_loyalty_points();

-- 6. Test de la correction
SELECT '=== TEST DE LA CORRECTION ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_test_loyalty_id UUID;
    v_insert_success BOOLEAN := FALSE;
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
    
    -- Test 2: Insérer un point de fidélité dans client_loyalty_points
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            INSERT INTO client_loyalty_points (
                client_id, points_added, points_used, description, workshop_id
            ) VALUES (
                v_test_client_id, 100, 0, 'Test de points corrigé', v_test_user_id
            ) RETURNING id INTO v_test_loyalty_id;
            
            v_insert_success := TRUE;
            RAISE NOTICE '✅ Point de fidélité créé dans client_loyalty_points - ID: %', v_test_loyalty_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de la création du point: %', SQLERRM;
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
    RAISE NOTICE '📊 Résumé du test de correction:';
    RAISE NOTICE '  - Insertion client_loyalty_points: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 7. Vérification finale
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

-- 8. Message de confirmation
SELECT '=== CORRECTION TERMINÉE ===' as etape;
SELECT '✅ Triggers corrigés pour éviter l''erreur updated_at' as message;
SELECT '✅ Fonctions spécifiques créées pour chaque table' as fonctions;
SELECT '✅ Test de correction effectué' as test;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ L''ajout de points de fidélité devrait maintenant fonctionner' as note;
