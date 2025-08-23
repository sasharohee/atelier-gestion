-- Script pour corriger les fonctions et triggers
-- Ce script doit être exécuté APRÈS fix_unrestricted_tables.sql

-- 1. Nettoyer les triggers existants
DROP TRIGGER IF EXISTS trigger_update_technician_performance ON repairs;
DROP TRIGGER IF EXISTS trigger_create_repair_alerts ON repairs;

-- 2. Nettoyer les fonctions existantes
DROP FUNCTION IF EXISTS update_technician_performance_trigger();
DROP FUNCTION IF EXISTS create_repair_alerts_trigger();
DROP FUNCTION IF EXISTS calculate_technician_performance(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS create_alert(VARCHAR, VARCHAR, TEXT, alert_severity_type, UUID);

-- 3. Créer les fonctions utilitaires
CREATE OR REPLACE FUNCTION calculate_technician_performance(
    p_technician_id UUID,
    p_period_start DATE,
    p_period_end DATE
)
RETURNS VOID AS $$
DECLARE
    v_total_repairs INTEGER;
    v_completed_repairs INTEGER;
    v_avg_repair_time NUMERIC(10,2);
    v_total_revenue NUMERIC(10,2);
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;
    
    -- Calculer les métriques
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'completed' THEN 1 END),
        COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400), 0),
        COALESCE(SUM(total_cost), 0)
    INTO v_total_repairs, v_completed_repairs, v_avg_repair_time, v_total_revenue
    FROM repairs 
    WHERE assigned_technician_id = p_technician_id
    AND workshop_id = v_workshop_id
    AND created_at >= p_period_start 
    AND created_at <= p_period_end;
    
    -- Insérer ou mettre à jour les métriques
    INSERT INTO technician_performance (
        technician_id, period_start, period_end, 
        total_repairs, completed_repairs, avg_repair_time, 
        total_revenue, workshop_id
    ) VALUES (
        p_technician_id, p_period_start, p_period_end,
        v_total_repairs, v_completed_repairs, v_avg_repair_time,
        v_total_revenue, v_workshop_id
    )
    ON CONFLICT (technician_id, period_start, period_end)
    DO UPDATE SET
        total_repairs = EXCLUDED.total_repairs,
        completed_repairs = EXCLUDED.completed_repairs,
        avg_repair_time = EXCLUDED.avg_repair_time,
        total_revenue = EXCLUDED.total_revenue,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_alert(
    p_alert_type VARCHAR(50),
    p_title VARCHAR(200),
    p_message TEXT,
    p_severity alert_severity_type DEFAULT 'info',
    p_target_user_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_workshop_id UUID;
    v_user_role user_role;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;
    
    -- Obtenir le rôle de l'utilisateur
    SELECT (raw_user_meta_data->>'role')::user_role INTO v_user_role
    FROM auth.users WHERE id = auth.uid();
    
    -- Créer l'alerte
    INSERT INTO advanced_alerts (
        alert_type, title, message, severity, 
        target_user_id, target_role, workshop_id
    ) VALUES (
        p_alert_type, p_title, p_message, p_severity,
        p_target_user_id, v_user_role, v_workshop_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Créer les fonctions de triggers
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
    
    -- Vérifier que le technicien existe
    IF v_technician_id IS NOT NULL THEN
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

-- 5. Créer les triggers
CREATE TRIGGER trigger_update_technician_performance
    AFTER INSERT OR UPDATE OR DELETE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION update_technician_performance_trigger();

CREATE TRIGGER trigger_create_repair_alerts
    AFTER INSERT OR UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION create_repair_alerts_trigger();

-- 6. Fonction de test
CREATE OR REPLACE FUNCTION test_functions_and_triggers()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Vérifier que les fonctions existent
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'calculate_technician_performance') THEN
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '✅ Existe'::TEXT, 'Fonction créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '❌ Manquante'::TEXT, 'Fonction non trouvée'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que les triggers existent
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_technician_performance') THEN
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '✅ Existe'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '❌ Manquant'::TEXT, 'Trigger non trouvé'::TEXT;
    END IF;
    
    -- Test 3: Tester l'appel de la fonction
    BEGIN
        PERFORM calculate_technician_performance(
            '00000000-0000-0000-0000-000000000000'::UUID,
            CURRENT_DATE,
            CURRENT_DATE
        );
        RETURN QUERY SELECT 'Test appel fonction'::TEXT, '✅ Réussi'::TEXT, 'Fonction exécutée sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test appel fonction'::TEXT, '❌ Échec'::TEXT, SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- 7. Afficher le statut
SELECT 'Script fix_functions_and_triggers.sql exécuté avec succès' as status;
