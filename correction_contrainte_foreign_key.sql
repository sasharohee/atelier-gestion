-- CORRECTION DE LA CONTRAINTE DE CLÉ ÉTRANGÈRE
-- Le problème : current_tier_id pointe vers loyalty_tiers au lieu de loyalty_tiers_advanced

-- 1. VÉRIFIER LES CONTRAINTES ACTUELLES
SELECT '🔍 VÉRIFICATION DES CONTRAINTES' as diagnostic;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id';

-- 2. VÉRIFIER SI LA TABLE loyalty_tiers EXISTE
SELECT '🏗️ VÉRIFICATION DES TABLES' as diagnostic;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('loyalty_tiers', 'loyalty_tiers_advanced')
AND table_schema = 'public';

-- 3. VÉRIFIER LE CONTENU DES TABLES
SELECT '📊 CONTENU DES TABLES' as diagnostic;

-- Vérifier loyalty_tiers (si elle existe)
SELECT 'loyalty_tiers:' as table_name;
SELECT COUNT(*) as count FROM loyalty_tiers;

-- Vérifier loyalty_tiers_advanced
SELECT 'loyalty_tiers_advanced:' as table_name;
SELECT COUNT(*) as count FROM loyalty_tiers_advanced;

-- 4. SUPPRIMER L'ANCIENNE CONTRAINTE
SELECT '🔧 SUPPRESSION DE L''ANCIENNE CONTRAINTE' as diagnostic;

ALTER TABLE clients 
DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;

-- 5. CRÉER LA NOUVELLE CONTRAINTE
SELECT '🔧 CRÉATION DE LA NOUVELLE CONTRAINTE' as diagnostic;

ALTER TABLE clients 
ADD CONSTRAINT clients_current_tier_id_fkey 
FOREIGN KEY (current_tier_id) 
REFERENCES loyalty_tiers_advanced(id);

-- 6. CORRIGER LES NIVEAUX
SELECT '🔧 CORRECTION DES NIVEAUX' as diagnostic;

-- Nettoyer les anciennes références
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL;

-- Assigner les nouveaux niveaux
UPDATE clients 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers_advanced 
    WHERE points_required <= clients.loyalty_points 
    AND is_active = true
    ORDER BY points_required DESC 
    LIMIT 1
)
WHERE loyalty_points > 0;

-- 7. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.name as niveau_nom,
    lt.points_required,
    lt.discount_percentage
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 8. VÉRIFIER LA NOUVELLE CONTRAINTE
SELECT '🔗 VÉRIFICATION DE LA NOUVELLE CONTRAINTE' as diagnostic;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id';

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 La contrainte pointe maintenant vers loyalty_tiers_advanced.' as next_step;
