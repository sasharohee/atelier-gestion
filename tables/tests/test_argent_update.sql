-- Test direct de mise à jour du niveau Argent
-- Exécutez ces requêtes dans l'ordre dans Supabase

-- 1. Voir l'état actuel du niveau Argent
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    updated_at
FROM loyalty_tiers_advanced
WHERE name = 'Argent';

-- 2. Mettre à jour le niveau Argent à 255 points
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

-- 4. Remettre à 100 points (valeur originale)
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
