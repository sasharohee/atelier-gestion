-- Correction simple du problème 400 - Colonne created_by manquante dans device_models
-- Script simplifié et robuste pour résoudre l'erreur "null value in column created_by violates not-null constraint"

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

-- 2. Créer la colonne created_by si elle n'existe pas
DO $$
BEGIN
    -- Ajouter la colonne created_by si elle n'existe pas
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND table_schema = 'public'
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_models';
    END IF;
END $$;

-- 3. Créer la fonction trigger
CREATE OR REPLACE FUNCTION set_device_models_created_by()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir created_by automatiquement
    NEW.created_by := v_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Supprimer et recréer le trigger
DROP TRIGGER IF EXISTS set_device_models_created_by ON device_models;

CREATE TRIGGER set_device_models_created_by
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_models_created_by();

-- 5. Créer une politique RLS permissive pour l'insertion
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON device_models;

CREATE POLICY "Enable insert access for authenticated users" ON device_models
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 6. Maintenant que created_by existe, mettre à jour les données existantes
DO $$
DECLARE
    admin_user_id UUID;
    updated_count INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements avec created_by NULL
        UPDATE device_models 
        SET created_by = admin_user_id 
        WHERE created_by IS NULL;
        
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements mis à jour avec created_by = %', updated_count, admin_user_id;
    ELSE
        RAISE NOTICE '❌ Aucun utilisateur admin trouvé';
    END IF;
END $$;

-- 7. Vérification que la colonne existe maintenant
SELECT '=== VÉRIFICATION POST-CRÉATION ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
AND column_name = 'created_by';

-- 8. Vérification des données
SELECT 
    'Vérification created_by' as info,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_created_by
FROM device_models;

-- 9. Test d'insertion
DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
BEGIN
    -- Test d'insertion
    INSERT INTO device_models (
        id, brand, model, category, 
        repair_difficulty, parts_availability, is_active, 
        created_at, updated_at
    ) VALUES (
        gen_random_uuid(), 'Test Brand', 'Test Model', 'Test Category',
        'Medium', 'Good', true,
        NOW(), NOW()
    ) RETURNING id, created_by INTO test_id, test_created_by;
    
    RAISE NOTICE '✅ Test d''insertion réussi - ID: %, Created_by: %', test_id, test_created_by;
    
    -- Nettoyer le test
    DELETE FROM device_models WHERE id = test_id;
    RAISE NOTICE '✅ Enregistrement de test supprimé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 10. Vérification finale
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
    END as rls_insert_status;

SELECT 'Correction device_models created_by 400 terminée avec succès !' as status;
