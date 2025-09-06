-- =====================================================
-- CRÉATION DES NOUVELLES TABLES POUR LES FONCTIONNALITÉS
-- =====================================================

-- 1. Création de tous les types ENUM en premier
DO $$ BEGIN
    CREATE TYPE device_type AS ENUM ('smartphone', 'tablet', 'laptop', 'desktop', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'technician', 'client');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE repair_difficulty_type AS ENUM ('easy', 'medium', 'hard');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE parts_availability_type AS ENUM ('high', 'medium', 'low');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE report_status_type AS ENUM ('pending', 'processing', 'completed', 'failed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE alert_severity_type AS ENUM ('info', 'warning', 'error', 'critical');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type_enum AS ENUM ('repair', 'sale', 'refund', 'deposit', 'withdrawal');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_status_type AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method_type AS ENUM ('cash', 'card', 'transfer', 'check', 'payment_link');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Table des modèles d'appareils
CREATE TABLE IF NOT EXISTS device_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    type device_type NOT NULL,
    year INTEGER NOT NULL,
    specifications JSONB DEFAULT '{}',
    common_issues TEXT[] DEFAULT '{}',
    repair_difficulty repair_difficulty_type NOT NULL DEFAULT 'medium',
    parts_availability parts_availability_type NOT NULL DEFAULT 'medium',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Table des statistiques et métriques
CREATE TABLE IF NOT EXISTS performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    metric_unit VARCHAR(50),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Table des rapports et exports
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_name VARCHAR(200) NOT NULL,
    report_type VARCHAR(100) NOT NULL,
    parameters JSONB DEFAULT '{}',
    generated_by UUID REFERENCES auth.users(id),
    file_path VARCHAR(500),
    file_size INTEGER,
    status report_status_type DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);



-- 6. Table des alertes et notifications avancées
CREATE TABLE IF NOT EXISTS advanced_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    severity alert_severity_type NOT NULL DEFAULT 'info',
    target_user_id UUID REFERENCES auth.users(id),
    target_role user_role,
    is_read BOOLEAN DEFAULT false,
    action_required BOOLEAN DEFAULT false,
    action_url VARCHAR(500),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);



-- 8. Table des métriques de performance des techniciens
CREATE TABLE IF NOT EXISTS technician_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID REFERENCES auth.users(id) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_repairs INTEGER DEFAULT 0,
    completed_repairs INTEGER DEFAULT 0,
    failed_repairs INTEGER DEFAULT 0,
    avg_repair_time DECIMAL(5,2), -- en jours
    total_revenue DECIMAL(10,2) DEFAULT 0,
    customer_satisfaction DECIMAL(3,2), -- score de 0 à 5
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Table des transactions (pour la section Transaction)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_type transaction_type_enum NOT NULL,
    reference_id UUID, -- ID de la réparation, vente, etc.
    reference_type VARCHAR(50) NOT NULL, -- 'repair', 'sale', 'refund', etc.
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    status transaction_status_type DEFAULT 'pending',
    client_id UUID REFERENCES clients(id),
    technician_id UUID REFERENCES auth.users(id),
    payment_method payment_method_type,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);



-- 11. Table des audits et logs d'activité
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Table des paramètres de configuration avancés
CREATE TABLE IF NOT EXISTS advanced_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    setting_type VARCHAR(50) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEX POUR OPTIMISER LES PERFORMANCES
-- =====================================================

-- Index pour device_models
CREATE INDEX IF NOT EXISTS idx_device_models_brand_model ON device_models(brand, model);
CREATE INDEX IF NOT EXISTS idx_device_models_type ON device_models(type);
CREATE INDEX IF NOT EXISTS idx_device_models_active ON device_models(is_active);

-- Index pour performance_metrics
CREATE INDEX IF NOT EXISTS idx_performance_metrics_period ON performance_metrics(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_category ON performance_metrics(category);

-- Index pour reports
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_by ON reports(generated_by);

-- Index pour advanced_alerts
CREATE INDEX IF NOT EXISTS idx_advanced_alerts_user ON advanced_alerts(target_user_id);
CREATE INDEX IF NOT EXISTS idx_advanced_alerts_type ON advanced_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_advanced_alerts_read ON advanced_alerts(is_read);

-- Index pour technician_performance
CREATE INDEX IF NOT EXISTS idx_technician_performance_tech ON technician_performance(technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_performance_period ON technician_performance(period_start, period_end);

-- Index pour transactions
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_client ON transactions(client_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(created_at);

-- Index pour activity_logs
CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON activity_logs(action);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_date ON activity_logs(created_at);

-- =====================================================
-- POLITIQUES RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Politiques pour device_models
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view device models" ON device_models
    FOR SELECT USING (true);

CREATE POLICY "Technicians can manage device models" ON device_models
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- Politiques pour performance_metrics
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view performance metrics" ON performance_metrics
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage performance metrics" ON performance_metrics
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Politiques pour reports
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own reports" ON reports
    FOR SELECT USING (generated_by = auth.uid());

CREATE POLICY "Users can create reports" ON reports
    FOR INSERT WITH CHECK (generated_by = auth.uid());

-- Politiques pour advanced_alerts
ALTER TABLE advanced_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their alerts" ON advanced_alerts
    FOR SELECT USING (
        target_user_id = auth.uid() OR 
        target_role = (SELECT (raw_user_meta_data->>'role')::user_role FROM auth.users WHERE id = auth.uid())
    );

CREATE POLICY "Users can update their alerts" ON advanced_alerts
    FOR UPDATE USING (target_user_id = auth.uid());

-- Politiques pour technician_performance
ALTER TABLE technician_performance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view technician performance" ON technician_performance
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage technician performance" ON technician_performance
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Politiques pour transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view transactions" ON transactions
    FOR SELECT USING (true);

CREATE POLICY "Technicians can create transactions" ON transactions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- Politiques pour activity_logs
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view activity logs" ON activity_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Politiques pour advanced_settings
ALTER TABLE advanced_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view settings" ON advanced_settings
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage settings" ON advanced_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- =====================================================
-- DONNÉES DE DÉMONSTRATION
-- =====================================================

-- Insérer des modèles d'appareils de démonstration
INSERT INTO device_models (brand, model, type, year, specifications, common_issues, repair_difficulty, parts_availability) VALUES
('Apple', 'iPhone 14 Pro', 'smartphone', 2022, 
 '{"screen": "6.1\" OLED", "processor": "A16 Bionic", "ram": "6GB", "storage": "128GB-1TB", "battery": "3200mAh", "os": "iOS 16"}',
 ARRAY['Écran cassé', 'Batterie défaillante', 'Port de charge'],
 'hard', 'high'),

('Samsung', 'Galaxy S23', 'smartphone', 2023,
 '{"screen": "6.1\" AMOLED", "processor": "Snapdragon 8 Gen 2", "ram": "8GB", "storage": "128GB-512GB", "battery": "3900mAh", "os": "Android 13"}',
 ARRAY['Écran cassé', 'Batterie', 'Haut-parleur'],
 'medium', 'high'),

('Apple', 'MacBook Pro 14"', 'laptop', 2023,
 '{"screen": "14\" Retina", "processor": "M2 Pro", "ram": "16GB", "storage": "512GB-8TB", "battery": "70Wh", "os": "macOS Ventura"}',
 ARRAY['Clavier défaillant', 'Batterie', 'Écran'],
 'hard', 'medium'),

('Dell', 'XPS 13', 'laptop', 2023,
 '{"screen": "13.4\" FHD", "processor": "Intel i7-1355U", "ram": "16GB", "storage": "512GB-2TB", "battery": "55Wh", "os": "Windows 11"}',
 ARRAY['Batterie', 'Ventilateur', 'Écran'],
 'medium', 'high');

-- Insérer des paramètres de configuration par défaut
INSERT INTO advanced_settings (setting_key, setting_value, setting_type, description, is_system) VALUES
('statistics_refresh_interval', '300', 'number', 'Intervalle de rafraîchissement des statistiques en secondes', true),
('alert_retention_days', '30', 'number', 'Nombre de jours de conservation des alertes', true),
('performance_tracking_enabled', 'true', 'boolean', 'Activer le suivi des performances', true),
('auto_report_generation', 'false', 'boolean', 'Génération automatique des rapports', true),
('dashboard_widgets', '["repairs", "revenue", "performance", "alerts"]', 'array', 'Widgets affichés sur le tableau de bord', true);

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour calculer automatiquement les métriques de performance
CREATE OR REPLACE FUNCTION calculate_technician_performance(
    p_technician_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS void AS $$
BEGIN
    INSERT INTO technician_performance (
        technician_id, period_start, period_end,
        total_repairs, completed_repairs, failed_repairs,
        avg_repair_time, total_revenue
    )
    SELECT 
        p_technician_id,
        p_start_date,
        p_end_date,
        COUNT(*) as total_repairs,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_repairs,
        COUNT(*) FILTER (WHERE status = 'cancelled') as failed_repairs,
        AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400) as avg_repair_time,
        SUM(total_price) as total_revenue
    FROM repairs
    WHERE assigned_technician_id = p_technician_id
    AND created_at::date BETWEEN p_start_date AND p_end_date
    ON CONFLICT (technician_id, period_start, period_end)
    DO UPDATE SET
        total_repairs = EXCLUDED.total_repairs,
        completed_repairs = EXCLUDED.completed_repairs,
        failed_repairs = EXCLUDED.failed_repairs,
        avg_repair_time = EXCLUDED.avg_repair_time,
        total_revenue = EXCLUDED.total_revenue,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer des alertes automatiques
CREATE OR REPLACE FUNCTION create_alert(
    p_alert_type VARCHAR(100),
    p_title VARCHAR(200),
    p_message TEXT,
    p_severity alert_severity_type DEFAULT 'info',
    p_target_user_id UUID DEFAULT NULL,
    p_target_role user_role DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
BEGIN
    INSERT INTO advanced_alerts (
        alert_type, title, message, severity, 
        target_user_id, target_role
    ) VALUES (
        p_alert_type, p_title, p_message, p_severity,
        p_target_user_id, p_target_role
    ) RETURNING id INTO v_alert_id;
    
    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS POUR AUTOMATISATION
-- =====================================================

-- Trigger pour mettre à jour les métriques de performance
CREATE OR REPLACE FUNCTION update_technician_performance_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour les métriques mensuelles
    PERFORM calculate_technician_performance(
        COALESCE(NEW.assigned_technician_id, OLD.assigned_technician_id),
        DATE_TRUNC('month', COALESCE(NEW.created_at, OLD.created_at))::date,
        (DATE_TRUNC('month', COALESCE(NEW.created_at, OLD.created_at)) + INTERVAL '1 month - 1 day')::date
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_technician_performance
    AFTER INSERT OR UPDATE OR DELETE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION update_technician_performance_trigger();

-- Trigger pour créer des alertes automatiques
CREATE OR REPLACE FUNCTION create_repair_alerts_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Alerte pour réparation urgente
    IF NEW.is_urgent = true AND OLD.is_urgent = false THEN
        PERFORM create_alert(
            'urgent_repair',
            'Nouvelle réparation urgente',
            'Une réparation urgente a été créée pour ' || NEW.description,
            'warning',
            NEW.assigned_technician_id
        );
    END IF;
    
    -- Alerte pour réparation en retard
    IF NEW.due_date < CURRENT_DATE AND NEW.status NOT IN ('completed', 'cancelled') THEN
        PERFORM create_alert(
            'overdue_repair',
            'Réparation en retard',
            'La réparation ' || NEW.description || ' est en retard',
            'error',
            NEW.assigned_technician_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_repair_alerts
    AFTER INSERT OR UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION create_repair_alerts_trigger();

-- =====================================================
-- VUES POUR FACILITER LES REQUÊTES
-- =====================================================

-- Vue pour les statistiques consolidées
CREATE OR REPLACE VIEW consolidated_statistics AS
SELECT 
    DATE_TRUNC('day', r.created_at) as date,
    COUNT(*) as total_repairs,
    COUNT(*) FILTER (WHERE r.status = 'completed') as completed_repairs,
    COUNT(*) FILTER (WHERE r.is_urgent = true) as urgent_repairs,
    COUNT(*) FILTER (WHERE r.due_date < CURRENT_DATE AND r.status NOT IN ('completed', 'cancelled')) as overdue_repairs,
    SUM(r.total_price) as total_revenue,
    AVG(EXTRACT(EPOCH FROM (r.updated_at - r.created_at)) / 86400) as avg_repair_time
FROM repairs r
GROUP BY DATE_TRUNC('day', r.created_at)
ORDER BY date DESC;

-- Vue pour les top clients
CREATE OR REPLACE VIEW top_clients AS
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(r.id) as repair_count,
    SUM(r.total_price) as total_spent,
    AVG(r.total_price) as avg_repair_cost
FROM clients c
LEFT JOIN repairs r ON c.id = r.client_id
GROUP BY c.id, c.first_name, c.last_name, c.email
ORDER BY repair_count DESC, total_spent DESC;

-- Vue pour les top appareils
CREATE OR REPLACE VIEW top_devices AS
SELECT 
    d.id,
    d.brand,
    d.model,
    d.type,
    COUNT(r.id) as repair_count,
    SUM(r.total_price) as total_revenue,
    AVG(r.total_price) as avg_repair_cost
FROM devices d
LEFT JOIN repairs r ON d.id = r.device_id
GROUP BY d.id, d.brand, d.model, d.type
ORDER BY repair_count DESC, total_revenue DESC;

COMMENT ON TABLE device_models IS 'Modèles d''appareils avec spécifications et problèmes courants';
COMMENT ON TABLE performance_metrics IS 'Métriques de performance pour les analyses';
COMMENT ON TABLE reports IS 'Rapports générés par les utilisateurs';
COMMENT ON TABLE advanced_alerts IS 'Alertes avancées et notifications';
COMMENT ON TABLE technician_performance IS 'Métriques de performance des techniciens';
COMMENT ON TABLE transactions IS 'Transactions financières de l''atelier';
COMMENT ON TABLE activity_logs IS 'Logs d''activité pour l''audit';
COMMENT ON TABLE advanced_settings IS 'Paramètres de configuration avancés';
