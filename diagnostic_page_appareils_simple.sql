-- =====================================================
-- DIAGNOSTIC PAGE APPARAILS SIMPLE
-- =====================================================
-- Vérifie rapidement l'état de la page appareils
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier si la table devices existe
SELECT '=== VÉRIFICATION TABLE ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'devices';

-- 2. Vérifier le contenu de la table devices
SELECT '=== CONTENU TABLE ===' as etape;

SELECT 
    COUNT(*) as nombre_appareils
FROM devices;

-- 3. Vérifier les colonnes de la table
SELECT '=== COLONNES TABLE ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'devices'
ORDER BY ordinal_position;

-- 4. Vérifier les politiques RLS
SELECT '=== POLITIQUES RLS ===' as etape;

SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

-- 5. Vérifier les triggers
SELECT '=== TRIGGERS ===' as etape;

SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'devices'
ORDER BY trigger_name;

-- 6. Test d'accès direct
SELECT '=== TEST ACCÈS DIRECT ===' as etape;

DO $$
DECLARE
    v_count INTEGER;
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    RAISE NOTICE 'User_id actuel: %', v_user_id;
    
    -- Test de lecture
    SELECT COUNT(*) INTO v_count FROM devices;
    RAISE NOTICE 'Nombre d''appareils dans la table: %', v_count;
    
    -- Test avec user_id
    SELECT COUNT(*) INTO v_count FROM devices WHERE user_id = v_user_id;
    RAISE NOTICE 'Nombre d''appareils pour l''utilisateur actuel: %', v_count;
    
    -- Test avec created_by
    SELECT COUNT(*) INTO v_count FROM devices WHERE created_by = v_user_id;
    RAISE NOTICE 'Nombre d''appareils avec created_by: %', v_count;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 7. Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as etape;

SELECT 
    id,
    brand,
    model,
    type,
    user_id,
    created_by,
    created_at
FROM devices
LIMIT 5;

-- 8. Instructions
SELECT '=== INSTRUCTIONS ===' as etape;
SELECT '✅ Si la table existe et contient des données, le problème est dans le code' as message;
SELECT '✅ Si la table est vide, il faut créer des données de test' as test_data;
SELECT '✅ Si RLS est activé, vérifier les politiques' as rls_check;
SELECT '⚠️ Vérifiez la console du navigateur pour les erreurs JavaScript' as browser_check;
