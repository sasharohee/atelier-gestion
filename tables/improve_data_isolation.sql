-- =====================================================
-- AMÉLIORATION DE L'ISOLATION DES DONNÉES
-- =====================================================

-- 1. Suppression des politiques RLS existantes pour les nouvelles tables
DROP POLICY IF EXISTS "Users can view device models" ON device_models;
DROP POLICY IF EXISTS "Technicians can manage device models" ON device_models;
DROP POLICY IF EXISTS "Users can view performance metrics" ON performance_metrics;
DROP POLICY IF EXISTS "Admins can manage performance metrics" ON performance_metrics;
DROP POLICY IF EXISTS "Users can view their own reports" ON reports;
DROP POLICY IF EXISTS "Users can create reports" ON reports;
DROP POLICY IF EXISTS "Users can view their alerts" ON advanced_alerts;
DROP POLICY IF EXISTS "Users can update their alerts" ON advanced_alerts;
DROP POLICY IF EXISTS "Users can view technician performance" ON technician_performance;
DROP POLICY IF EXISTS "Admins can manage technician performance" ON technician_performance;
DROP POLICY IF EXISTS "Users can view transactions" ON transactions;
DROP POLICY IF EXISTS "Technicians can create transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can view activity logs" ON activity_logs;
DROP POLICY IF EXISTS "Users can view settings" ON advanced_settings;
DROP POLICY IF EXISTS "Admins can manage settings" ON advanced_settings;

-- 2. Ajout de colonnes pour l'isolation des données
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE device_models ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- Créer un utilisateur admin par défaut si aucun n'existe
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Vérifier s'il existe déjà un utilisateur admin
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE raw_user_meta_data->>'role' = 'admin' 
    LIMIT 1;
    
    -- Si aucun admin n'existe, créer un utilisateur par défaut
    IF admin_user_id IS NULL THEN
        INSERT INTO auth.users (id, email, raw_user_meta_data, created_at, updated_at)
        VALUES (
            gen_random_uuid(),
            'admin@default.com',
            '{"role": "admin", "name": "Administrateur par défaut"}'::jsonb,
            NOW(),
            NOW()
        ) RETURNING id INTO admin_user_id;
    END IF;
END $$;

ALTER TABLE performance_metrics ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE performance_metrics ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE reports ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE advanced_alerts ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE technician_performance ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE transactions ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE activity_logs ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE advanced_settings ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- 3. Mise à jour des données existantes avec l'ID de l'atelier et created_by
UPDATE device_models SET 
    workshop_id = (
        SELECT COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    ),
    created_by = COALESCE(
        created_by,
        (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE workshop_id IS NULL OR created_by IS NULL;

UPDATE performance_metrics SET 
    workshop_id = (
        SELECT COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    ),
    created_by = COALESCE(
        created_by,
        (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE workshop_id IS NULL OR created_by IS NULL;

UPDATE reports SET workshop_id = (
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

UPDATE technician_performance SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE transactions SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE activity_logs SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

UPDATE advanced_settings SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) WHERE workshop_id IS NULL;

-- 4. Nouvelles politiques RLS avec isolation stricte

-- Politiques pour device_models
CREATE POLICY "device_models_select_policy" ON device_models
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "device_models_insert_policy" ON device_models
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        created_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "device_models_update_policy" ON device_models
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

CREATE POLICY "device_models_delete_policy" ON device_models
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

-- Politiques pour performance_metrics
CREATE POLICY "performance_metrics_select_policy" ON performance_metrics
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "performance_metrics_insert_policy" ON performance_metrics
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        created_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "performance_metrics_update_policy" ON performance_metrics
    FOR UPDATE USING (
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

-- Politiques pour reports
CREATE POLICY "reports_select_policy" ON reports
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        (generated_by = auth.uid() OR 
         EXISTS (
             SELECT 1 FROM auth.users 
             WHERE auth.users.id = auth.uid() 
             AND auth.users.raw_user_meta_data->>'role' = 'admin'
         ))
    );

CREATE POLICY "reports_insert_policy" ON reports
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        generated_by = auth.uid()
    );

-- Politiques pour advanced_alerts
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

-- Politiques pour technician_performance
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
        ) AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "technician_performance_update_policy" ON technician_performance
    FOR UPDATE USING (
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

-- Politiques pour transactions
CREATE POLICY "transactions_select_policy" ON transactions
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "transactions_insert_policy" ON transactions
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        technician_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

CREATE POLICY "transactions_update_policy" ON transactions
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

-- Politiques pour activity_logs
CREATE POLICY "activity_logs_select_policy" ON activity_logs
    FOR SELECT USING (
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

CREATE POLICY "activity_logs_insert_policy" ON activity_logs
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        user_id = auth.uid()
    );

-- Politiques pour advanced_settings
CREATE POLICY "advanced_settings_select_policy" ON advanced_settings
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

CREATE POLICY "advanced_settings_insert_policy" ON advanced_settings
    FOR INSERT WITH CHECK (
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

CREATE POLICY "advanced_settings_update_policy" ON advanced_settings
    FOR UPDATE USING (
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

-- 5. Nettoyage final des données avant contraintes

-- S'assurer qu'il n'y a pas de valeurs NULL dans workshop_id et created_by
UPDATE device_models SET 
    workshop_id = COALESCE(workshop_id, '00000000-0000-0000-0000-000000000000'::UUID),
    created_by = COALESCE(created_by, 
        (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE workshop_id IS NULL OR created_by IS NULL;

UPDATE performance_metrics SET 
    workshop_id = COALESCE(workshop_id, '00000000-0000-0000-0000-000000000000'::UUID),
    created_by = COALESCE(created_by, 
        (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
WHERE workshop_id IS NULL OR created_by IS NULL;

-- 6. Contraintes supplémentaires pour l'isolation

-- Contrainte pour s'assurer que workshop_id n'est jamais NULL
ALTER TABLE device_models ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE performance_metrics ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE reports ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE advanced_alerts ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE technician_performance ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE transactions ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE activity_logs ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE advanced_settings ALTER COLUMN workshop_id SET NOT NULL;

-- Contrainte pour s'assurer que created_by est défini lors de l'insertion
ALTER TABLE device_models ALTER COLUMN created_by SET NOT NULL;
ALTER TABLE performance_metrics ALTER COLUMN created_by SET NOT NULL;

-- 7. Index pour optimiser les requêtes avec workshop_id
CREATE INDEX IF NOT EXISTS idx_device_models_workshop ON device_models(workshop_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_workshop ON performance_metrics(workshop_id);
CREATE INDEX IF NOT EXISTS idx_reports_workshop ON reports(workshop_id);
CREATE INDEX IF NOT EXISTS idx_advanced_alerts_workshop ON advanced_alerts(workshop_id);
CREATE INDEX IF NOT EXISTS idx_technician_performance_workshop ON technician_performance(workshop_id);
CREATE INDEX IF NOT EXISTS idx_transactions_workshop ON transactions(workshop_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_workshop ON activity_logs(workshop_id);
CREATE INDEX IF NOT EXISTS idx_advanced_settings_workshop ON advanced_settings(workshop_id);

-- 8. Fonction pour automatiquement définir workshop_id et created_by
CREATE OR REPLACE FUNCTION set_workshop_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.workshop_id = COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    );
    
    IF TG_OP = 'INSERT' THEN
        NEW.created_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Triggers pour automatiquement définir le contexte
CREATE TRIGGER trigger_set_workshop_context_device_models
    BEFORE INSERT OR UPDATE ON device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_performance_metrics
    BEFORE INSERT OR UPDATE ON performance_metrics
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_reports
    BEFORE INSERT OR UPDATE ON reports
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_advanced_alerts
    BEFORE INSERT OR UPDATE ON advanced_alerts
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_technician_performance
    BEFORE INSERT OR UPDATE ON technician_performance
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_transactions
    BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_activity_logs
    BEFORE INSERT OR UPDATE ON activity_logs
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER trigger_set_workshop_context_advanced_settings
    BEFORE INSERT OR UPDATE ON advanced_settings
    FOR EACH ROW
    EXECUTE FUNCTION set_workshop_context();

-- 10. Fonction pour vérifier l'isolation des données
CREATE OR REPLACE FUNCTION verify_data_isolation()
RETURNS TABLE (
    table_name TEXT,
    total_rows BIGINT,
    isolated_rows BIGINT,
    isolation_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'device_models'::TEXT as table_name,
        COUNT(*) as total_rows,
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) as isolated_rows,
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2) as isolation_percentage
    FROM device_models
    
    UNION ALL
    
    SELECT 
        'performance_metrics'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM performance_metrics
    
    UNION ALL
    
    SELECT 
        'reports'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM reports
    
    UNION ALL
    
    SELECT 
        'advanced_alerts'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM advanced_alerts
    
    UNION ALL
    
    SELECT 
        'technician_performance'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM technician_performance
    
    UNION ALL
    
    SELECT 
        'transactions'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM transactions
    
    UNION ALL
    
    SELECT 
        'activity_logs'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM activity_logs
    
    UNION ALL
    
    SELECT 
        'advanced_settings'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM advanced_settings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Commentaires pour documenter l'isolation
COMMENT ON FUNCTION set_workshop_context() IS 'Fonction pour automatiquement définir le contexte de l''atelier lors des insertions/mises à jour';
COMMENT ON FUNCTION verify_data_isolation() IS 'Fonction pour vérifier le niveau d''isolation des données par table';
COMMENT ON COLUMN device_models.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN device_models.created_by IS 'Utilisateur qui a créé l''enregistrement';
COMMENT ON COLUMN performance_metrics.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN performance_metrics.created_by IS 'Utilisateur qui a créé l''enregistrement';
COMMENT ON COLUMN reports.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN advanced_alerts.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN technician_performance.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN transactions.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN activity_logs.workshop_id IS 'ID de l''atelier pour l''isolation des données';
COMMENT ON COLUMN advanced_settings.workshop_id IS 'ID de l''atelier pour l''isolation des données';
