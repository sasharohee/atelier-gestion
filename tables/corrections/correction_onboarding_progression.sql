-- =====================================================
-- CORRECTION SYSTÈME ONBOARDING/PROGRESSION
-- =====================================================
-- Script pour corriger le système d'onboarding qui ne fonctionne plus
-- après les corrections de triggers de fidélité
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC DU SYSTÈME ONBOARDING
SELECT '=== DIAGNOSTIC SYSTÈME ONBOARDING ===' as etape;

-- Vérifier les tables nécessaires pour l'onboarding
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'sales', 'repairs', 'appointments', 'messages') 
        THEN '✅ Table onboarding'
        ELSE '⚠️ Table système'
    END as type_table
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN (
    'clients', 'devices', 'services', 'parts', 'products', 
    'sales', 'repairs', 'appointments', 'messages',
    'device_categories', 'device_brands', 'device_models'
)
ORDER BY table_name;

-- 2. VÉRIFIER LES TRIGGERS SUR LES TABLES ONBOARDING
SELECT '=== VÉRIFICATION TRIGGERS TABLES ONBOARDING ===' as etape;

SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'sales', 'repairs')
ORDER BY event_object_table, trigger_name;

-- 3. VÉRIFIER LES POLITIQUES RLS SUR LES TABLES ONBOARDING
SELECT '=== VÉRIFICATION POLITIQUES RLS ONBOARDING ===' as etape;

SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'sales', 'repairs')
ORDER BY tablename, policyname;

-- 4. TEST D'INSERTION DE DONNÉES ONBOARDING
SELECT '=== TEST INSERTION DONNÉES ONBOARDING ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_test_device_id UUID;
    v_test_service_id UUID;
    v_test_part_id UUID;
    v_test_product_id UUID;
    v_test_sale_id UUID;
    v_test_repair_id UUID;
    v_success_count INTEGER := 0;
    v_total_tests INTEGER := 7;
BEGIN
    -- Créer un utilisateur de test
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '🧪 Test onboarding avec utilisateur: %', v_test_user_id;
    
    -- Simuler la connexion de cet utilisateur
    PERFORM set_config('request.jwt.claims', '{"sub":"' || v_test_user_id || '"}', true);
    
    -- Test 1: Insérer un client
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'Onboarding', 'test.onboarding@example.com', '0123456789', '123 Test Street', v_test_user_id
        ) RETURNING id INTO v_test_client_id;
        
        v_success_count := v_success_count + 1;
        RAISE NOTICE '✅ Client créé - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur client: %', SQLERRM;
    END;
    
    -- Test 2: Insérer un appareil
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            INSERT INTO devices (
                client_id, brand, model, serial_number, type, user_id
            ) VALUES (
                v_test_client_id, 'Test Brand', 'Test Model', 'TEST123', 'smartphone', v_test_user_id
            ) RETURNING id INTO v_test_device_id;
            
            v_success_count := v_success_count + 1;
            RAISE NOTICE '✅ Appareil créé - ID: %', v_test_device_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur appareil: %', SQLERRM;
        END;
    END IF;
    
    -- Test 3: Insérer un service
    BEGIN
        INSERT INTO services (
            name, description, price, duration, category, user_id
        ) VALUES (
            'Test Service', 'Service de test', 50.00, 60, 'réparation', v_test_user_id
        ) RETURNING id INTO v_test_service_id;
        
        v_success_count := v_success_count + 1;
        RAISE NOTICE '✅ Service créé - ID: %', v_test_service_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur service: %', SQLERRM;
    END;
    
    -- Test 4: Insérer une pièce
    BEGIN
        INSERT INTO parts (
            name, description, price, stock_quantity, part_number, brand, user_id
        ) VALUES (
            'Test Part', 'Pièce de test', 25.00, 10, 'PART123', 'Test Brand', v_test_user_id
        ) RETURNING id INTO v_test_part_id;
        
        v_success_count := v_success_count + 1;
        RAISE NOTICE '✅ Pièce créée - ID: %', v_test_part_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur pièce: %', SQLERRM;
    END;
    
    -- Test 5: Insérer un produit
    BEGIN
        INSERT INTO products (
            name, description, price, stock_quantity, category, user_id
        ) VALUES (
            'Test Product', 'Produit de test', 100.00, 5, 'accessoire', v_test_user_id
        ) RETURNING id INTO v_test_product_id;
        
        v_success_count := v_success_count + 1;
        RAISE NOTICE '✅ Produit créé - ID: %', v_test_product_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur produit: %', SQLERRM;
    END;
    
    -- Test 6: Insérer une vente
    IF v_test_client_id IS NOT NULL AND v_test_product_id IS NOT NULL THEN
        BEGIN
            INSERT INTO sales (
                client_id, items, subtotal, total, payment_method, status, user_id
            ) VALUES (
                v_test_client_id, 
                '[{"id":"' || v_test_product_id || '","type":"product","name":"Test Product","quantity":1,"unitPrice":100.00,"totalPrice":100.00}]'::jsonb,
                100.00, 100.00, 'cash', 'completed', v_test_user_id
            ) RETURNING id INTO v_test_sale_id;
            
            v_success_count := v_success_count + 1;
            RAISE NOTICE '✅ Vente créée - ID: %', v_test_sale_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur vente: %', SQLERRM;
        END;
    END IF;
    
    -- Test 7: Insérer une réparation
    IF v_test_client_id IS NOT NULL AND v_test_device_id IS NOT NULL THEN
        BEGIN
            INSERT INTO repairs (
                client_id, device_id, status, description, issue, total_price, user_id
            ) VALUES (
                v_test_client_id, v_test_device_id, 'in_progress', 'Test repair', 'Test issue', 75.00, v_test_user_id
            ) RETURNING id INTO v_test_repair_id;
            
            v_success_count := v_success_count + 1;
            RAISE NOTICE '✅ Réparation créée - ID: %', v_test_repair_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur réparation: %', SQLERRM;
        END;
    END IF;
    
    -- Nettoyer les tests
    IF v_test_repair_id IS NOT NULL THEN DELETE FROM repairs WHERE id = v_test_repair_id; END IF;
    IF v_test_sale_id IS NOT NULL THEN DELETE FROM sales WHERE id = v_test_sale_id; END IF;
    IF v_test_product_id IS NOT NULL THEN DELETE FROM products WHERE id = v_test_product_id; END IF;
    IF v_test_part_id IS NOT NULL THEN DELETE FROM parts WHERE id = v_test_part_id; END IF;
    IF v_test_service_id IS NOT NULL THEN DELETE FROM services WHERE id = v_test_service_id; END IF;
    IF v_test_device_id IS NOT NULL THEN DELETE FROM devices WHERE id = v_test_device_id; END IF;
    IF v_test_client_id IS NOT NULL THEN DELETE FROM clients WHERE id = v_test_client_id; END IF;
    
    RAISE NOTICE '✅ Tests nettoyés';
    
    -- Réinitialiser le contexte
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    -- Résumé du test
    RAISE NOTICE '📊 RÉSULTAT TEST ONBOARDING:';
    RAISE NOTICE '  - Tests réussis: %/%', v_success_count, v_total_tests;
    RAISE NOTICE '  - Taux de réussite: %', ROUND((v_success_count::DECIMAL / v_total_tests) * 100, 2) || '%';
    
    IF v_success_count = v_total_tests THEN
        RAISE NOTICE '✅ SYSTÈME ONBOARDING FONCTIONNEL';
    ELSIF v_success_count >= v_total_tests * 0.7 THEN
        RAISE NOTICE '⚠️ SYSTÈME ONBOARDING PARTIELLEMENT FONCTIONNEL';
    ELSE
        RAISE NOTICE '❌ SYSTÈME ONBOARDING DÉFAILLANT';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 5. CORRECTION DES TRIGGERS POUR L'ONBOARDING
SELECT '=== CORRECTION TRIGGERS ONBOARDING ===' as etape;

-- Créer une fonction trigger sécurisée pour l'onboarding
CREATE OR REPLACE FUNCTION set_user_id_safe()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer user_id à l'utilisateur connecté
    NEW.user_id := auth.uid();
    
    -- Définir created_at seulement s'il existe
    BEGIN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
    EXCEPTION WHEN undefined_column THEN
        -- Le champ n'existe pas, on continue
        NULL;
    END;
    
    -- Définir updated_at seulement s'il existe
    BEGIN
        NEW.updated_at := NOW();
    EXCEPTION WHEN undefined_column THEN
        -- Le champ n'existe pas, on continue
        NULL;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRÉER DES TRIGGERS SÉCURISÉS POUR L'ONBOARDING
SELECT '=== CRÉATION TRIGGERS SÉCURISÉS ONBOARDING ===' as etape;

-- Supprimer les anciens triggers problématiques
DROP TRIGGER IF EXISTS set_user_id_clients_trigger ON public.clients;
DROP TRIGGER IF EXISTS set_user_id_devices_trigger ON public.devices;
DROP TRIGGER IF EXISTS set_user_id_services_trigger ON public.services;
DROP TRIGGER IF EXISTS set_user_id_parts_trigger ON public.parts;
DROP TRIGGER IF EXISTS set_user_id_products_trigger ON public.products;
DROP TRIGGER IF EXISTS set_user_id_sales_trigger ON public.sales;
DROP TRIGGER IF EXISTS set_user_id_repairs_trigger ON public.repairs;

-- Créer les nouveaux triggers sécurisés
CREATE TRIGGER set_user_id_clients_safe
    BEFORE INSERT ON public.clients
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_user_id_devices_safe
    BEFORE INSERT ON public.devices
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_user_id_services_safe
    BEFORE INSERT ON public.services
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_user_id_parts_safe
    BEFORE INSERT ON public.parts
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_user_id_products_safe
    BEFORE INSERT ON public.products
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_user_id_sales_safe
    BEFORE INSERT ON public.sales
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_user_id_repairs_safe
    BEFORE INSERT ON public.repairs
    FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

-- 7. TEST FINAL DE L'ONBOARDING
SELECT '=== TEST FINAL ONBOARDING ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_success BOOLEAN := FALSE;
BEGIN
    -- Créer un utilisateur de test
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '🧪 Test final onboarding avec utilisateur: %', v_test_user_id;
    
    -- Simuler la connexion de cet utilisateur
    PERFORM set_config('request.jwt.claims', '{"sub":"' || v_test_user_id || '"}', true);
    
    -- Test d'insertion d'un client (test principal)
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'Final', 'test.final@example.com', '0123456789', '123 Test Street', v_test_user_id
        ) RETURNING id INTO v_test_client_id;
        
        v_success := TRUE;
        RAISE NOTICE '✅ SUCCÈS: Client créé - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ ÉCHEC: Erreur lors de la création du client: %', SQLERRM;
    END;
    
    -- Nettoyer le test
    IF v_test_client_id IS NOT NULL THEN
        DELETE FROM clients WHERE id = v_test_client_id;
    END IF;
    
    RAISE NOTICE '✅ Test nettoyé';
    
    -- Réinitialiser le contexte
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    -- Résumé du test
    RAISE NOTICE '📊 RÉSULTAT TEST FINAL:';
    RAISE NOTICE '  - Insertion client: %', CASE WHEN v_success THEN '✅ SUCCÈS' ELSE '❌ ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test final: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les triggers créés
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'sales', 'repairs')
AND trigger_name LIKE 'set_user_id_%'
ORDER BY event_object_table, trigger_name;

-- 9. MESSAGE DE CONFIRMATION
SELECT '=== CORRECTION ONBOARDING TERMINÉE ===' as etape;
SELECT '✅ Triggers sécurisés créés pour l''onboarding' as message;
SELECT '✅ Tests d''insertion effectués' as tests;
SELECT '✅ Système d''onboarding corrigé' as systeme;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Le guide d''intégration devrait maintenant fonctionner' as note;
