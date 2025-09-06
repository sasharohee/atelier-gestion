-- CRÉATION DES FONCTIONS POUR LES PARAMÈTRES DE FIDÉLITÉ
-- Script pour créer les fonctions manquantes

-- 1. CRÉER LA FONCTION GET_LOYALTY_CONFIG
CREATE OR REPLACE FUNCTION get_loyalty_config(p_workshop_id UUID)
RETURNS TABLE(key TEXT, value TEXT, description TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT lc.key, lc.value, lc.description
    FROM loyalty_config lc
    WHERE lc.workshop_id = p_workshop_id
    ORDER BY lc.key;
END;
$$;

-- 2. CRÉER LA FONCTION GET_LOYALTY_TIERS
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

-- 3. CRÉER LA FONCTION UPDATE_LOYALTY_CONFIG
CREATE OR REPLACE FUNCTION update_loyalty_config(
    p_workshop_id UUID,
    p_key TEXT,
    p_value TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE loyalty_config 
    SET value = p_value
    WHERE workshop_id = p_workshop_id 
    AND key = p_key;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Configuration mise à jour avec succès'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la mise à jour: ' || SQLERRM
        );
END;
$$;

-- 4. CRÉER LA FONCTION UPDATE_LOYALTY_TIER
CREATE OR REPLACE FUNCTION update_loyalty_tier(
    p_workshop_id UUID,
    p_tier_id UUID,
    p_name TEXT,
    p_points_required INTEGER,
    p_discount_percentage INTEGER,
    p_color TEXT,
    p_description TEXT,
    p_is_active BOOLEAN
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE loyalty_tiers_advanced 
    SET 
        name = p_name,
        points_required = p_points_required,
        discount_percentage = p_discount_percentage,
        color = p_color,
        description = p_description,
        is_active = p_is_active
    WHERE id = p_tier_id 
    AND workshop_id = p_workshop_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveau mis à jour avec succès'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la mise à jour: ' || SQLERRM
        );
END;
$$;

-- 5. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION get_loyalty_config(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_loyalty_tiers(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_loyalty_config(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_loyalty_tier(UUID, UUID, TEXT, INTEGER, INTEGER, TEXT, TEXT, BOOLEAN) TO authenticated;

-- 6. CRÉER DES DONNÉES PAR DÉFAUT SI ELLES N'EXISTENT PAS
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
    SELECT 1 FROM loyalty_config lc WHERE lc.workshop_id = u.id AND lc.key = config.key
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
    SELECT 1 FROM loyalty_tiers_advanced lta WHERE lta.workshop_id = u.id AND lta.name = tier.name
);

-- 7. VÉRIFICATION
SELECT 'Fonctions créées avec succès!' as result;

-- Test des fonctions
SELECT 'Test get_loyalty_config:' as test;
SELECT * FROM get_loyalty_config((SELECT id FROM auth.users LIMIT 1));

SELECT 'Test get_loyalty_tiers:' as test;
SELECT * FROM get_loyalty_tiers((SELECT id FROM auth.users LIMIT 1));
