-- =====================================================
-- CORRECTION DE L'ERREUR DE TRIGGER
-- =====================================================

-- 1. Supprimer tous les triggers problématiques
DROP TRIGGER IF EXISTS trigger_update_technician_performance ON repairs;
DROP TRIGGER IF EXISTS trigger_create_repair_alerts ON repairs;

-- 2. Supprimer les fonctions problématiques
DROP FUNCTION IF EXISTS update_technician_performance_trigger();
DROP FUNCTION IF EXISTS create_repair_alerts_trigger();

-- 3. Supprimer les fonctions utilitaires
DROP FUNCTION IF EXISTS calculate_technician_performance(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS create_alert(VARCHAR, VARCHAR, TEXT, alert_severity_type, UUID, user_role);

-- 4. Recréer les fonctions utilitaires avec les bons types

-- Fonction pour calculer les performances des techniciens
CREATE OR REPLACE FUNCTION calculate_technician_performance(
    p_technician_id UUID,
    p_period_start DATE,
    p_period_end DATE
) RETURNS VOID AS $$
BEGIN
    -- Vérifier que la table existe
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'technician_performance') THEN
        RAISE NOTICE 'Table technician_performance does not exist, skipping calculation';
        RETURN;
    END IF;
    
    -- Supprimer les métriques existantes pour cette période
    DELETE FROM technician_performance 
    WHERE technician_id = p_technician_id 
    AND period_start = p_period_start 
    AND period_end = p_period_end;
    
    -- Insérer les nouvelles métriques calculées
    INSERT INTO technician_performance (
        technician_id, period_start, period_end, 
        total_repairs, completed_repairs, avg_repair_time, 
        total_revenue, customer_satisfaction, workshop_id
    )
    SELECT 
        p_technician_id,
        p_period_start,
        p_period_end,
        COUNT(*) as total_repairs,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_repairs,
        AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400) as avg_repair_time,
        SUM(total_price) as total_revenue,
        AVG(COALESCE(customer_rating, 0)) as customer_satisfaction,
        COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) as workshop_id
    FROM repairs 
    WHERE assigned_technician_id = p_technician_id
    AND created_at >= p_period_start 
    AND created_at <= p_period_end;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour créer des alertes
CREATE OR REPLACE FUNCTION create_alert(
    p_alert_type VARCHAR(50),
    p_title VARCHAR(200),
    p_message TEXT,
    p_severity alert_severity_type DEFAULT 'info',
    p_target_user_id UUID DEFAULT NULL,
    p_target_role user_role DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
BEGIN
    -- Vérifier que la table existe
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'advanced_alerts') THEN
        RAISE NOTICE 'Table advanced_alerts does not exist, skipping alert creation';
        RETURN NULL;
    END IF;
    
    INSERT INTO advanced_alerts (
        alert_type, title, message, severity, 
        target_user_id, target_role, workshop_id
    ) VALUES (
        p_alert_type, p_title, p_message, p_severity,
        p_target_user_id, p_target_role,
        COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    ) RETURNING id INTO v_alert_id;
    
    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Recréer les triggers avec la nouvelle logique

-- Trigger pour mettre à jour les métriques de performance
CREATE OR REPLACE FUNCTION update_technician_performance_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_technician_id UUID;
    v_period_start DATE;
    v_period_end DATE;
BEGIN
    -- Convertir et valider les paramètres
    v_technician_id := COALESCE(NEW.assigned_technician_id, OLD.assigned_technician_id)::UUID;
    v_period_start := DATE_TRUNC('month', COALESCE(NEW.created_at, OLD.created_at))::date;
    v_period_end := (DATE_TRUNC('month', COALESCE(NEW.created_at, OLD.created_at)) + INTERVAL '1 month - 1 day')::date;
    
    -- Vérifier que le technicien existe et n'est pas NULL
    IF v_technician_id IS NOT NULL AND v_technician_id != '00000000-0000-0000-0000-000000000000'::UUID THEN
        -- Mettre à jour les métriques mensuelles
        PERFORM calculate_technician_performance(
            v_technician_id,
            v_period_start,
            v_period_end
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger pour créer des alertes automatiques
CREATE OR REPLACE FUNCTION create_repair_alerts_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Alerte pour réparation urgente
    IF NEW.is_urgent = true AND (OLD.is_urgent = false OR OLD IS NULL) THEN
        PERFORM create_alert(
            'urgent_repair',
            'Nouvelle réparation urgente',
            'Une réparation urgente a été créée pour ' || COALESCE(NEW.description, 'un appareil'),
            'warning',
            NEW.assigned_technician_id
        );
    END IF;
    
    -- Alerte pour réparation en retard
    IF NEW.due_date < CURRENT_DATE AND NEW.status NOT IN ('completed', 'cancelled') THEN
        PERFORM create_alert(
            'overdue_repair',
            'Réparation en retard',
            'La réparation ' || COALESCE(NEW.description, '') || ' est en retard',
            'error',
            NEW.assigned_technician_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Créer les triggers
CREATE TRIGGER trigger_update_technician_performance
    AFTER INSERT OR UPDATE OR DELETE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION update_technician_performance_trigger();

CREATE TRIGGER trigger_create_repair_alerts
    AFTER INSERT OR UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION create_repair_alerts_trigger();

-- 7. Fonction de test pour vérifier que tout fonctionne
CREATE OR REPLACE FUNCTION test_trigger_fix()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Vérifier que la fonction calculate_technician_performance existe
    IF EXISTS (SELECT FROM pg_proc WHERE proname = 'calculate_technician_performance') THEN
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '✅ OK'::TEXT, 'Fonction créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que la fonction create_alert existe
    IF EXISTS (SELECT FROM pg_proc WHERE proname = 'create_alert') THEN
        RETURN QUERY SELECT 'Fonction create_alert'::TEXT, '✅ OK'::TEXT, 'Fonction créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction create_alert'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que le trigger update_technician_performance existe
    IF EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trigger_update_technician_performance') THEN
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger create_repair_alerts existe
    IF EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trigger_create_repair_alerts') THEN
        RETURN QUERY SELECT 'Trigger trigger_create_repair_alerts'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_create_repair_alerts'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Tester l'appel de la fonction calculate_technician_performance
    BEGIN
        PERFORM calculate_technician_performance(
            '00000000-0000-0000-0000-000000000000'::UUID,
            CURRENT_DATE,
            CURRENT_DATE
        );
        RETURN QUERY SELECT 'Test appel calculate_technician_performance'::TEXT, '✅ OK'::TEXT, 'Fonction appelable sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test appel calculate_technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''appel: ' || SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Commentaires
COMMENT ON FUNCTION calculate_technician_performance(UUID, DATE, DATE) IS 'Fonction pour calculer les performances des techniciens';
COMMENT ON FUNCTION create_alert(VARCHAR, VARCHAR, TEXT, alert_severity_type, UUID, user_role) IS 'Fonction pour créer des alertes avancées';
COMMENT ON FUNCTION update_technician_performance_trigger() IS 'Trigger pour mettre à jour les métriques de performance';
COMMENT ON FUNCTION create_repair_alerts_trigger() IS 'Trigger pour créer des alertes automatiques';
COMMENT ON FUNCTION test_trigger_fix() IS 'Fonction pour tester la correction des triggers';
