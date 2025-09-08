-- Script de diagnostic simple pour les niveaux de fidélité
-- Exécutez ces requêtes une par une dans Supabase

-- 1. Vérifier que la table existe et sa structure
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'loyalty_tiers_advanced'
ORDER BY ordinal_position;

-- 2. Voir tous les niveaux actuels
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    description,
    is_active,
    created_at,
    updated_at
FROM loyalty_tiers_advanced
ORDER BY points_required;

-- 3. Vérifier spécifiquement le niveau Argent
SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    updated_at
FROM loyalty_tiers_advanced
WHERE name = 'Argent';

-- 4. Compter les niveaux par nom (détecter les doublons)
SELECT 
    name,
    COUNT(*) as count
FROM loyalty_tiers_advanced
GROUP BY name
ORDER BY count DESC;

-- 5. Vérifier les permissions RLS (version corrigée)
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'loyalty_tiers_advanced';

-- 6. Test de mise à jour directe (décommentez et remplacez l'ID)
-- UPDATE loyalty_tiers_advanced 
-- SET points_required = 255, updated_at = NOW()
-- WHERE name = 'Argent';
-- 
-- -- Puis vérifiez le résultat :
-- SELECT name, points_required, updated_at 
-- FROM loyalty_tiers_advanced 
-- WHERE name = 'Argent';
