-- Correction du chargement des clients pour les points de fidélité
-- Ce script corrige le problème de chargement des données clients

-- 1. VÉRIFIER SI LA VUE CLIENT_LOYALTY_POINTS EXISTE
SELECT '🔍 VÉRIFICATION DE LA VUE CLIENT_LOYALTY_POINTS:' as info;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'client_loyalty_points' 
AND table_schema = 'public';

-- 2. CRÉER LA VUE SI ELLE N'EXISTE PAS
SELECT '🔧 CRÉATION DE LA VUE CLIENT_LOYALTY_POINTS...' as info;

CREATE OR REPLACE VIEW client_loyalty_points AS
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    COALESCE(c.loyalty_points, 0) as total_points,
    c.current_tier_id,
    lt.name as tier_name,
    lt.description as tier_description,
    lt.points_required as tier_points_required,
    lt.discount_percentage as tier_discount_percentage,
    lt.color as tier_color,
    c.created_at,
    c.updated_at
FROM clients c
LEFT JOIN loyalty_tiers lt ON c.current_tier_id = lt.id
ORDER BY COALESCE(c.loyalty_points, 0) DESC;

-- 3. VÉRIFIER LA STRUCTURE DE LA VUE
SELECT '📋 STRUCTURE DE LA VUE:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'client_loyalty_points' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. TESTER LA VUE
SELECT '🧪 TEST DE LA VUE:' as info;

SELECT 
    id,
    first_name,
    last_name,
    total_points,
    tier_name,
    tier_points_required
FROM client_loyalty_points
LIMIT 5;

-- 5. VÉRIFIER LES DONNÉES DIRECTES DE LA TABLE CLIENTS
SELECT '👥 DONNÉES DIRECTES DE LA TABLE CLIENTS:' as info;

SELECT 
    id,
    first_name,
    last_name,
    email,
    COALESCE(loyalty_points, 0) as loyalty_points,
    current_tier_id,
    created_at,
    updated_at
FROM clients
ORDER BY COALESCE(loyalty_points, 0) DESC
LIMIT 10;

-- 6. COMPARER LES DONNÉES
SELECT '📊 COMPARAISON DES DONNÉES:' as info;

SELECT 
    'Table clients' as source,
    COUNT(*) as total_clients,
    COUNT(loyalty_points) as clients_avec_points,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients

UNION ALL

SELECT 
    'Vue client_loyalty_points' as source,
    COUNT(*) as total_clients,
    COUNT(total_points) as clients_avec_points,
    AVG(total_points) as moyenne_points
FROM client_loyalty_points;

-- 7. VÉRIFIER LES PERMISSIONS SUR LA VUE
SELECT '🔐 PERMISSIONS SUR LA VUE:' as info;

GRANT SELECT ON client_loyalty_points TO authenticated;
GRANT SELECT ON client_loyalty_points TO anon;

-- 8. CRÉER UNE FONCTION DE RECHARGEMENT
SELECT '⚙️ CRÉATION D''UNE FONCTION DE RECHARGEMENT...' as info;

CREATE OR REPLACE FUNCTION refresh_client_loyalty_data()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Retourner les statistiques mises à jour
    SELECT json_build_object(
        'success', true,
        'total_clients', (SELECT COUNT(*) FROM clients),
        'clients_with_points', (SELECT COUNT(*) FROM clients WHERE COALESCE(loyalty_points, 0) > 0),
        'average_points', (SELECT AVG(COALESCE(loyalty_points, 0)) FROM clients),
        'message', 'Données mises à jour avec succès'
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION refresh_client_loyalty_data() TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_client_loyalty_data() TO anon;

-- 9. TESTER LA FONCTION DE RECHARGEMENT
SELECT '🧪 TEST DE LA FONCTION DE RECHARGEMENT:' as info;

SELECT refresh_client_loyalty_data();

-- 10. RECOMMANDATIONS POUR LE CODE FRONTEND
SELECT '💡 RECOMMANDATIONS POUR LE CODE FRONTEND:' as info;

SELECT '1. Modifier la requête pour charger directement depuis clients au lieu de client_loyalty_points' as recommandation
UNION ALL
SELECT '2. Utiliser cette requête: SELECT id, first_name, last_name, email, COALESCE(loyalty_points, 0) as loyalty_points, current_tier_id FROM clients'
UNION ALL
SELECT '3. Joindre avec loyalty_tiers pour obtenir les informations de niveau'
UNION ALL
SELECT '4. Appeler loadData() après chaque modification de points'
UNION ALL
SELECT '5. Vérifier que les colonnes loyalty_points et current_tier_id existent';

-- 11. REQUÊTE ALTERNATIVE POUR LE FRONTEND
SELECT '📝 REQUÊTE ALTERNATIVE POUR LE FRONTEND:' as info;

SELECT 'SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    COALESCE(c.loyalty_points, 0) as loyalty_points,
    c.current_tier_id,
    lt.name as tier_name,
    lt.description as tier_description,
    lt.points_required as tier_points_required,
    lt.discount_percentage as tier_discount_percentage,
    lt.color as tier_color,
    c.created_at,
    c.updated_at
FROM clients c
LEFT JOIN loyalty_tiers lt ON c.current_tier_id = lt.id
ORDER BY COALESCE(c.loyalty_points, 0) DESC;' as requete_alternative;

SELECT '✅ Correction du chargement terminée !' as result;
