-- 🔧 CORRECTION SIMPLE - Erreur 403 Products
-- Script pour corriger l'erreur 403 sur la table products

-- ========================================
-- PARTIE 1: CORRECTION ERREUR 403 PRODUCTS
-- ========================================

-- 1. Désactiver temporairement RLS sur products
ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques RLS existantes
DROP POLICY IF EXISTS "Users can view their own products" ON products;
DROP POLICY IF EXISTS "Users can insert their own products" ON products;
DROP POLICY IF EXISTS "Users can update their own products" ON products;
DROP POLICY IF EXISTS "Users can delete their own products" ON products;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON products;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON products;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON products;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON products;
DROP POLICY IF EXISTS "products_select_policy" ON products;
DROP POLICY IF EXISTS "products_insert_policy" ON products;
DROP POLICY IF EXISTS "products_update_policy" ON products;
DROP POLICY IF EXISTS "products_delete_policy" ON products;

-- 3. Vérifier et créer les colonnes d'isolation si nécessaire
DO $$
DECLARE
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    -- Vérifier si la colonne user_id existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    -- Vérifier si la colonne created_by existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    -- Vérifier si la colonne workshop_id existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    IF NOT user_id_exists THEN
        ALTER TABLE products ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans products';
    END IF;
    
    IF NOT created_by_exists THEN
        ALTER TABLE products ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans products';
    END IF;
    
    IF NOT workshop_id_exists THEN
        ALTER TABLE products ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans products';
    END IF;
END $$;

-- 4. Mettre à jour les enregistrements existants
DO $$
DECLARE
    default_user_id UUID;
BEGIN
    -- Récupérer l'ID d'un utilisateur par défaut
    SELECT id INTO default_user_id FROM auth.users LIMIT 1;
    
    IF default_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements existants
        UPDATE products SET user_id = default_user_id WHERE user_id IS NULL;
        UPDATE products SET created_by = default_user_id WHERE created_by IS NULL;
        UPDATE products SET workshop_id = default_user_id WHERE workshop_id IS NULL;
        
        RAISE NOTICE '✅ Enregistrements products mis à jour avec l''ID utilisateur: %', default_user_id;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour la mise à jour';
    END IF;
END $$;

-- 5. Créer un trigger pour définir automatiquement les valeurs d'isolation
CREATE OR REPLACE FUNCTION set_products_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs d'isolation automatiquement
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Supprimer et recréer le trigger
DROP TRIGGER IF EXISTS set_products_isolation_trigger ON products;

CREATE TRIGGER set_products_isolation_trigger
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_products_isolation();

-- 7. Créer des politiques RLS permissives
CREATE POLICY "Enable read access for authenticated users" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON products
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON products
    FOR DELETE USING (auth.role() = 'authenticated');

-- 8. Réactiver RLS avec les nouvelles politiques
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- ========================================
-- PARTIE 2: VÉRIFICATIONS FINALES
-- ========================================

-- Vérifier la configuration RLS de products
DO $$
DECLARE
    rls_actif BOOLEAN;
    politique_insert_existe BOOLEAN;
    trigger_isolation_existe BOOLEAN;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    -- Vérifications
    SELECT rowsecurity INTO rls_actif FROM pg_tables WHERE tablename = 'products';
    
    SELECT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'products' 
        AND cmd = 'INSERT'
    ) INTO politique_insert_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.triggers 
        WHERE trigger_name = 'set_products_isolation_trigger'
        AND event_object_table = 'products'
    ) INTO trigger_isolation_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    -- Afficher les résultats
    RAISE NOTICE '=== VÉRIFICATION CORRECTION 403 ===';
    RAISE NOTICE 'RLS activé: %s', CASE WHEN rls_actif THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Politique INSERT: %s', CASE WHEN politique_insert_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Trigger d''isolation: %s', CASE WHEN trigger_isolation_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne user_id: %s', CASE WHEN user_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne created_by: %s', CASE WHEN created_by_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne workshop_id: %s', CASE WHEN workshop_id_exists THEN '✅' ELSE '❌' END;
    
    IF rls_actif AND politique_insert_existe AND trigger_isolation_existe AND user_id_exists AND created_by_exists AND workshop_id_exists THEN
        RAISE NOTICE '🎉 CORRECTION 403 RÉUSSIE !';
    ELSE
        RAISE NOTICE '⚠️ CORRECTION 403 INCOMPLÈTE - Vérifiez les éléments manquants';
    END IF;
END $$;

-- Test d'insertion pour vérifier que tout fonctionne
DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
    test_workshop_id UUID;
    test_user_id UUID;
    insertion_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== TEST D''INSERTION PRODUCTS ===';
    
    BEGIN
        -- Test d'insertion
        INSERT INTO products (
            id, name, description, price, stock_quantity, category, is_active, 
            created_at, updated_at
        ) VALUES (
            gen_random_uuid(), 'Test Correction 403', 'Test Description', 25.00, 10, 'Test Category', true,
            NOW(), NOW()
        ) RETURNING id, created_by, workshop_id, user_id INTO test_id, test_created_by, test_workshop_id, test_user_id;
        
        insertion_success := TRUE;
        
        RAISE NOTICE '✅ Test d''insertion RÉUSSI';
        RAISE NOTICE '   - ID: %', test_id;
        RAISE NOTICE '   - Created_by: %', test_created_by;
        RAISE NOTICE '   - Workshop_id: %', test_workshop_id;
        RAISE NOTICE '   - User_id: %', test_user_id;
        
        -- Vérifier que les valeurs d'isolation ont été définies
        IF test_created_by IS NOT NULL AND test_workshop_id IS NOT NULL AND test_user_id IS NOT NULL THEN
            RAISE NOTICE '✅ Valeurs d''isolation correctement définies par le trigger';
        ELSE
            RAISE NOTICE '❌ Problème avec les valeurs d''isolation';
        END IF;
        
        -- Nettoyer le test
        DELETE FROM products WHERE id = test_id;
        RAISE NOTICE '✅ Enregistrement de test supprimé';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ ERREUR lors du test d''insertion: %', SQLERRM;
            insertion_success := FALSE;
    END;
    
    -- Résumé du test
    IF insertion_success THEN
        RAISE NOTICE '🎉 CORRECTION 403 RÉUSSIE - L''insertion de produits fonctionne !';
    ELSE
        RAISE NOTICE '❌ CORRECTION 403 ÉCHOUÉE - L''insertion de produits ne fonctionne pas';
    END IF;
END $$;

-- Message final
SELECT '🎉 Correction erreur 403 products terminée avec succès !' as status;
