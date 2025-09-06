-- =====================================================
-- CORRECTION DE L'ERREUR DES VUES
-- =====================================================

-- 1. Supprimer les vues existantes qui causent des erreurs
DROP VIEW IF EXISTS consolidated_statistics CASCADE;
DROP VIEW IF EXISTS top_clients CASCADE;
DROP VIEW IF EXISTS top_devices CASCADE;

-- 2. Vérifier que les tables de base ont les colonnes nécessaires
DO $$
BEGIN
    -- Vérifier et ajouter workshop_id à repairs si nécessaire
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'workshop_id') THEN
        ALTER TABLE repairs ADD COLUMN workshop_id UUID;
        UPDATE repairs SET workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) WHERE workshop_id IS NULL;
    END IF;
    
    -- Vérifier et ajouter workshop_id à clients si nécessaire
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'workshop_id') THEN
        ALTER TABLE clients ADD COLUMN workshop_id UUID;
        UPDATE clients SET workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) WHERE workshop_id IS NULL;
    END IF;
    
    -- Vérifier et ajouter workshop_id à devices si nécessaire
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'workshop_id') THEN
        ALTER TABLE devices ADD COLUMN workshop_id UUID;
        UPDATE devices SET workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) WHERE workshop_id IS NULL;
    END IF;
END $$;

-- 3. Recréer les vues avec isolation appropriée

-- Vue consolidated_statistics
CREATE OR REPLACE VIEW consolidated_statistics AS
SELECT 
    DATE_TRUNC('day', r.created_at) as date,
    COUNT(*) as total_repairs,
    COUNT(*) FILTER (WHERE r.status = 'completed') as completed_repairs,
    COUNT(*) FILTER (WHERE r.is_urgent = true) as urgent_repairs,
    COUNT(*) FILTER (WHERE r.due_date < CURRENT_DATE AND r.status NOT IN ('completed', 'cancelled')) as overdue_repairs,
    SUM(r.total_price) as total_revenue,
    AVG(EXTRACT(EPOCH FROM (r.updated_at - r.created_at)) / 86400) as avg_repair_time,
    COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) as workshop_id
FROM repairs r
WHERE r.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
GROUP BY DATE_TRUNC('day', r.created_at)
ORDER BY date DESC;

-- Vue top_clients
CREATE OR REPLACE VIEW top_clients AS
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    COUNT(r.id) as repair_count,
    SUM(r.total_price) as total_spent,
    COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) as workshop_id
FROM clients c
LEFT JOIN repairs r ON c.id = r.client_id
WHERE c.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
GROUP BY c.id, c.first_name, c.last_name, c.email, c.phone
ORDER BY repair_count DESC, total_spent DESC
LIMIT 10;

-- Vue top_devices
CREATE OR REPLACE VIEW top_devices AS
SELECT 
    d.id,
    d.brand,
    d.model,
    d.type,
    COUNT(r.id) as repair_count,
    AVG(r.total_price) as avg_repair_cost,
    COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) as workshop_id
FROM devices d
LEFT JOIN repairs r ON d.id = r.device_id
WHERE d.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
GROUP BY d.id, d.brand, d.model, d.type
ORDER BY repair_count DESC, avg_repair_cost DESC
LIMIT 10;

-- 4. Activer la sécurité sur les vues
ALTER VIEW consolidated_statistics SET (security_barrier = true);
ALTER VIEW top_clients SET (security_barrier = true);
ALTER VIEW top_devices SET (security_barrier = true);

-- 5. Fonction de test pour vérifier les vues
CREATE OR REPLACE FUNCTION test_views_fix()
RETURNS TABLE (
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Vérifier que la vue consolidated_statistics existe
    IF EXISTS (SELECT FROM information_schema.views WHERE table_name = 'consolidated_statistics') THEN
        RETURN QUERY SELECT 'Vue consolidated_statistics'::TEXT, '✅ OK'::TEXT, 'Vue créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vue consolidated_statistics'::TEXT, '❌ ERREUR'::TEXT, 'Vue manquante'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que la vue top_clients existe
    IF EXISTS (SELECT FROM information_schema.views WHERE table_name = 'top_clients') THEN
        RETURN QUERY SELECT 'Vue top_clients'::TEXT, '✅ OK'::TEXT, 'Vue créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vue top_clients'::TEXT, '❌ ERREUR'::TEXT, 'Vue manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que la vue top_devices existe
    IF EXISTS (SELECT FROM information_schema.views WHERE table_name = 'top_devices') THEN
        RETURN QUERY SELECT 'Vue top_devices'::TEXT, '✅ OK'::TEXT, 'Vue créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vue top_devices'::TEXT, '❌ ERREUR'::TEXT, 'Vue manquante'::TEXT;
    END IF;
    
    -- Test 4: Tester l'accès à la vue consolidated_statistics
    BEGIN
        PERFORM COUNT(*) FROM consolidated_statistics LIMIT 1;
        RETURN QUERY SELECT 'Test accès consolidated_statistics'::TEXT, '✅ OK'::TEXT, 'Vue accessible sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test accès consolidated_statistics'::TEXT, '❌ ERREUR'::TEXT, 'Erreur d''accès: ' || SQLERRM::TEXT;
    END;
    
    -- Test 5: Tester l'accès à la vue top_clients
    BEGIN
        PERFORM COUNT(*) FROM top_clients LIMIT 1;
        RETURN QUERY SELECT 'Test accès top_clients'::TEXT, '✅ OK'::TEXT, 'Vue accessible sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test accès top_clients'::TEXT, '❌ ERREUR'::TEXT, 'Erreur d''accès: ' || SQLERRM::TEXT;
    END;
    
    -- Test 6: Tester l'accès à la vue top_devices
    BEGIN
        PERFORM COUNT(*) FROM top_devices LIMIT 1;
        RETURN QUERY SELECT 'Test accès top_devices'::TEXT, '✅ OK'::TEXT, 'Vue accessible sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test accès top_devices'::TEXT, '❌ ERREUR'::TEXT, 'Erreur d''accès: ' || SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Commentaires
COMMENT ON VIEW consolidated_statistics IS 'Vue pour les statistiques consolidées avec isolation par atelier';
COMMENT ON VIEW top_clients IS 'Vue pour les top clients avec isolation par atelier';
COMMENT ON VIEW top_devices IS 'Vue pour les top appareils avec isolation par atelier';
COMMENT ON FUNCTION test_views_fix() IS 'Fonction pour tester la correction des vues';
