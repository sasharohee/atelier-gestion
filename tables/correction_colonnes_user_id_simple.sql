-- Correction simple des colonnes user_id manquantes
-- Version simplifiée sans fonction pour éviter les conflits

-- 1. AJOUTER LA COLONNE USER_ID DANS REPAIRS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'user_id') THEN
        ALTER TABLE repairs ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans repairs';
    END IF;
END $$;

-- 2. AJOUTER LA COLONNE USER_ID DANS PRODUCTS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') THEN
        ALTER TABLE products ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table products';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans products';
    END IF;
END $$;

-- 3. AJOUTER LA COLONNE USER_ID DANS SALES
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'user_id') THEN
        ALTER TABLE sales ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table sales';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans sales';
    END IF;
END $$;

-- 4. AJOUTER LA COLONNE USER_ID DANS APPOINTMENTS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') THEN
        ALTER TABLE appointments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans appointments';
    END IF;
END $$;

-- 5. AJOUTER LA COLONNE USER_ID DANS CLIENTS (SI MANQUANTE)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') THEN
        ALTER TABLE clients ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table clients';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans clients';
    END IF;
END $$;

-- 6. AJOUTER LA COLONNE USER_ID DANS DEVICES (SI MANQUANTE)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') THEN
        ALTER TABLE devices ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table devices';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans devices';
    END IF;
END $$;

-- 7. CRÉER LES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);

-- 8. VÉRIFIER LA STRUCTURE FINALE
SELECT 
    '=== VÉRIFICATION DES COLONNES USER_ID ===' as info;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('repairs', 'products', 'sales', 'appointments', 'clients', 'devices')
AND column_name = 'user_id'
ORDER BY table_name;

-- 9. TEST SIMPLE DES REQUÊTES
SELECT 
    '=== TEST DES REQUÊTES ===' as info;

-- Test repairs
SELECT 
    'repairs' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'user_id') 
        THEN 'Colonne user_id présente' 
        ELSE 'Colonne user_id manquante' 
    END as details;

-- Test products
SELECT 
    'products' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') 
        THEN 'Colonne user_id présente' 
        ELSE 'Colonne user_id manquante' 
    END as details;

-- Test sales
SELECT 
    'sales' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'user_id') 
        THEN 'Colonne user_id présente' 
        ELSE 'Colonne user_id manquante' 
    END as details;

-- Test appointments
SELECT 
    'appointments' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') 
        THEN 'Colonne user_id présente' 
        ELSE 'Colonne user_id manquante' 
    END as details;

-- Test clients
SELECT 
    'clients' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') 
        THEN 'Colonne user_id présente' 
        ELSE 'Colonne user_id manquante' 
    END as details;

-- Test devices
SELECT 
    'devices' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') 
        THEN 'Colonne user_id présente' 
        ELSE 'Colonne user_id manquante' 
    END as details;

-- 10. MESSAGE DE FIN
SELECT 
    '=== CORRECTION TERMINÉE ===' as status,
    'Les colonnes user_id ont été ajoutées aux tables. Rechargez votre application !' as message;
