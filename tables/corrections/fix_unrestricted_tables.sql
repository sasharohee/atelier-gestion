-- =====================================================
-- CORRECTION DES TABLES "UNRESTRICTED"
-- =====================================================

-- 1. Ajout de colonnes workshop_id aux tables existantes qui n'en ont pas
ALTER TABLE products ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- Ajouter workshop_id aux tables de base utilisées dans les vues
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- Note: consolidated_statistics, top_clients, top_devices sont des vues, pas des tables
-- Elles seront recréées avec isolation appropriée

-- 2. Mise à jour des données existantes avec workshop_id
UPDATE products SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE user_profiles SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE user_preferences SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

-- Mise à jour des tables de base utilisées dans les vues
UPDATE repairs SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE clients SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE devices SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

-- 3. Activation de RLS sur toutes les tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- Note: Les vues (consolidated_statistics, top_clients, top_devices) 
-- seront recréées avec isolation intégrée

-- 4. Politiques RLS pour les tables de base

-- Politiques RLS pour repairs
DROP POLICY IF EXISTS "repairs_select_policy" ON repairs;
DROP POLICY IF EXISTS "repairs_insert_policy" ON repairs;
DROP POLICY IF EXISTS "repairs_update_policy" ON repairs;

CREATE POLICY "repairs_select_policy" ON repairs
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "repairs_insert_policy" ON repairs
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "repairs_update_policy" ON repairs
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- Politiques RLS pour clients
DROP POLICY IF EXISTS "clients_select_policy" ON clients;
DROP POLICY IF EXISTS "clients_insert_policy" ON clients;
DROP POLICY IF EXISTS "clients_update_policy" ON clients;

CREATE POLICY "clients_select_policy" ON clients
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "clients_insert_policy" ON clients
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "clients_update_policy" ON clients
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- Politiques RLS pour devices
DROP POLICY IF EXISTS "devices_select_policy" ON devices;
DROP POLICY IF EXISTS "devices_insert_policy" ON devices;
DROP POLICY IF EXISTS "devices_update_policy" ON devices;

CREATE POLICY "devices_select_policy" ON devices
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "devices_insert_policy" ON devices
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "devices_update_policy" ON devices
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- 5. Politiques RLS pour products
DROP POLICY IF EXISTS "products_select_policy" ON products;
DROP POLICY IF EXISTS "products_insert_policy" ON products;
DROP POLICY IF EXISTS "products_update_policy" ON products;
DROP POLICY IF EXISTS "products_delete_policy" ON products;

CREATE POLICY "products_select_policy" ON products
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "products_insert_policy" ON products
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "products_update_policy" ON products
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "products_delete_policy" ON products
    FOR DELETE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- 6. Note: Les vues (consolidated_statistics, top_clients, top_devices) 
-- doivent être gérées séparément avec le script fix_views_error.sql
-- car elles ne sont pas des tables mais des vues

-- 7. Note: Les politiques RLS pour les vues sont gérées dans fix_views_error.sql
-- car les vues nécessitent un traitement spécial

-- 7. Politiques RLS pour user_profiles
DROP POLICY IF EXISTS "user_profiles_select_policy" ON user_profiles;
DROP POLICY IF EXISTS "user_profiles_insert_policy" ON user_profiles;
DROP POLICY IF EXISTS "user_profiles_update_policy" ON user_profiles;

CREATE POLICY "user_profiles_select_policy" ON user_profiles
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        (user_id = auth.uid() OR 
         EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'admin'
         ))
    );

CREATE POLICY "user_profiles_insert_policy" ON user_profiles
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        user_id = auth.uid()
    );

CREATE POLICY "user_profiles_update_policy" ON user_profiles
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        (user_id = auth.uid() OR 
         EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'admin'
         ))
    );

-- 8. Politiques RLS pour user_preferences
DROP POLICY IF EXISTS "user_preferences_select_policy" ON user_preferences;
DROP POLICY IF EXISTS "user_preferences_insert_policy" ON user_preferences;
DROP POLICY IF EXISTS "user_preferences_update_policy" ON user_preferences;

CREATE POLICY "user_preferences_select_policy" ON user_preferences
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        (user_id = auth.uid() OR 
         EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'admin'
         ))
    );

CREATE POLICY "user_preferences_insert_policy" ON user_preferences
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        user_id = auth.uid()
    );

CREATE POLICY "user_preferences_update_policy" ON user_preferences
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        (user_id = auth.uid() OR 
         EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'admin'
         ))
    );

-- 9. Ajout de contraintes NOT NULL
ALTER TABLE products ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE user_profiles ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE user_preferences ALTER COLUMN workshop_id SET NOT NULL;

-- 10. Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_products_workshop ON products(workshop_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_workshop ON user_profiles(workshop_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_workshop ON user_preferences(workshop_id);
CREATE INDEX IF NOT EXISTS idx_repairs_workshop ON repairs(workshop_id);
CREATE INDEX IF NOT EXISTS idx_clients_workshop ON clients(workshop_id);
CREATE INDEX IF NOT EXISTS idx_devices_workshop ON devices(workshop_id);

-- 11. Triggers pour automatiquement définir workshop_id
CREATE TRIGGER trigger_set_workshop_context_products
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_user_profiles
    BEFORE INSERT OR UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_user_preferences
    BEFORE INSERT OR UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_repairs
    BEFORE INSERT OR UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_clients
    BEFORE INSERT OR UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_devices
    BEFORE INSERT OR UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

-- 12. Triggers pour les fonctionnalités avancées

-- Nettoyer les triggers existants qui pourraient causer des conflits
DROP TRIGGER IF EXISTS trigger_update_technician_performance ON repairs;
DROP TRIGGER IF EXISTS trigger_create_repair_alerts ON repairs;

-- Vérifier que les tables nécessaires existent avant de créer les triggers
DO $$
BEGIN
    -- Créer la table technician_performance si elle n'existe pas
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'technician_performance') THEN
        CREATE TABLE technician_performance (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            technician_id UUID NOT NULL,
            period_start DATE NOT NULL,
            period_end DATE NOT NULL,
            total_repairs INTEGER DEFAULT 0,
            completed_repairs INTEGER DEFAULT 0,
            avg_repair_time NUMERIC(10,2) DEFAULT 0,
            total_revenue NUMERIC(10,2) DEFAULT 0,
            customer_satisfaction NUMERIC(3,2) DEFAULT 0,
            workshop_id UUID NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(technician_id, period_start, period_end)
        );
        
        -- Ajouter les commentaires
        COMMENT ON TABLE technician_performance IS 'Métriques de performance des techniciens par période';
        COMMENT ON COLUMN technician_performance.technician_id IS 'ID du technicien';
        COMMENT ON COLUMN technician_performance.period_start IS 'Début de la période';
        COMMENT ON COLUMN technician_performance.period_end IS 'Fin de la période';
        COMMENT ON COLUMN technician_performance.total_repairs IS 'Nombre total de réparations';
        COMMENT ON COLUMN technician_performance.completed_repairs IS 'Nombre de réparations terminées';
        COMMENT ON COLUMN technician_performance.avg_repair_time IS 'Temps moyen de réparation en jours';
        COMMENT ON COLUMN technician_performance.total_revenue IS 'Revenus totaux générés';
        COMMENT ON COLUMN technician_performance.customer_satisfaction IS 'Note de satisfaction client (0-5)';
        COMMENT ON COLUMN technician_performance.workshop_id IS 'ID de l''atelier pour l''isolation des données';
    END IF;
    
    -- Créer la table advanced_alerts si elle n'existe pas
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'advanced_alerts') THEN
        CREATE TABLE advanced_alerts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            alert_type VARCHAR(50) NOT NULL,
            title VARCHAR(200) NOT NULL,
            message TEXT NOT NULL,
            severity alert_severity_type DEFAULT 'info',
            target_user_id UUID,
            target_role user_role,
            is_read BOOLEAN DEFAULT false,
            workshop_id UUID NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        -- Ajouter les commentaires
        COMMENT ON TABLE advanced_alerts IS 'Alertes avancées du système';
        COMMENT ON COLUMN advanced_alerts.alert_type IS 'Type d''alerte';
        COMMENT ON COLUMN advanced_alerts.title IS 'Titre de l''alerte';
        COMMENT ON COLUMN advanced_alerts.message IS 'Message de l''alerte';
        COMMENT ON COLUMN advanced_alerts.severity IS 'Niveau de gravité';
        COMMENT ON COLUMN advanced_alerts.target_user_id IS 'Utilisateur cible';
        COMMENT ON COLUMN advanced_alerts.target_role IS 'Rôle cible';
        COMMENT ON COLUMN advanced_alerts.is_read IS 'Alerte lue';
        COMMENT ON COLUMN advanced_alerts.workshop_id IS 'ID de l''atelier pour l''isolation des données';
    END IF;
END $$;

-- Ajouter workshop_id aux nouvelles tables si nécessaire
ALTER TABLE technician_performance ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE advanced_alerts ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- Mettre à jour les données existantes
UPDATE technician_performance SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE advanced_alerts SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

-- Activer RLS sur les nouvelles tables
ALTER TABLE technician_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE advanced_alerts ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour technician_performance
DROP POLICY IF EXISTS "technician_performance_select_policy" ON technician_performance;
DROP POLICY IF EXISTS "technician_performance_insert_policy" ON technician_performance;
DROP POLICY IF EXISTS "technician_performance_update_policy" ON technician_performance;

CREATE POLICY "technician_performance_select_policy" ON technician_performance
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "technician_performance_insert_policy" ON technician_performance
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "technician_performance_update_policy" ON technician_performance
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politiques RLS pour advanced_alerts
DROP POLICY IF EXISTS "advanced_alerts_select_policy" ON advanced_alerts;
DROP POLICY IF EXISTS "advanced_alerts_insert_policy" ON advanced_alerts;
DROP POLICY IF EXISTS "advanced_alerts_update_policy" ON advanced_alerts;

CREATE POLICY "advanced_alerts_select_policy" ON advanced_alerts
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        (target_user_id = auth.uid() OR 
         target_role = (SELECT (raw_user_meta_data->>'role')::user_role FROM auth.users WHERE id = auth.uid()) OR
         target_user_id IS NULL)
    );

CREATE POLICY "advanced_alerts_insert_policy" ON advanced_alerts
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "advanced_alerts_update_policy" ON advanced_alerts
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        target_user_id = auth.uid()
    );

-- Note: Les fonctions et triggers sont gérés dans fix_functions_and_triggers.sql

-- Note: Les triggers sont gérés dans fix_functions_and_triggers.sql

-- 13. Fonction pour vérifier que toutes les tables sont sécurisées
CREATE OR REPLACE FUNCTION check_table_security()
RETURNS TABLE (
    table_name TEXT,
    has_rls BOOLEAN,
    policy_count INTEGER,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.table_name::TEXT,
        t.row_security as has_rls,
        COALESCE(p.policy_count, 0) as policy_count,
        CASE 
            WHEN t.row_security = true AND COALESCE(p.policy_count, 0) > 0 THEN '✅ Sécurisé'
            WHEN t.row_security = false THEN '❌ RLS désactivé'
            WHEN t.row_security = true AND COALESCE(p.policy_count, 0) = 0 THEN '⚠️ RLS activé mais pas de politique'
            ELSE '❓ Inconnu'
        END as status
    FROM information_schema.tables t
    LEFT JOIN (
        SELECT 
            schemaname,
            tablename,
            COUNT(*) as policy_count
        FROM pg_policies 
        WHERE schemaname = 'public'
        GROUP BY schemaname, tablename
    ) p ON t.table_schema = p.schemaname AND t.table_name = p.tablename
    WHERE t.table_schema = 'public' 
    AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: Les fonctions sont gérées dans fix_functions_and_triggers.sql

-- 15. Fonction de test pour vérifier l'installation

CREATE OR REPLACE FUNCTION test_installation()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Vérifier que les tables existent
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'technician_performance') THEN
        RETURN QUERY SELECT 'Table technician_performance'::TEXT, '✅ OK'::TEXT, 'Table créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que les tables existent
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'advanced_alerts') THEN
        RETURN QUERY SELECT 'Table advanced_alerts'::TEXT, '✅ OK'::TEXT, 'Table créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table advanced_alerts'::TEXT, '❌ ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les triggers existent
    IF EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trigger_set_workshop_context_products') THEN
        RETURN QUERY SELECT 'Trigger trigger_set_workshop_context_products'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_set_workshop_context_products'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 4: Vérifier l'isolation des données
    IF EXISTS (SELECT FROM pg_policies WHERE tablename = 'products' AND policyname = 'products_select_policy') THEN
        RETURN QUERY SELECT 'Politique RLS products'::TEXT, '✅ OK'::TEXT, 'Politique RLS créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique RLS products'::TEXT, '❌ ERREUR'::TEXT, 'Politique RLS manquante'::TEXT;
    END IF;
    
    -- Test 5: Vérifier que les tables de base sont sécurisées
    IF EXISTS (SELECT FROM pg_policies WHERE tablename = 'repairs' AND policyname = 'repairs_select_policy') THEN
        RETURN QUERY SELECT 'Politique RLS repairs'::TEXT, '✅ OK'::TEXT, 'Politique RLS créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique RLS repairs'::TEXT, '❌ ERREUR'::TEXT, 'Politique RLS manquante'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. Commentaires
COMMENT ON FUNCTION check_table_security() IS 'Fonction pour vérifier la sécurité de toutes les tables';
COMMENT ON FUNCTION test_installation() IS 'Fonction pour tester l''installation complète';
COMMENT ON COLUMN products.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN user_profiles.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN user_preferences.workshop_id IS 'ID de l''atelier pour l''isolation des données';
