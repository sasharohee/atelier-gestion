-- CORRECTION SIMPLE DE LA STRUCTURE DES TABLES DE FIDÉLITÉ
-- Version simplifiée pour éviter les problèmes avec les UUID

-- 1. SUPPRIMER LES CONTRAINTES UNIQUES PROBLÉMATIQUES
SELECT '🔧 SUPPRESSION DES CONTRAINTES UNIQUES' as diagnostic;

-- Supprimer la contrainte unique sur loyalty_config.key
ALTER TABLE loyalty_config DROP CONSTRAINT IF EXISTS loyalty_config_key_key;

-- 2. NETTOYER COMPLÈTEMENT LES TABLES
SELECT '🧹 NETTOYAGE COMPLET' as diagnostic;

-- Supprimer toutes les données existantes
TRUNCATE TABLE loyalty_config CASCADE;
TRUNCATE TABLE loyalty_tiers_advanced CASCADE;

-- 3. CRÉER LES NOUVELLES CONTRAINTES
SELECT '🔧 CRÉATION DES NOUVELLES CONTRAINTES' as diagnostic;

-- Contrainte unique sur (workshop_id, key) pour loyalty_config
ALTER TABLE loyalty_config 
ADD CONSTRAINT loyalty_config_workshop_key_unique 
UNIQUE (workshop_id, key);

-- Contrainte unique sur (workshop_id, name) pour loyalty_tiers_advanced
ALTER TABLE loyalty_tiers_advanced 
ADD CONSTRAINT loyalty_tiers_workshop_name_unique 
UNIQUE (workshop_id, name);

-- 4. CRÉER DES DONNÉES PAR DÉFAUT POUR CHAQUE UTILISATEUR
SELECT '🏗️ CRÉATION DES DONNÉES PAR DÉFAUT' as diagnostic;

-- Créer la configuration par défaut pour chaque utilisateur
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
) AS config(key, value, description);

-- Créer les niveaux par défaut pour chaque utilisateur
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
) AS tier(name, points_required, discount_percentage, color, description, is_active);

-- 5. VÉRIFIER LA STRUCTURE
SELECT '✅ VÉRIFICATION DE LA STRUCTURE' as diagnostic;

-- Vérifier les contraintes existantes
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('loyalty_config', 'loyalty_tiers_advanced')
    AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.table_name, tc.constraint_name;

-- 6. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Afficher les données par atelier
SELECT 
    'Configuration par atelier:' as info,
    workshop_id,
    COUNT(*) as config_count
FROM loyalty_config 
GROUP BY workshop_id;

SELECT 
    'Niveaux par atelier:' as info,
    workshop_id,
    COUNT(*) as tiers_count
FROM loyalty_tiers_advanced 
GROUP BY workshop_id;

-- 7. MESSAGE DE CONFIRMATION
SELECT '🎉 STRUCTURE CORRIGÉE !' as result;
SELECT '📋 L''isolation par atelier est maintenant possible.' as next_step;
SELECT '🔄 Vous pouvez maintenant exécuter le script de création des fonctions.' as instruction;





