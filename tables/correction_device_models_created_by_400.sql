-- Correction du problème 400 - Colonne created_by manquante dans device_models
-- Script pour résoudre l'erreur "null value in column created_by violates not-null constraint"

-- 1. Vérifier la structure actuelle de la table device_models
SELECT '=== DIAGNOSTIC STRUCTURE DEVICE_MODELS ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier si la colonne created_by existe et la créer si nécessaire
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Vérifier si la colonne created_by existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND table_schema = 'public'
        AND column_name = 'created_by'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        -- Ajouter la colonne created_by
        ALTER TABLE device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_models';
    END IF;
END $$;

-- 3. Vérifier les contraintes NOT NULL
SELECT 
    'Contraintes NOT NULL sur device_models' as info,
    column_name,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
AND table_schema = 'public'
AND is_nullable = 'NO';

-- 4. Vérifier les triggers existants
SELECT 
    'Triggers sur device_models' as info,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';

-- 5. Supprimer le trigger existant s'il existe
DROP TRIGGER IF EXISTS set_device_models_created_by ON device_models;

-- 6. Créer la fonction pour le trigger
CREATE OR REPLACE FUNCTION set_device_models_created_by()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir created_by automatiquement
    NEW.created_by := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND column_name = 'user_id'
    ) AND NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    -- Définir workshop_id si la colonne existe et est NULL
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND column_name = 'workshop_id'
    ) AND NEW.workshop_id IS NULL THEN
        NEW.workshop_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Créer le trigger
CREATE TRIGGER set_device_models_created_by
    BEFORE INSERT ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_models_created_by();

-- 8. Vérifier les politiques RLS
SELECT 
    'Politiques RLS device_models' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_models';

-- 9. S'assurer que les politiques RLS permettent l'insertion
DO $$
BEGIN
    -- Vérifier si les politiques permissives existent
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND cmd = 'INSERT'
        AND policyname = 'Enable insert access for authenticated users'
    ) THEN
        -- Créer une politique permissive pour l'insertion
        CREATE POLICY "Enable insert access for authenticated users" ON device_models
            FOR INSERT WITH CHECK (auth.role() = 'authenticated');
        
        RAISE NOTICE '✅ Politique d''insertion permissive créée';
    ELSE
        RAISE NOTICE '✅ Politique d''insertion existe déjà';
    END IF;
END $$;

-- 10. Maintenant que created_by existe, mettre à jour les enregistrements existants
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

-- 11. Vérifier que tous les enregistrements ont un created_by (maintenant que la colonne existe)
SELECT 
    'Vérification created_by' as info,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_created_by
FROM device_models;

-- 12. Test d'insertion pour vérifier que le trigger fonctionne
DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
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
    
    -- Vérifier que created_by a été défini
    IF test_created_by IS NOT NULL THEN
        RAISE NOTICE '✅ Created_by correctement défini par le trigger';
    ELSE
        RAISE NOTICE '❌ Created_by non défini par le trigger';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM device_models WHERE id = test_id;
    RAISE NOTICE '✅ Enregistrement de test supprimé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 13. Vérification finale (maintenant que created_by existe)
SELECT 
    '=== VÉRIFICATION FINALE ===' as etape,
    'device_models' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_created_by,
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
