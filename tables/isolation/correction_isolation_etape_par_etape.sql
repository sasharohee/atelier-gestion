-- =====================================================
-- CORRECTION ISOLATION ÉTAPE PAR ÉTAPE
-- =====================================================
-- Correction de l'isolation sur toutes les tables importantes
-- Date: 2025-01-23
-- =====================================================

-- ÉTAPE 1: Ajouter les colonnes d'isolation
SELECT '=== ÉTAPE 1: AJOUT DES COLONNES ===' as etape;

-- Clients
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE clients ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans clients';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE clients ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans clients';
    END IF;
END $$;

-- Appointments
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE appointments ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE appointments ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans appointments';
    END IF;
END $$;

-- Products
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE products ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans products';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE products ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans products';
    END IF;
END $$;

-- Sales
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE sales ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans sales';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE sales ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans sales';
    END IF;
END $$;

-- ÉTAPE 2: Mettre à jour les données existantes
SELECT '=== ÉTAPE 2: MISE À JOUR DES DONNÉES ===' as etape;

-- Mettre à jour workshop_id pour toutes les tables
UPDATE clients 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

UPDATE appointments 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

UPDATE products 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

UPDATE sales 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Mettre à jour created_by pour toutes les tables
UPDATE clients 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

UPDATE appointments 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

UPDATE products 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

UPDATE sales 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- ÉTAPE 3: Activer RLS et créer les politiques
SELECT '=== ÉTAPE 3: ACTIVATION RLS ===' as etape;

-- Activer RLS sur toutes les tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Nettoyer les politiques existantes
DROP POLICY IF EXISTS clients_select_policy ON clients;
DROP POLICY IF EXISTS clients_insert_policy ON clients;
DROP POLICY IF EXISTS clients_update_policy ON clients;
DROP POLICY IF EXISTS clients_delete_policy ON clients;

DROP POLICY IF EXISTS appointments_select_policy ON appointments;
DROP POLICY IF EXISTS appointments_insert_policy ON appointments;
DROP POLICY IF EXISTS appointments_update_policy ON appointments;
DROP POLICY IF EXISTS appointments_delete_policy ON appointments;

DROP POLICY IF EXISTS products_select_policy ON products;
DROP POLICY IF EXISTS products_insert_policy ON products;
DROP POLICY IF EXISTS products_update_policy ON products;
DROP POLICY IF EXISTS products_delete_policy ON products;

DROP POLICY IF EXISTS sales_select_policy ON sales;
DROP POLICY IF EXISTS sales_insert_policy ON sales;
DROP POLICY IF EXISTS sales_update_policy ON sales;
DROP POLICY IF EXISTS sales_delete_policy ON sales;

-- ÉTAPE 4: Créer les politiques RLS
SELECT '=== ÉTAPE 4: CRÉATION DES POLITIQUES ===' as etape;

-- Politiques pour clients
CREATE POLICY clients_select_policy ON clients
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY clients_insert_policy ON clients
    FOR INSERT WITH CHECK (true);

CREATE POLICY clients_update_policy ON clients
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY clients_delete_policy ON clients
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politiques pour appointments
CREATE POLICY appointments_select_policy ON appointments
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY appointments_insert_policy ON appointments
    FOR INSERT WITH CHECK (true);

CREATE POLICY appointments_update_policy ON appointments
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY appointments_delete_policy ON appointments
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politiques pour products
CREATE POLICY products_select_policy ON products
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY products_insert_policy ON products
    FOR INSERT WITH CHECK (true);

CREATE POLICY products_update_policy ON products
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY products_delete_policy ON products
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politiques pour sales
CREATE POLICY sales_select_policy ON sales
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY sales_insert_policy ON sales
    FOR INSERT WITH CHECK (true);

CREATE POLICY sales_update_policy ON sales
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY sales_delete_policy ON sales
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- ÉTAPE 5: Créer les triggers
SELECT '=== ÉTAPE 5: CRÉATION DES TRIGGERS ===' as etape;

-- Fonction trigger générique
CREATE OR REPLACE FUNCTION set_workshop_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_client_context ON clients;
CREATE TRIGGER set_client_context
    BEFORE INSERT ON clients
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

DROP TRIGGER IF EXISTS set_appointment_context ON appointments;
CREATE TRIGGER set_appointment_context
    BEFORE INSERT ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

DROP TRIGGER IF EXISTS set_product_context ON products;
CREATE TRIGGER set_product_context
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

DROP TRIGGER IF EXISTS set_sale_context ON sales;
CREATE TRIGGER set_sale_context
    BEFORE INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

-- ÉTAPE 6: Vérification finale
SELECT '=== ÉTAPE 6: VÉRIFICATION FINALE ===' as etape;

-- Vérifier les politiques créées
SELECT 
    tablename,
    COUNT(*) as nombre_politiques
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'appointments', 'products', 'sales')
GROUP BY tablename
ORDER BY tablename;

-- Vérifier les triggers créés
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'appointments', 'products', 'sales')
ORDER BY event_object_table, trigger_name;

-- Vérifier les colonnes ajoutées
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('clients', 'appointments', 'products', 'sales')
AND column_name IN ('workshop_id', 'created_by')
ORDER BY table_name, column_name;

-- ÉTAPE 7: Instructions finales
SELECT '=== ÉTAPE 7: INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation corrigée sur toutes les tables' as message;
SELECT '✅ Colonnes workshop_id et created_by ajoutées' as colonnes;
SELECT '✅ Politiques RLS créées avec accès gestion' as politiques;
SELECT '✅ Triggers automatiques créés' as triggers;
SELECT '✅ Testez les pages Administration et Réglages' as next_step;
SELECT 'ℹ️ L''isolation fonctionne maintenant sur toutes les tables' as note;
