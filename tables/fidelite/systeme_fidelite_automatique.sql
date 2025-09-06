-- SYSTÈME DE FIDÉLITÉ AUTOMATIQUE BASÉ SUR LES DÉPENSES
-- Ce script implémente un système qui attribue automatiquement des points de fidélité
-- en fonction des dépenses des clients

-- 1. CRÉER LA TABLE DE CONFIGURATION DU SYSTÈME DE FIDÉLITÉ
CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. INSÉRER LA CONFIGURATION PAR DÉFAUT
INSERT INTO loyalty_config (key, value, description) VALUES
('points_per_euro', '1', 'Nombre de points attribués par euro dépensé'),
('minimum_purchase_for_points', '5', 'Montant minimum en euros pour obtenir des points'),
('bonus_threshold_50', '50', 'Seuil en euros pour bonus de 10% de points'),
('bonus_threshold_100', '100', 'Seuil en euros pour bonus de 20% de points'),
('bonus_threshold_200', '200', 'Seuil en euros pour bonus de 30% de points'),
('points_expiry_months', '24', 'Durée de validité des points en mois'),
('auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité')
ON CONFLICT (key) DO NOTHING;

-- 3. CRÉER LA TABLE DES NIVEAUX DE FIDÉLITÉ AVANCÉS
CREATE TABLE IF NOT EXISTS loyalty_tiers_advanced (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT DEFAULT '#000000',
    benefits TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. INSÉRER LES NIVEAUX DE FIDÉLITÉ PAR DÉFAUT
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color, benefits) VALUES
('Bronze', 'Niveau de base', 0, 0, '#CD7F32', ARRAY['Accès aux promotions de base']),
('Argent', 'Client régulier', 100, 5, '#C0C0C0', ARRAY['5% de réduction', 'Promotions exclusives']),
('Or', 'Client fidèle', 500, 10, '#FFD700', ARRAY['10% de réduction', 'Service prioritaire', 'Garantie étendue']),
('Platine', 'Client VIP', 1000, 15, '#E5E4E2', ARRAY['15% de réduction', 'Service VIP', 'Garantie étendue', 'Rendez-vous prioritaires']),
('Diamant', 'Client Premium', 2000, 20, '#B9F2FF', ARRAY['20% de réduction', 'Service Premium', 'Garantie étendue', 'Rendez-vous prioritaires', 'Support dédié'])
ON CONFLICT DO NOTHING;

-- 5. CRÉER LA FONCTION POUR CALCULER LES POINTS AUTOMATIQUEMENT
CREATE OR REPLACE FUNCTION calculate_loyalty_points(
    p_amount DECIMAL(10,2),
    p_client_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_points_per_euro INTEGER;
    v_minimum_purchase DECIMAL(10,2);
    v_bonus_50 DECIMAL(10,2);
    v_bonus_100 DECIMAL(10,2);
    v_bonus_200 DECIMAL(10,2);
    v_base_points INTEGER;
    v_bonus_points INTEGER;
    v_total_points INTEGER;
BEGIN
    -- Récupérer la configuration
    SELECT 
        CAST(value AS INTEGER) INTO v_points_per_euro
    FROM loyalty_config 
    WHERE key = 'points_per_euro';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_minimum_purchase
    FROM loyalty_config 
    WHERE key = 'minimum_purchase_for_points';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_bonus_50
    FROM loyalty_config 
    WHERE key = 'bonus_threshold_50';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_bonus_100
    FROM loyalty_config 
    WHERE key = 'bonus_threshold_100';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_bonus_200
    FROM loyalty_config 
    WHERE key = 'bonus_threshold_200';
    
    -- Vérifier le montant minimum
    IF p_amount < v_minimum_purchase THEN
        RETURN 0;
    END IF;
    
    -- Calculer les points de base
    v_base_points := FLOOR(p_amount * v_points_per_euro);
    
    -- Calculer les bonus
    v_bonus_points := 0;
    
    IF p_amount >= v_bonus_200 THEN
        v_bonus_points := FLOOR(v_base_points * 0.30); -- 30% de bonus
    ELSIF p_amount >= v_bonus_100 THEN
        v_bonus_points := FLOOR(v_base_points * 0.20); -- 20% de bonus
    ELSIF p_amount >= v_bonus_50 THEN
        v_bonus_points := FLOOR(v_base_points * 0.10); -- 10% de bonus
    END IF;
    
    v_total_points := v_base_points + v_bonus_points;
    
    RETURN v_total_points;
END;
$$ LANGUAGE plpgsql;

-- 6. CRÉER LA FONCTION POUR ATTRIBUER AUTOMATIQUEMENT LES POINTS
CREATE OR REPLACE FUNCTION auto_add_loyalty_points_from_purchase(
    p_client_id UUID,
    p_amount DECIMAL(10,2),
    p_source_type TEXT DEFAULT 'purchase',
    p_description TEXT DEFAULT 'Achat automatique',
    p_reference_id UUID DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_points_to_add INTEGER;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_current_tier_id UUID;
    v_new_tier_id UUID;
    v_result JSON;
BEGIN
    -- Calculer les points à attribuer
    v_points_to_add := calculate_loyalty_points(p_amount, p_client_id);
    
    IF v_points_to_add = 0 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Montant insuffisant pour obtenir des points',
            'amount', p_amount,
            'points_earned', 0
        );
    END IF;
    
    -- Récupérer les points actuels du client
    SELECT COALESCE(loyalty_points, 0), current_tier_id
    INTO v_current_points, v_current_tier_id
    FROM clients
    WHERE id = p_client_id;
    
    -- Mettre à jour les points du client
    UPDATE clients 
    SET 
        loyalty_points = v_current_points + v_points_to_add,
        updated_at = NOW()
    WHERE id = p_client_id;
    
    v_new_points := v_current_points + v_points_to_add;
    
    -- Déterminer le nouveau niveau de fidélité
    SELECT id INTO v_new_tier_id
    FROM loyalty_tiers_advanced
    WHERE points_required <= v_new_points
    AND is_active = true
    ORDER BY points_required DESC
    LIMIT 1;
    
    -- Mettre à jour le niveau si nécessaire
    IF v_new_tier_id IS NOT NULL AND v_new_tier_id != v_current_tier_id THEN
        UPDATE clients 
        SET 
            current_tier_id = v_new_tier_id,
            updated_at = NOW()
        WHERE id = p_client_id;
    END IF;
    
    -- Enregistrer l'historique
    INSERT INTO loyalty_points_history (
        client_id,
        points_change,
        points_type,
        source_type,
        description,
        reference_id,
        points_before,
        points_after,
        created_at
    ) VALUES (
        p_client_id,
        v_points_to_add,
        'earned',
        p_source_type,
        p_description,
        p_reference_id,
        v_current_points,
        v_new_points,
        NOW()
    );
    
    -- Préparer le résultat
    v_result := json_build_object(
        'success', true,
        'message', 'Points de fidélité attribués avec succès',
        'client_id', p_client_id,
        'amount', p_amount,
        'points_earned', v_points_to_add,
        'points_before', v_current_points,
        'points_after', v_new_points,
        'old_tier_id', v_current_tier_id,
        'new_tier_id', v_new_tier_id,
        'tier_upgraded', v_new_tier_id != v_current_tier_id
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- 7. CRÉER LA FONCTION POUR ATTRIBUER DES POINTS DEPUIS LES VENTES
CREATE OR REPLACE FUNCTION auto_add_loyalty_points_from_sale(
    p_sale_id UUID
) RETURNS JSON AS $$
DECLARE
    v_sale_record RECORD;
    v_points_result JSON;
BEGIN
    -- Récupérer les informations de la vente
    SELECT 
        s.client_id,
        s.total,
        s.id
    INTO v_sale_record
    FROM sales s
    WHERE s.id = p_sale_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Vente non trouvée'
        );
    END IF;
    
    -- Attribuer les points automatiquement
    v_points_result := auto_add_loyalty_points_from_purchase(
        v_sale_record.client_id,
        v_sale_record.total,
        'sale',
        'Points de fidélité - Vente #' || v_sale_record.id,
        v_sale_record.id
    );
    
    RETURN v_points_result;
END;
$$ LANGUAGE plpgsql;

-- 8. CRÉER LA FONCTION POUR ATTRIBUER DES POINTS DEPUIS LES RÉPARATIONS
CREATE OR REPLACE FUNCTION auto_add_loyalty_points_from_repair(
    p_repair_id UUID
) RETURNS JSON AS $$
DECLARE
    v_repair_record RECORD;
    v_points_result JSON;
BEGIN
    -- Récupérer les informations de la réparation
    SELECT 
        r.client_id,
        r.total_price,
        r.id
    INTO v_repair_record
    FROM repairs r
    WHERE r.id = p_repair_id
    AND r.is_paid = true; -- Seulement si la réparation est payée
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Réparation non trouvée ou non payée'
        );
    END IF;
    
    -- Attribuer les points automatiquement
    v_points_result := auto_add_loyalty_points_from_purchase(
        v_repair_record.client_id,
        v_repair_record.total_price,
        'repair',
        'Points de fidélité - Réparation #' || v_repair_record.id,
        v_repair_record.id
    );
    
    RETURN v_points_result;
END;
$$ LANGUAGE plpgsql;

-- 9. CRÉER LES TRIGGERS POUR L'AUTOMATISATION
-- Trigger pour les ventes
CREATE OR REPLACE FUNCTION trigger_auto_loyalty_points_sale()
RETURNS TRIGGER AS $$
BEGIN
    -- Seulement si la vente est complétée
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        PERFORM auto_add_loyalty_points_from_sale(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour les réparations
CREATE OR REPLACE FUNCTION trigger_auto_loyalty_points_repair()
RETURNS TRIGGER AS $$
BEGIN
    -- Seulement si la réparation passe à "payée"
    IF NEW.is_paid = true AND OLD.is_paid = false THEN
        PERFORM auto_add_loyalty_points_from_repair(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. ATTACHER LES TRIGGERS
DROP TRIGGER IF EXISTS auto_loyalty_points_sale_trigger ON sales;
CREATE TRIGGER auto_loyalty_points_sale_trigger
    AFTER UPDATE ON sales
    FOR EACH ROW
    EXECUTE FUNCTION trigger_auto_loyalty_points_sale();

DROP TRIGGER IF EXISTS auto_loyalty_points_repair_trigger ON repairs;
CREATE TRIGGER auto_loyalty_points_repair_trigger
    AFTER UPDATE ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_auto_loyalty_points_repair();

-- 11. CRÉER UNE VUE POUR LE TABLEAU DE BORD DE FIDÉLITÉ
CREATE OR REPLACE VIEW loyalty_dashboard AS
SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.email,
    COALESCE(c.loyalty_points, 0) as current_points,
    lt.name as current_tier,
    lt.discount_percentage,
    lt.color as tier_color,
    lt.benefits,
    (SELECT COUNT(*) FROM loyalty_points_history lph WHERE lph.client_id = c.id) as total_transactions,
    (SELECT SUM(points_change) FROM loyalty_points_history lph WHERE lph.client_id = c.id AND lph.points_type = 'earned') as total_points_earned,
    (SELECT SUM(points_change) FROM loyalty_points_history lph WHERE lph.client_id = c.id AND lph.points_type = 'used') as total_points_used,
    c.created_at as client_since,
    c.updated_at as last_activity
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE COALESCE(c.loyalty_points, 0) > 0
ORDER BY c.loyalty_points DESC;

-- 12. CRÉER UNE FONCTION POUR OBTENIR LES STATISTIQUES DE FIDÉLITÉ
CREATE OR REPLACE FUNCTION get_loyalty_statistics()
RETURNS JSON AS $$
DECLARE
    v_stats JSON;
BEGIN
    SELECT json_build_object(
        'total_clients_with_points', COUNT(*),
        'average_points', AVG(COALESCE(loyalty_points, 0)),
        'total_points_distributed', SUM(COALESCE(loyalty_points, 0)),
        'tier_distribution', json_object_agg(
            COALESCE(lt.name, 'Sans niveau'), 
            COUNT(*)
        ),
        'top_clients', (
            SELECT json_agg(
                json_build_object(
                    'client_id', c.id,
                    'name', c.first_name || ' ' || c.last_name,
                    'points', c.loyalty_points,
                    'tier', COALESCE(lt.name, 'Sans niveau')
                )
            )
            FROM clients c
            LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
            WHERE COALESCE(c.loyalty_points, 0) > 0
            ORDER BY c.loyalty_points DESC
            LIMIT 10
        )
    ) INTO v_stats
    FROM clients c
    LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- 13. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION calculate_loyalty_points(DECIMAL, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION auto_add_loyalty_points_from_purchase(UUID, DECIMAL, TEXT, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION auto_add_loyalty_points_from_sale(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION auto_add_loyalty_points_from_repair(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_loyalty_statistics() TO authenticated;

GRANT SELECT ON loyalty_dashboard TO authenticated;
GRANT SELECT ON loyalty_config TO authenticated;
GRANT SELECT ON loyalty_tiers_advanced TO authenticated;

-- 14. MESSAGE DE CONFIRMATION
SELECT '✅ Système de fidélité automatique créé avec succès !' as status;

-- 15. INSTRUCTIONS D'UTILISATION
SELECT '📋 INSTRUCTIONS D''UTILISATION:' as info;

SELECT '1. Configuration: Modifiez les valeurs dans loyalty_config pour personnaliser le système' as instruction;
SELECT '2. Test: Utilisez auto_add_loyalty_points_from_purchase() pour tester manuellement' as instruction;
SELECT '3. Automatique: Les points sont attribués automatiquement lors des ventes/réparations' as instruction;
SELECT '4. Tableau de bord: Consultez loyalty_dashboard pour voir tous les clients' as instruction;
SELECT '5. Statistiques: Utilisez get_loyalty_statistics() pour les métriques' as instruction;

-- 16. EXEMPLE D'UTILISATION
SELECT '🧪 EXEMPLE D''UTILISATION:' as info;

SELECT '-- Attribuer des points manuellement pour un achat de 50€' as example;
SELECT 'SELECT auto_add_loyalty_points_from_purchase(''client_id_ici'', 50.00, ''test'', ''Test manuel'');' as example;

SELECT '-- Voir les statistiques de fidélité' as example;
SELECT 'SELECT get_loyalty_statistics();' as example;

SELECT '-- Consulter le tableau de bord' as example;
SELECT 'SELECT * FROM loyalty_dashboard;' as example;





