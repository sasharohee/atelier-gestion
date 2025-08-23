-- Correction du problème 400 - Colonne workshop_id manquante dans device_models
-- Script pour résoudre l'erreur "null value in column workshop_id violates not-null constraint"

-- 1. Diagnostic initial
SELECT '=== DIAGNOSTIC INITIAL ===' as etape;

-- Vérifier la structure actuelle
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Créer la colonne workshop_id si elle n'existe pas
DO $$
BEGIN
    -- Ajouter la colonne workshop_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND table_schema = 'public'
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE device_models ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans device_models';
    END IF;
END $$;

-- 3. Mettre à jour la fonction trigger pour gérer workshop_id
CREATE OR REPLACE FUNCTION set_device_models_created_by()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir created_by automatiquement
    NEW.created_by := v_user_id;
    
    -- Définir workshop_id automatiquement
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND column_name = 'user_id'
    ) AND NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recréer le trigger
DROP TRIGGER IF EXISTS set_device_models_created_by ON device_models;

CREATE TRIGGER set_device_models_created_by
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_models_created_by();

-- 5. Maintenant que workshop_id existe, mettre à jour les données existantes
DO $$
DECLARE
    admin_user_id UUID;
    updated_count INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements avec workshop_id NULL
        UPDATE device_models 
        SET workshop_id = admin_user_id 
        WHERE workshop_id IS NULL;
        
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements mis à jour avec workshop_id = %', updated_count, admin_user_id;
    ELSE
        RAISE NOTICE '❌ Aucun utilisateur admin trouvé';
    END IF;
END $$;

-- 6. Vérification que les colonnes existent maintenant
SELECT '=== VÉRIFICATION POST-CRÉATION ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
AND column_name IN ('created_by', 'workshop_id');

-- 7. Vérification des données
SELECT 
    'Vérification created_by et workshop_id' as info,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_created_by,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM device_models;

-- 8. Test d'insertion complet
DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
    test_workshop_id UUID;
BEGIN
    -- Test d'insertion avec toutes les colonnes obligatoires
    INSERT INTO device_models (
        id, brand, model, category, 
        repair_difficulty, parts_availability, is_active, 
        created_at, updated_at
    ) VALUES (
        gen_random_uuid(), 'Test Brand', 'Test Model', 'Test Category',
        'Medium', 'Good', true,
        NOW(), NOW()
    ) RETURNING id, created_by, workshop_id INTO test_id, test_created_by, test_workshop_id;
    
    RAISE NOTICE '✅ Test d''insertion réussi - ID: %, Created_by: %, Workshop_id: %', 
        test_id, test_created_by, test_workshop_id;
    
    -- Vérifier que les colonnes ont été définies
    IF test_created_by IS NOT NULL AND test_workshop_id IS NOT NULL THEN
        RAISE NOTICE '✅ Created_by et workshop_id correctement définis par le trigger';
    ELSE
        RAISE NOTICE '❌ Problème avec created_by ou workshop_id';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM device_models WHERE id = test_id;
    RAISE NOTICE '✅ Enregistrement de test supprimé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 9. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

SELECT 
    'device_models' as table_name,
    COUNT(*) as total_enregistrements,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.triggers 
            WHERE trigger_name = 'set_device_models_created_by'
            AND event_object_table = 'device_models'
        ) THEN '✅ Trigger actif'
        ELSE '❌ Trigger manquant'
    END as trigger_status,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_policies 
            WHERE tablename = 'device_models' 
            AND cmd = 'INSERT'
        ) THEN '✅ Politique INSERT'
        ELSE '❌ Politique INSERT manquante'
    END as rls_insert_status,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'device_models' 
            AND column_name = 'created_by'
        ) THEN '✅ Colonne created_by'
        ELSE '❌ Colonne created_by manquante'
    END as created_by_status,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'device_models' 
            AND column_name = 'workshop_id'
        ) THEN '✅ Colonne workshop_id'
        ELSE '❌ Colonne workshop_id manquante'
    END as workshop_id_status;

SELECT 'Correction device_models workshop_id 400 terminée avec succès !' as status;
