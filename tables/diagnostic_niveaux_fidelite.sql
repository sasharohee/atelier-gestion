-- Diagnostic et correction des niveaux de fidélité
-- Date: 2024-01-24

-- ============================================================================
-- 1. DIAGNOSTIC DES TABLES
-- ============================================================================

SELECT '=== DIAGNOSTIC DES TABLES ===' as section;

-- Vérifier si la table client_loyalty_points existe
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'client_loyalty_points';

-- Vérifier la structure de client_loyalty_points
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'client_loyalty_points'
ORDER BY ordinal_position;

-- Vérifier les données dans client_loyalty_points
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN total_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau
FROM client_loyalty_points;

-- Afficher quelques exemples de données
SELECT 
    clp.id,
    clp.client_id,
    clp.total_points,
    clp.used_points,
    clp.current_tier_id,
    clp.user_id,
    c.first_name,
    c.last_name
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LIMIT 5;

-- ============================================================================
-- 2. DIAGNOSTIC DES NIVEAUX DE FIDÉLITÉ
-- ============================================================================

SELECT '=== DIAGNOSTIC DES NIVEAUX ===' as section;

-- Vérifier les niveaux de fidélité
SELECT 
    id,
    name,
    min_points,
    discount_percentage,
    description,
    color
FROM loyalty_tiers
ORDER BY min_points;

-- ============================================================================
-- 3. DIAGNOSTIC DES POLITIQUES RLS
-- ============================================================================

SELECT '=== DIAGNOSTIC RLS ===' as section;

-- Vérifier les politiques RLS sur client_loyalty_points
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'client_loyalty_points';

-- Vérifier si RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'client_loyalty_points';

-- ============================================================================
-- 4. CORRECTION DES DONNÉES MANQUANTES
-- ============================================================================

SELECT '=== CORRECTION DES DONNÉES ===' as section;

-- Créer des entrées pour tous les clients qui n'en ont pas
INSERT INTO client_loyalty_points (client_id, total_points, used_points, current_tier_id, user_id)
SELECT 
    c.id,
    0,
    0,
    (SELECT id FROM loyalty_tiers WHERE min_points = 0 LIMIT 1),
    c.user_id
FROM clients c
WHERE NOT EXISTS (
    SELECT 1 FROM client_loyalty_points clp 
    WHERE clp.client_id = c.id
)
AND c.user_id IS NOT NULL;

-- Mettre à jour les niveaux de fidélité basés sur les points
UPDATE client_loyalty_points 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers 
    WHERE min_points <= client_loyalty_points.total_points 
    ORDER BY min_points DESC 
    LIMIT 1
)
WHERE current_tier_id IS NULL;

-- ============================================================================
-- 5. VÉRIFICATION DES DONNÉES APRÈS CORRECTION
-- ============================================================================

SELECT '=== VÉRIFICATION APRÈS CORRECTION ===' as section;

-- Vérifier les données mises à jour
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN total_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau
FROM client_loyalty_points;

-- Afficher les clients avec leurs niveaux
SELECT 
    clp.id,
    clp.client_id,
    clp.total_points,
    clp.used_points,
    clp.current_tier_id,
    c.first_name,
    c.last_name,
    lt.name as niveau_nom,
    lt.min_points as niveau_min_points
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id
ORDER BY clp.total_points DESC
LIMIT 10;

-- ============================================================================
-- 6. TEST DE LA REQUÊTE DE L'APPLICATION
-- ============================================================================

SELECT '=== TEST REQUÊTE APPLICATION ===' as section;

-- Simuler la requête de l'application
SELECT 
    clp.*,
    c.first_name,
    c.last_name,
    c.email,
    lt.name as tier_name,
    lt.min_points as tier_min_points,
    lt.discount_percentage as tier_discount,
    lt.description as tier_description,
    lt.color as tier_color
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id
ORDER BY clp.total_points DESC
LIMIT 5;

-- ============================================================================
-- 7. MESSAGE DE SUCCÈS
-- ============================================================================

SELECT '✅ Diagnostic et correction terminés !' as result;
SELECT '📊 Les niveaux de fidélité devraient maintenant s''afficher correctement' as message;
SELECT '🔧 Vérifiez l''application après avoir exécuté ce script' as verification;
