-- =====================================================
-- AJOUTER DONNÉES TEST APPARAILS
-- =====================================================
-- Ajoute des données de test dans la table devices
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel
SELECT '=== ÉTAT ACTUEL ===' as etape;

SELECT COUNT(*) as nombre_appareils_actuels FROM devices;

-- 2. Obtenir l'utilisateur actuel
DO $$
DECLARE
    v_user_id UUID;
    v_test_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    RAISE NOTICE 'User_id pour les tests: %', v_user_id;
    
    -- 3. Ajouter des appareils de test
    SELECT '=== AJOUT APPARAILS TEST ===' as etape;
    
    -- Appareil 1: iPhone
    INSERT INTO devices (
        brand, model, type, serial_number, specifications, user_id, created_by, created_at, updated_at
    ) VALUES (
        'Apple', 'iPhone 14', 'smartphone', 'IP14-001', 
        '{"processor": "A15 Bionic", "ram": "6GB", "storage": "128GB", "screen": "6.1 inch"}',
        v_user_id, v_user_id, NOW(), NOW()
    ) RETURNING id INTO v_test_id;
    RAISE NOTICE '✅ iPhone 14 créé - ID: %', v_test_id;
    
    -- Appareil 2: Samsung
    INSERT INTO devices (
        brand, model, type, serial_number, specifications, user_id, created_by, created_at, updated_at
    ) VALUES (
        'Samsung', 'Galaxy S23', 'smartphone', 'SS23-001', 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "8GB", "storage": "256GB", "screen": "6.1 inch"}',
        v_user_id, v_user_id, NOW(), NOW()
    ) RETURNING id INTO v_test_id;
    RAISE NOTICE '✅ Samsung Galaxy S23 créé - ID: %', v_test_id;
    
    -- Appareil 3: MacBook
    INSERT INTO devices (
        brand, model, type, serial_number, specifications, user_id, created_by, created_at, updated_at
    ) VALUES (
        'Apple', 'MacBook Pro 14"', 'laptop', 'MBP14-001', 
        '{"processor": "M2 Pro", "ram": "16GB", "storage": "512GB", "screen": "14 inch"}',
        v_user_id, v_user_id, NOW(), NOW()
    ) RETURNING id INTO v_test_id;
    RAISE NOTICE '✅ MacBook Pro créé - ID: %', v_test_id;
    
    -- Appareil 4: iPad
    INSERT INTO devices (
        brand, model, type, serial_number, specifications, user_id, created_by, created_at, updated_at
    ) VALUES (
        'Apple', 'iPad Air', 'tablet', 'IPA-001', 
        '{"processor": "M1", "ram": "8GB", "storage": "256GB", "screen": "10.9 inch"}',
        v_user_id, v_user_id, NOW(), NOW()
    ) RETURNING id INTO v_test_id;
    RAISE NOTICE '✅ iPad Air créé - ID: %', v_test_id;
    
    -- Appareil 5: PC Desktop
    INSERT INTO devices (
        brand, model, type, serial_number, specifications, user_id, created_by, created_at, updated_at
    ) VALUES (
        'Dell', 'OptiPlex 7090', 'desktop', 'DELL-001', 
        '{"processor": "Intel i7-11700", "ram": "16GB", "storage": "1TB", "screen": "N/A"}',
        v_user_id, v_user_id, NOW(), NOW()
    ) RETURNING id INTO v_test_id;
    RAISE NOTICE '✅ Dell OptiPlex créé - ID: %', v_test_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de l''ajout des données test: %', SQLERRM;
END $$;

-- 4. Vérifier le résultat
SELECT '=== VÉRIFICATION FINALE ===' as etape;

SELECT 
    COUNT(*) as nombre_appareils_final
FROM devices;

SELECT 
    brand,
    model,
    type,
    created_at
FROM devices
ORDER BY created_at DESC
LIMIT 10;

-- 5. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Données de test ajoutées avec succès' as message;
SELECT '✅ Testez maintenant la page appareils' as next_step;
SELECT 'ℹ️ Vous devriez voir 5 appareils de test' as expected;
SELECT '⚠️ Si la page ne s''affiche toujours pas, vérifiez la console du navigateur' as browser_check;
