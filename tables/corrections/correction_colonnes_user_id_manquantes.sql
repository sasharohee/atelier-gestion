-- Correction des colonnes user_id manquantes
-- Date: 2024-01-24

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DES TABLES

SELECT 
    '=== DIAGNOSTIC DES COLONNES USER_ID ===' as info;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('repairs', 'products', 'sales', 'appointments', 'clients', 'devices')
AND column_name = 'user_id'
ORDER BY table_name;

-- 2. AJOUTER LA COLONNE USER_ID DANS REPAIRS

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'user_id') THEN
        ALTER TABLE repairs ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans repairs';
    END IF;
END $$;

-- 3. AJOUTER LA COLONNE USER_ID DANS PRODUCTS

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') THEN
        ALTER TABLE products ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table products';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans products';
    END IF;
END $$;

-- 4. AJOUTER LA COLONNE USER_ID DANS SALES

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'user_id') THEN
        ALTER TABLE sales ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table sales';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans sales';
    END IF;
END $$;

-- 5. AJOUTER LA COLONNE USER_ID DANS APPOINTMENTS

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') THEN
        ALTER TABLE appointments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans appointments';
    END IF;
END $$;

-- 6. AJOUTER LA COLONNE USER_ID DANS CLIENTS (SI MANQUANTE)

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') THEN
        ALTER TABLE clients ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table clients';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans clients';
    END IF;
END $$;

-- 7. AJOUTER LA COLONNE USER_ID DANS DEVICES (SI MANQUANTE)

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') THEN
        ALTER TABLE devices ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table devices';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans devices';
    END IF;
END $$;

-- 8. CRÉER LES INDEX POUR LES PERFORMANCES

CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);

-- 9. METTRE À JOUR LES DONNÉES EXISTANTES (OPTIONNEL)

-- Si vous voulez assigner les données existantes à un utilisateur spécifique
-- Décommentez et modifiez la ligne suivante avec l'ID de l'utilisateur souhaité
-- UPDATE repairs SET user_id = 'votre-user-id-ici' WHERE user_id IS NULL;

-- 10. VÉRIFIER LA STRUCTURE FINALE

SELECT 
    '=== STRUCTURE FINALE ===' as info;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('repairs', 'products', 'sales', 'appointments', 'clients', 'devices')
AND column_name = 'user_id'
ORDER BY table_name;

-- 11. CRÉER UNE FONCTION DE TEST

CREATE OR REPLACE FUNCTION test_user_id_columns()
RETURNS TABLE(tbl_name TEXT, status TEXT, details TEXT) AS $$
BEGIN
    -- Test repairs
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'repairs'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'repairs'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test products
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'products'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'products'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test sales
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'sales'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'sales'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test appointments
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'appointments'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'appointments'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test clients
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'clients'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'clients'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test devices
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'devices'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'devices'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- 12. EXÉCUTER LE TEST

SELECT '=== TEST DES COLONNES USER_ID ===' as info;
SELECT * FROM test_user_id_columns();

-- 13. INSTRUCTIONS

SELECT 
    '=== INSTRUCTIONS ===' as section,
    'Après avoir exécuté ce script :' as instruction;

SELECT 
    '1. Recharger l''application' as step,
    'Les erreurs 400 devraient disparaître' as action;

SELECT 
    '2. Vérifier les données' as step,
    'Les requêtes devraient maintenant fonctionner' as action;

SELECT 
    '3. Tester la connexion' as step,
    'L''application devrait charger sans erreur' as action;

SELECT 
    '=== CORRECTION TERMINÉE ===' as status,
    'Les colonnes user_id ont été ajoutées aux tables' as message;
