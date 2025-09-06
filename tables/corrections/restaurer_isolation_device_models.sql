-- Restaurer l'isolation des données sur device_models
-- Script pour remettre en place les politiques RLS d'isolation tout en gardant la fonctionnalité

-- 1. Diagnostic de l'état actuel
SELECT '=== DIAGNOSTIC ÉTAT ACTUEL ===' as etape;

-- Vérifier les politiques RLS actuelles
SELECT 
    'Politiques RLS actuelles' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_models';

-- Vérifier la structure de la table
SELECT 
    'Structure device_models' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
AND column_name IN ('created_by', 'workshop_id', 'user_id')
ORDER BY column_name;

-- 2. Supprimer les politiques permissives actuelles
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON device_models;

-- 3. Créer des politiques RLS d'isolation basées sur l'utilisateur
-- Politique de lecture : les utilisateurs ne voient que leurs propres modèles
CREATE POLICY "Users can view their own device models" ON device_models
    FOR SELECT USING (
        created_by = auth.uid() OR 
        workshop_id = auth.uid() OR
        (user_id IS NOT NULL AND user_id = auth.uid())
    );

-- Politique d'insertion : les utilisateurs peuvent insérer leurs propres modèles
CREATE POLICY "Users can insert their own device models" ON device_models
    FOR INSERT WITH CHECK (
        created_by = auth.uid() OR 
        workshop_id = auth.uid() OR
        (user_id IS NOT NULL AND user_id = auth.uid())
    );

-- Politique de modification : les utilisateurs peuvent modifier leurs propres modèles
CREATE POLICY "Users can update their own device models" ON device_models
    FOR UPDATE USING (
        created_by = auth.uid() OR 
        workshop_id = auth.uid() OR
        (user_id IS NOT NULL AND user_id = auth.uid())
    ) WITH CHECK (
        created_by = auth.uid() OR 
        workshop_id = auth.uid() OR
        (user_id IS NOT NULL AND user_id = auth.uid())
    );

-- Politique de suppression : les utilisateurs peuvent supprimer leurs propres modèles
CREATE POLICY "Users can delete their own device models" ON device_models
    FOR DELETE USING (
        created_by = auth.uid() OR 
        workshop_id = auth.uid() OR
        (user_id IS NOT NULL AND user_id = auth.uid())
    );

-- 4. Vérifier que le trigger fonctionne toujours correctement
DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
    test_workshop_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Test d'insertion avec isolation
    INSERT INTO device_models (
        id, brand, model, category, 
        repair_difficulty, parts_availability, is_active, 
        created_at, updated_at
    ) VALUES (
        gen_random_uuid(), 'Test Isolation', 'Test Model', 'Test Category',
        'Medium', 'Good', true,
        NOW(), NOW()
    ) RETURNING id, created_by, workshop_id INTO test_id, test_created_by, test_workshop_id;
    
    RAISE NOTICE '✅ Test d''insertion avec isolation réussi - ID: %, Created_by: %, Workshop_id: %', 
        test_id, test_created_by, test_workshop_id;
    
    -- Vérifier que les colonnes ont été définies correctement
    IF test_created_by = current_user_id AND test_workshop_id = current_user_id THEN
        RAISE NOTICE '✅ Isolation correcte - les valeurs correspondent à l''utilisateur actuel';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation - valeurs incorrectes';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM device_models WHERE id = test_id;
    RAISE NOTICE '✅ Enregistrement de test supprimé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test d''insertion avec isolation: %', SQLERRM;
END $$;

-- 5. Vérifier l'isolation des données existantes
DO $$
DECLARE
    current_user_id UUID;
    total_models INTEGER;
    user_models INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Compter le total des modèles
    SELECT COUNT(*) INTO total_models FROM device_models;
    
    -- Compter les modèles de l'utilisateur actuel
    SELECT COUNT(*) INTO user_models FROM device_models 
    WHERE created_by = current_user_id OR workshop_id = current_user_id;
    
    RAISE NOTICE '📊 Isolation des données - Total: %, Modèles utilisateur actuel: %', total_models, user_models;
    
    IF user_models < total_models THEN
        RAISE NOTICE '✅ Isolation fonctionnelle - L''utilisateur ne voit que ses propres modèles';
    ELSE
        RAISE NOTICE '⚠️  Vérification nécessaire - L''utilisateur pourrait voir tous les modèles';
    END IF;
END $$;

-- 6. Vérification finale des politiques RLS
SELECT '=== VÉRIFICATION FINALE ISOLATION ===' as etape;

SELECT 
    'Politiques RLS d''isolation' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY cmd, policyname;

-- 7. Test de lecture avec isolation
DO $$
DECLARE
    current_user_id UUID;
    visible_models INTEGER;
    all_models INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Compter tous les modèles (sans politique RLS)
    SELECT COUNT(*) INTO all_models FROM device_models;
    
    -- Compter les modèles visibles par l'utilisateur actuel
    SELECT COUNT(*) INTO visible_models FROM device_models 
    WHERE created_by = current_user_id OR workshop_id = current_user_id;
    
    RAISE NOTICE '🔍 Test d''isolation - Total modèles: %, Modèles visibles: %', all_models, visible_models;
    
    IF visible_models <= all_models THEN
        RAISE NOTICE '✅ Isolation fonctionnelle - L''utilisateur ne voit que ses propres modèles';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation - L''utilisateur voit plus de modèles que prévu';
    END IF;
END $$;

-- 8. Statistiques finales
SELECT 
    '=== STATISTIQUES FINALES ===' as etape,
    'device_models' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(DISTINCT created_by) as nombre_createurs,
    COUNT(DISTINCT workshop_id) as nombre_workshops,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_policies 
            WHERE tablename = 'device_models' 
            AND cmd = 'SELECT'
            AND policyname = 'Users can view their own device models'
        ) THEN '✅ Politique SELECT isolée'
        ELSE '❌ Politique SELECT manquante'
    END as isolation_select_status,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_policies 
            WHERE tablename = 'device_models' 
            AND cmd = 'INSERT'
            AND policyname = 'Users can insert their own device models'
        ) THEN '✅ Politique INSERT isolée'
        ELSE '❌ Politique INSERT manquante'
    END as isolation_insert_status
FROM device_models;

SELECT 'Isolation device_models restaurée avec succès !' as status;
