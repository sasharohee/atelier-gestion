-- CRÉATION DES FONCTIONS D'ISOLATION
-- Script simple pour créer les fonctions manquantes

-- 1. AJOUTER WORKSHOP_ID AUX TABLES SI NÉCESSAIRE
ALTER TABLE loyalty_config ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id);
ALTER TABLE loyalty_tiers_advanced ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id);

-- 2. MIGRER LES DONNÉES EXISTANTES
UPDATE loyalty_config SET workshop_id = (SELECT id FROM auth.users LIMIT 1) WHERE workshop_id IS NULL;
UPDATE loyalty_tiers_advanced SET workshop_id = (SELECT id FROM auth.users LIMIT 1) WHERE workshop_id IS NULL;

-- 3. CRÉER LA FONCTION GET_LOYALTY_TIERS
CREATE OR REPLACE FUNCTION get_loyalty_tiers(p_workshop_id UUID)
RETURNS TABLE(
    id UUID,
    name TEXT,
    points_required INTEGER,
    discount_percentage INTEGER,
    color TEXT,
    description TEXT,
    is_active BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lta.id,
        lta.name,
        lta.points_required,
        lta.discount_percentage,
        lta.color,
        lta.description,
        lta.is_active
    FROM loyalty_tiers_advanced lta
    WHERE lta.workshop_id = p_workshop_id
    ORDER BY lta.points_required;
END;
$$;

-- 4. CRÉER LA FONCTION GET_LOYALTY_CONFIG
CREATE OR REPLACE FUNCTION get_loyalty_config(p_workshop_id UUID)
RETURNS TABLE(key TEXT, value TEXT, description TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT lc.key, lc.value, lc.description
    FROM loyalty_config lc
    WHERE lc.workshop_id = p_workshop_id;
END;
$$;

-- 5. CRÉER LA FONCTION UPDATE_CLIENT_TIERS_BY_WORKSHOP
CREATE OR REPLACE FUNCTION update_client_tiers_by_workshop(p_workshop_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE clients 
    SET current_tier_id = (
        SELECT lta.id 
        FROM loyalty_tiers_advanced lta
        WHERE lta.points_required <= clients.loyalty_points 
        AND lta.is_active = true
        AND lta.workshop_id = p_workshop_id
        ORDER BY lta.points_required DESC 
        LIMIT 1
    )
    WHERE loyalty_points > 0
    AND workshop_id = p_workshop_id;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux mis à jour avec succès',
        'clients_updated', v_updated_count
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la mise à jour des niveaux: ' || SQLERRM
        );
END;
$$;

-- 6. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION get_loyalty_tiers(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_loyalty_config(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_client_tiers_by_workshop(UUID) TO authenticated;

-- 7. CRÉER DES DONNÉES PAR DÉFAUT POUR L'UTILISATEUR ACTUEL
INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    u.id,
    config.key,
    config.value,
    config.description
FROM auth.users u
CROSS JOIN (VALUES 
    ('points_per_euro', '1', 'Points gagnés par euro dépensé'),
    ('minimum_purchase', '10', 'Montant minimum pour gagner des points'),
    ('bonus_threshold', '100', 'Seuil pour bonus de points'),
    ('bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
    ('points_expiry_days', '365', 'Durée de validité des points en jours')
) AS config(key, value, description)
WHERE NOT EXISTS (
    SELECT 1 FROM loyalty_config lc WHERE lc.workshop_id = u.id
);

INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    u.id,
    tier.name,
    tier.points_required,
    tier.discount_percentage,
    tier.color,
    tier.description,
    tier.is_active
FROM auth.users u
CROSS JOIN (VALUES 
    ('Bronze', 0, 0, '#CD7F32', 'Niveau de base', true),
    ('Argent', 100, 5, '#C0C0C0', '5% de réduction', true),
    ('Or', 500, 10, '#FFD700', '10% de réduction', true),
    ('Platine', 1000, 15, '#E5E4E2', '15% de réduction', true),
    ('Diamant', 2000, 20, '#B9F2FF', '20% de réduction', true)
) AS tier(name, points_required, discount_percentage, color, description, is_active)
WHERE NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta WHERE lta.workshop_id = u.id
);

-- 8. VÉRIFICATION
SELECT 'Fonctions créées avec succès!' as result;
SELECT 'Test des fonctions:' as test;

-- Test get_loyalty_tiers
SELECT 'get_loyalty_tiers fonctionne' as test_result
WHERE EXISTS (
    SELECT 1 FROM get_loyalty_tiers((SELECT id FROM auth.users LIMIT 1))
);

-- Test get_loyalty_config
SELECT 'get_loyalty_config fonctionne' as test_result
WHERE EXISTS (
    SELECT 1 FROM get_loyalty_config((SELECT id FROM auth.users LIMIT 1))
);





