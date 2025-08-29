-- Ajustement des niveaux de fidélité avec des seuils plus réalistes
-- Ce script met à jour les seuils des niveaux de fidélité

-- 1. SUPPRIMER LES NIVEAUX EXISTANTS
SELECT '🗑️ SUPPRESSION DES NIVEAUX EXISTANTS...' as info;

DELETE FROM loyalty_tiers;

-- 2. CRÉER LES NOUVEAUX NIVEAUX AVEC DES SEUILS PLUS RÉALISTES
SELECT '🎯 CRÉATION DES NOUVEAUX NIVEAUX...' as info;

INSERT INTO loyalty_tiers (name, description, min_points, points_required, discount_percentage, color) 
VALUES 
    ('Bronze', 'Niveau de base - Nouveau client', 0, 0, 0, '#CD7F32'),
    ('Argent', 'Client régulier - 5 réparations', 0, 500, 5, '#C0C0C0'),
    ('Or', 'Client fidèle - 15 réparations', 500, 1500, 10, '#FFD700'),
    ('Platine', 'Client VIP - 30 réparations', 1500, 3000, 15, '#E5E4E2'),
    ('Diamant', 'Client premium - 50 réparations', 3000, 5000, 20, '#B9F2FF');

-- 3. RECALCULER LES NIVEAUX DES CLIENTS EXISTANTS
SELECT '🔄 RECALCUL DES NIVEAUX DES CLIENTS...' as info;

-- Mettre à jour les niveaux basés sur les points actuels
UPDATE clients 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers 
    WHERE points_required <= COALESCE(clients.loyalty_points, 0)
    ORDER BY points_required DESC 
    LIMIT 1
)
WHERE current_tier_id IS NOT NULL;

-- Assigner le niveau Bronze aux clients sans niveau
UPDATE clients 
SET current_tier_id = (SELECT id FROM loyalty_tiers WHERE name = 'Bronze' LIMIT 1)
WHERE current_tier_id IS NULL;

-- 4. VÉRIFICATION DES RÉSULTATS
SELECT '🔍 VÉRIFICATION DES RÉSULTATS...' as info;

-- Afficher les nouveaux niveaux
SELECT 
    name,
    description,
    min_points,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers
ORDER BY points_required;

-- Statistiques des clients par niveau
SELECT 
    lt.name as niveau,
    COUNT(c.id) as nombre_clients,
    AVG(COALESCE(c.loyalty_points, 0)) as moyenne_points,
    MIN(COALESCE(c.loyalty_points, 0)) as min_points,
    MAX(COALESCE(c.loyalty_points, 0)) as max_points
FROM loyalty_tiers lt
LEFT JOIN clients c ON lt.id = c.current_tier_id
GROUP BY lt.id, lt.name, lt.points_required
ORDER BY lt.points_required;

-- 5. TEST AVEC UN CLIENT
SELECT '🧪 TEST AVEC UN CLIENT...' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer un client pour le test
    SELECT id INTO v_client_id FROM clients LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
        -- Test d'ajout de points pour atteindre le niveau Argent
        SELECT add_loyalty_points(v_client_id, 600, 'Test ajustement niveaux') INTO v_result;
        
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ Test réussi: Points ajoutés pour niveau Argent';
            RAISE NOTICE 'Détails: %', v_result;
        ELSE
            RAISE NOTICE '❌ Test échoué: %', v_result->>'error';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun client trouvé pour le test';
    END IF;
END $$;

SELECT '✅ Ajustement des niveaux terminé !' as result;
