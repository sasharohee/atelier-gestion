-- =====================================================
-- DIAGNOSTIC COMPLET ISOLATION DEVICE_MODELS
-- =====================================================
-- Objectif: Comprendre pourquoi l'isolation ne fonctionne pas
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC UTILISATEUR
SELECT '=== DIAGNOSTIC UTILISATEUR ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email;

-- Vérifier tous les utilisateurs
SELECT 
    'Tous les utilisateurs' as info,
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at;

-- 2. DIAGNOSTIC STRUCTURE TABLE
SELECT '=== DIAGNOSTIC STRUCTURE ===' as section;

-- Vérifier la structure de la table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. DIAGNOSTIC DONNÉES ACTUELLES
SELECT '=== DIAGNOSTIC DONNÉES ===' as section;

-- Vérifier toutes les données
SELECT 
    'Toutes les données' as info,
    id,
    brand,
    model,
    created_by,
    user_id,
    created_at,
    updated_at
FROM device_models
ORDER BY created_at DESC;

-- Vérifier les données par utilisateur
SELECT 
    'Données par utilisateur' as info,
    created_by,
    user_id,
    COUNT(*) as nombre_modeles,
    MIN(created_at) as premier_modele,
    MAX(created_at) as dernier_modele
FROM device_models 
GROUP BY created_by, user_id
ORDER BY created_by;

-- 4. DIAGNOSTIC RLS
SELECT '=== DIAGNOSTIC RLS ===' as section;

-- Vérifier le statut RLS
SELECT 
    'Statut RLS' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'device_models';

-- Vérifier les politiques RLS
SELECT 
    'Politiques RLS' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'device_models';

-- 5. DIAGNOSTIC TRIGGERS
SELECT '=== DIAGNOSTIC TRIGGERS ===' as section;

-- Vérifier les triggers
SELECT 
    'Triggers existants' as info,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';

-- 6. DIAGNOSTIC FONCTIONS
SELECT '=== DIAGNOSTIC FONCTIONS ===' as section;

-- Vérifier les fonctions
SELECT 
    'Fonctions existantes' as info,
    proname,
    prosrc
FROM pg_proc 
WHERE proname LIKE '%device_model%' OR proname LIKE '%get_my%';

-- 7. TEST D'INSERTION MANUEL
SELECT '=== TEST INSERTION MANUEL ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_test_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    RAISE NOTICE 'Test d''insertion manuel pour utilisateur: %', v_user_id;
    
    -- Insérer un modèle de test
    INSERT INTO device_models (brand, model, type, year, created_by, user_id)
    VALUES ('Test Diagnostic', 'Manuel', 'other', 2024, v_user_id, v_user_id)
    RETURNING id INTO v_test_id;
    
    RAISE NOTICE 'Modèle créé avec ID: %', v_test_id;
    
    -- Vérifier l'insertion
    SELECT 
        id, brand, model, created_by, user_id
    FROM device_models 
    WHERE id = v_test_id;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = v_test_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. TEST DE LECTURE MANUEL
SELECT '=== TEST LECTURE MANUEL ===' as section;

-- Test de lecture directe
SELECT 
    'Lecture directe' as info,
    COUNT(*) as nombre_modeles
FROM device_models 
WHERE created_by = auth.uid();

-- Test de lecture via fonction si elle existe
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    BEGIN
        SELECT COUNT(*) INTO v_count FROM get_my_device_models_only();
        RAISE NOTICE 'Lecture via fonction get_my_device_models_only: %', v_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Fonction get_my_device_models_only non disponible: %', SQLERRM;
    END;
    
    BEGIN
        SELECT COUNT(*) INTO v_count FROM get_my_device_models();
        RAISE NOTICE 'Lecture via fonction get_my_device_models: %', v_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Fonction get_my_device_models non disponible: %', SQLERRM;
    END;
END $$;

-- 9. DIAGNOSTIC CACHE POSTGREST
SELECT '=== DIAGNOSTIC CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 10. TEST D'ISOLATION COMPLET
SELECT '=== TEST ISOLATION COMPLET ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_total_count INTEGER;
    v_my_count INTEGER;
    v_other_count INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    RAISE NOTICE 'Test d''isolation complet pour utilisateur: %', v_user_id;
    
    -- Compter tous les modèles
    SELECT COUNT(*) INTO v_total_count FROM device_models;
    
    -- Compter mes modèles
    SELECT COUNT(*) INTO v_my_count 
    FROM device_models 
    WHERE created_by = v_user_id;
    
    -- Compter les modèles des autres
    v_other_count := v_total_count - v_my_count;
    
    RAISE NOTICE 'Total modèles: %', v_total_count;
    RAISE NOTICE 'Mes modèles: %', v_my_count;
    RAISE NOTICE 'Modèles des autres: %', v_other_count;
    
    IF v_other_count > 0 THEN
        RAISE NOTICE '❌ PROBLÈME: Il y a % modèles d''autres utilisateurs visibles', v_other_count;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: Seulement mes modèles sont visibles';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''isolation: %', SQLERRM;
END $$;

SELECT 'DIAGNOSTIC COMPLET TERMINÉ' as status;
