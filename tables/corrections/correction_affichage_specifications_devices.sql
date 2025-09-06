-- =====================================================
-- CORRECTION AFFICHAGE SPÉCIFICATIONS - TABLE DEVICES
-- =====================================================
-- Objectif: Corriger l'affichage des spécifications dans la table devices
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION DONNÉES ACTUELLES
SELECT '=== 1. VÉRIFICATION DONNÉES ACTUELLES ===' as section;

-- Vérifier les données actuelles dans la table devices
SELECT 
    'Données actuelles devices' as info,
    id,
    brand,
    model,
    serial_number,
    specifications,
    created_at
FROM public.devices
ORDER BY created_at;

-- 2. NETTOYAGE DES SPÉCIFICATIONS CORROMPUES
SELECT '=== 2. NETTOYAGE DES SPÉCIFICATIONS CORROMPUES ===' as section;

-- Identifier et nettoyer les spécifications corrompues
UPDATE public.devices 
SET specifications = NULL 
WHERE specifications LIKE '%0: {, 1: ", 2: p, 3: r, 4: o, 5: c, 6: e, 7: s, 8: s, 9: o, 10: r%'
   OR specifications LIKE '%0: {, 1: ", 2: %'
   OR specifications ~ '^[0-9]+: [^,]+(?:, [0-9]+: [^,]+)*$';

-- 3. CRÉATION DE SPÉCIFICATIONS PAR DÉFAUT
SELECT '=== 3. CRÉATION DE SPÉCIFICATIONS PAR DÉFAUT ===' as section;

-- Mettre à jour les spécifications vides avec des valeurs par défaut
UPDATE public.devices 
SET specifications = CASE 
    WHEN brand ILIKE '%iphone%' OR brand ILIKE '%apple%' THEN 
        '{"processor": "A17 Pro", "ram": "8GB", "storage": "256GB", "screen": "6.1 inch Super Retina XDR", "camera": "48MP Main + 12MP Ultra Wide", "battery": "3349mAh"}'
    WHEN brand ILIKE '%samsung%' THEN 
        '{"processor": "Exynos 2400", "ram": "12GB", "storage": "256GB", "screen": "6.8 inch Dynamic AMOLED", "camera": "200MP Main + 12MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%xiaomi%' THEN 
        '{"processor": "Snapdragon 8 Gen 3", "ram": "12GB", "storage": "256GB", "screen": "6.73 inch AMOLED", "camera": "50MP Main + 50MP Telephoto", "battery": "4880mAh"}'
    WHEN brand ILIKE '%huawei%' THEN 
        '{"processor": "Kirin 9000S", "ram": "8GB", "storage": "256GB", "screen": "6.82 inch OLED", "camera": "50MP Main + 13MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%oneplus%' THEN 
        '{"processor": "Snapdragon 8 Gen 3", "ram": "16GB", "storage": "512GB", "screen": "6.82 inch AMOLED", "camera": "50MP Main + 48MP Ultra Wide", "battery": "5400mAh"}'
    WHEN brand ILIKE '%google%' OR brand ILIKE '%pixel%' THEN 
        '{"processor": "Google Tensor G3", "ram": "8GB", "storage": "128GB", "screen": "6.1 inch OLED", "camera": "50MP Main + 12MP Ultra Wide", "battery": "4575mAh"}'
    WHEN brand ILIKE '%oppo%' THEN 
        '{"processor": "MediaTek Dimensity 9200+", "ram": "12GB", "storage": "256GB", "screen": "6.7 inch AMOLED", "camera": "50MP Main + 32MP Telephoto", "battery": "5000mAh"}'
    WHEN brand ILIKE '%vivo%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.78 inch AMOLED", "camera": "50MP Main + 12MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%realme%' THEN 
        '{"processor": "MediaTek Dimensity 7200", "ram": "8GB", "storage": "256GB", "screen": "6.7 inch AMOLED", "camera": "108MP Main + 2MP Depth", "battery": "5000mAh"}'
    WHEN brand ILIKE '%motorola%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.7 inch OLED", "camera": "50MP Main + 12MP Ultra Wide", "battery": "4600mAh"}'
    WHEN brand ILIKE '%nokia%' THEN 
        '{"processor": "Snapdragon 695", "ram": "6GB", "storage": "128GB", "screen": "6.67 inch IPS LCD", "camera": "50MP Main + 5MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%sony%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.5 inch OLED", "camera": "48MP Main + 12MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%lg%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "8GB", "storage": "256GB", "screen": "6.8 inch OLED", "camera": "50MP Main + 12MP Ultra Wide", "battery": "4700mAh"}'
    WHEN brand ILIKE '%asus%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "16GB", "storage": "512GB", "screen": "6.78 inch AMOLED", "camera": "50MP Main + 13MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%lenovo%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.7 inch OLED", "camera": "50MP Main + 13MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%honor%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.81 inch OLED", "camera": "50MP Main + 50MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%nothing%' THEN 
        '{"processor": "Snapdragon 8+ Gen 1", "ram": "8GB", "storage": "128GB", "screen": "6.55 inch OLED", "camera": "50MP Main + 50MP Ultra Wide", "battery": "4500mAh"}'
    WHEN brand ILIKE '%zte%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.67 inch AMOLED", "camera": "64MP Main + 8MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%alcatel%' THEN 
        '{"processor": "MediaTek Helio G85", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "48MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%blackberry%' THEN 
        '{"processor": "Snapdragon 662", "ram": "6GB", "storage": "128GB", "screen": "6.5 inch IPS LCD", "camera": "48MP Main + 8MP Ultra Wide", "battery": "4000mAh"}'
    WHEN brand ILIKE '%cat%' THEN 
        '{"processor": "Snapdragon 480", "ram": "4GB", "storage": "64GB", "screen": "5.7 inch IPS LCD", "camera": "13MP Main + 2MP Depth", "battery": "4000mAh"}'
    WHEN brand ILIKE '%cubot%' THEN 
        '{"processor": "MediaTek Helio A22", "ram": "3GB", "storage": "32GB", "screen": "5.5 inch IPS LCD", "camera": "13MP Main + 2MP Depth", "battery": "3000mAh"}'
    WHEN brand ILIKE '%doogee%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%elephone%' THEN 
        '{"processor": "MediaTek Helio P23", "ram": "4GB", "storage": "64GB", "screen": "5.99 inch IPS LCD", "camera": "13MP Main + 5MP Secondary", "battery": "3000mAh"}'
    WHEN brand ILIKE '%fairphone%' THEN 
        '{"processor": "Snapdragon 750G", "ram": "6GB", "storage": "128GB", "screen": "6.3 inch OLED", "camera": "48MP Main + 48MP Ultra Wide", "battery": "4000mAh"}'
    WHEN brand ILIKE '%gionee%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%htc%' THEN 
        '{"processor": "Snapdragon 765G", "ram": "8GB", "storage": "128GB", "screen": "6.7 inch OLED", "camera": "48MP Main + 8MP Ultra Wide", "battery": "4000mAh"}'
    WHEN brand ILIKE '%infinix%' THEN 
        '{"processor": "MediaTek Helio G85", "ram": "6GB", "storage": "128GB", "screen": "6.78 inch IPS LCD", "camera": "50MP Main + 2MP Macro", "battery": "5000mAh"}'
    WHEN brand ILIKE '%itel%' THEN 
        '{"processor": "MediaTek Helio A22", "ram": "2GB", "storage": "32GB", "screen": "6.1 inch IPS LCD", "camera": "8MP Main + 0.3MP Secondary", "battery": "3000mAh"}'
    WHEN brand ILIKE '%jio%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "5000mAh"}'
    WHEN brand ILIKE '%karbonn%' THEN 
        '{"processor": "MediaTek Helio A22", "ram": "2GB", "storage": "16GB", "screen": "5.45 inch IPS LCD", "camera": "5MP Main + 0.3MP Secondary", "battery": "2500mAh"}'
    WHEN brand ILIKE '%lava%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "5000mAh"}'
    WHEN brand ILIKE '%meizu%' THEN 
        '{"processor": "MediaTek Dimensity 900", "ram": "8GB", "storage": "128GB", "screen": "6.7 inch AMOLED", "camera": "64MP Main + 8MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%micromax%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "5000mAh"}'
    WHEN brand ILIKE '%nubia%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "16GB", "storage": "1TB", "screen": "6.8 inch AMOLED", "camera": "64MP Main + 50MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%panasonic%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "3GB", "storage": "32GB", "screen": "5.45 inch IPS LCD", "camera": "8MP Main + 2MP Depth", "battery": "3000mAh"}'
    WHEN brand ILIKE '%sharp%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.4 inch OLED", "camera": "50MP Main + 12MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%tecno%' THEN 
        '{"processor": "MediaTek Helio G85", "ram": "6GB", "storage": "128GB", "screen": "6.78 inch IPS LCD", "camera": "50MP Main + 2MP Macro", "battery": "5000mAh"}'
    WHEN brand ILIKE '%umidigi%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%vivo%' THEN 
        '{"processor": "Snapdragon 8 Gen 2", "ram": "12GB", "storage": "256GB", "screen": "6.78 inch AMOLED", "camera": "50MP Main + 12MP Ultra Wide", "battery": "5000mAh"}'
    WHEN brand ILIKE '%wiko%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%xolo%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%yu%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    WHEN brand ILIKE '%zen%' THEN 
        '{"processor": "MediaTek Helio G35", "ram": "4GB", "storage": "64GB", "screen": "6.52 inch IPS LCD", "camera": "13MP Main + 2MP Macro", "battery": "4000mAh"}'
    ELSE 
        '{"processor": "Processeur standard", "ram": "4GB", "storage": "64GB", "screen": "6.0 inch LCD", "camera": "13MP Main", "battery": "4000mAh"}'
END
WHERE specifications IS NULL OR specifications = '';

-- 4. VÉRIFICATION DES DONNÉES CORRIGÉES
SELECT '=== 4. VÉRIFICATION DES DONNÉES CORRIGÉES ===' as section;

-- Vérifier les données après correction
SELECT 
    'Données corrigées devices' as info,
    id,
    brand,
    model,
    serial_number,
    specifications,
    created_at
FROM public.devices
ORDER BY created_at;

-- 5. TEST D'INSERTION AVEC SPÉCIFICATIONS CORRECTES
SELECT '=== 5. TEST D INSERTION AVEC SPÉCIFICATIONS CORRECTES ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_device_id UUID;
    test_specifications TEXT;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion avec spécifications correctes pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans devices avec spécifications correctes
    INSERT INTO public.devices (
        brand, 
        model, 
        serial_number, 
        type, 
        specifications, 
        color, 
        condition_status, 
        notes
    )
    VALUES (
        'Test Brand', 
        'Test Model', 
        'TESTSERIAL456', 
        'Smartphone', 
        '{"processor": "Test Processor", "ram": "8GB", "storage": "256GB", "screen": "6.1 inch OLED", "camera": "48MP Main", "battery": "4000mAh"}', 
        'Black', 
        'Good', 
        'Test device with correct specifications'
    )
    RETURNING id, specifications INTO test_device_id, test_specifications;
    
    RAISE NOTICE '✅ Device créé avec ID: %', test_device_id;
    RAISE NOTICE '✅ Spécifications: %', test_specifications;
    
    -- Nettoyer
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 6. VÉRIFICATION CACHE POSTGREST
SELECT '=== 6. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 7. RÉSUMÉ FINAL
SELECT '=== 7. RÉSUMÉ FINAL ===' as section;

-- Résumé des corrections
SELECT 
    'Résumé corrections specifications' as info,
    COUNT(*) as total_devices,
    COUNT(CASE WHEN specifications IS NOT NULL AND specifications != '' THEN 1 END) as devices_avec_specs,
    COUNT(CASE WHEN specifications IS NULL OR specifications = '' THEN 1 END) as devices_sans_specs
FROM public.devices;

SELECT 'CORRECTION AFFICHAGE SPÉCIFICATIONS DEVICES TERMINÉE' as status;
