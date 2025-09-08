-- Script de test direct pour mettre à jour le niveau Argent
-- Exécutez ces requêtes dans l'ordre dans Supabase

-- 1. D'abord, voir l'état actuel
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    updated_at
FROM loyalty_tiers_advanced
WHERE name = 'Argent';

-- 2. Mettre à jour directement (remplacez l'ID par l'ID réel de la requête précédente)
UPDATE loyalty_tiers_advanced 
SET 
    points_required = 255,
    updated_at = NOW()
WHERE name = 'Argent';

-- 3. Vérifier que la mise à jour a fonctionné
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    updated_at
FROM loyalty_tiers_advanced
WHERE name = 'Argent';

-- 4. Si ça marche, remettre à 100 pour le test
UPDATE loyalty_tiers_advanced 
SET 
    points_required = 100,
    updated_at = NOW()
WHERE name = 'Argent';

-- 5. Vérification finale
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    updated_at
FROM loyalty_tiers_advanced
WHERE name = 'Argent';
