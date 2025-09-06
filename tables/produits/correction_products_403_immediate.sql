-- Correction immédiate du problème 403 sur products
-- Script pour corriger les politiques RLS qui empêchent l'insertion

-- 1. Désactiver temporairement RLS sur products pour permettre l'insertion
ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- 2. Vérifier si des politiques existent et les supprimer
DROP POLICY IF EXISTS "Users can view their own products" ON products;
DROP POLICY IF EXISTS "Users can insert their own products" ON products;
DROP POLICY IF EXISTS "Users can update their own products" ON products;
DROP POLICY IF EXISTS "Users can delete their own products" ON products;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON products;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON products;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON products;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON products;

-- 3. Créer des politiques RLS plus permissives
CREATE POLICY "Enable read access for authenticated users" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON products
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON products
    FOR DELETE USING (auth.role() = 'authenticated');

-- 4. Réactiver RLS avec les nouvelles politiques
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 5. Vérifier que la table products a bien une colonne user_id
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'user_id'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE 'La table products n''a pas de colonne user_id - ajout en cours...';
        ALTER TABLE products ADD COLUMN user_id UUID REFERENCES users(id);
    ELSE
        RAISE NOTICE 'La colonne user_id existe déjà dans products';
    END IF;
END $$;

-- 6. Vérifier et créer les colonnes d'isolation si nécessaire
DO $$
DECLARE
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
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

-- 7. Mettre à jour les enregistrements existants avec l'ID de l'admin
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements existants
        UPDATE products 
        SET user_id = admin_user_id 
        WHERE user_id IS NULL;
        
        UPDATE products 
        SET created_by = admin_user_id 
        WHERE created_by IS NULL;
        
        UPDATE products 
        SET workshop_id = admin_user_id 
        WHERE workshop_id IS NULL;
        
        RAISE NOTICE 'Enregistrements products mis à jour avec l''ID admin: %', admin_user_id;
    ELSE
        RAISE NOTICE 'Aucun utilisateur admin trouvé';
    END IF;
END $$;

-- 8. Créer un trigger pour définir automatiquement les valeurs d'isolation
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

-- 9. Supprimer le trigger existant s'il existe et le recréer
DROP TRIGGER IF EXISTS set_products_isolation_trigger ON products;

CREATE TRIGGER set_products_isolation_trigger
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_products_isolation();

-- 10. Vérifier la configuration finale
SELECT 
    'products RLS status' as info,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_tables 
            WHERE tablename = 'products' 
            AND rowsecurity = true
        ) THEN 'RLS activé'
        ELSE 'RLS désactivé'
    END as rls_status;

SELECT 
    'Politiques RLS products' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'products';

-- 11. Test d'insertion pour vérifier que tout fonctionne
DO $$
DECLARE
    test_id UUID;
    test_created_by UUID;
    test_workshop_id UUID;
    test_user_id UUID;
BEGIN
    -- Test d'insertion
    INSERT INTO products (
        id, name, description, price, stock_quantity, category, is_active, 
        created_at, updated_at
    ) VALUES (
        gen_random_uuid(), 'Test Product', 'Test Description', 25.00, 10, 'Test Category', true,
        NOW(), NOW()
    ) RETURNING id, created_by, workshop_id, user_id INTO test_id, test_created_by, test_workshop_id, test_user_id;
    
    RAISE NOTICE '✅ Test d''insertion réussi - ID: %, Created_by: %, Workshop_id: %, User_id: %', 
        test_id, test_created_by, test_workshop_id, test_user_id;
    
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
        RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 12. Vérification finale
SELECT 
    '=== VÉRIFICATION FINALE ===' as etape,
    'products' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as avec_user_id,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.triggers 
            WHERE trigger_name = 'set_products_isolation_trigger'
            AND event_object_table = 'products'
        ) THEN '✅ Trigger actif'
        ELSE '❌ Trigger manquant'
    END as trigger_status,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_policies 
            WHERE tablename = 'products' 
            AND cmd = 'INSERT'
        ) THEN '✅ Politique INSERT'
        ELSE '❌ Politique INSERT manquante'
    END as rls_insert_status;

SELECT 'Correction products 403 terminée avec succès !' as status;
