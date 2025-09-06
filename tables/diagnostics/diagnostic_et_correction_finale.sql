-- DIAGNOSTIC ET CORRECTION FINALE DU PROBLÈME DE CONTRAINTE
-- Résout définitivement le problème de foreign key

-- 1. DIAGNOSTIC DES CONTRAINTES
SELECT '🔍 DIAGNOSTIC DES CONTRAINTES' as diagnostic;

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

-- 2. VÉRIFIER LES TABLES EXISTANTES
SELECT '🏗️ TABLES EXISTANTES' as diagnostic;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%loyalty%'
AND table_schema = 'public'
ORDER BY table_name;

-- 3. VÉRIFIER LE CONTENU DES TABLES
SELECT '📊 CONTENU DES TABLES' as diagnostic;

-- Vérifier loyalty_tiers (si elle existe)
SELECT 'loyalty_tiers (si existe):' as table_name;
SELECT COUNT(*) as count FROM information_schema.tables 
WHERE table_name = 'loyalty_tiers' AND table_schema = 'public';

-- Vérifier loyalty_tiers_advanced
SELECT 'loyalty_tiers_advanced:' as table_name;
SELECT COUNT(*) as count FROM loyalty_tiers_advanced;

-- 4. SUPPRIMER TOUTES LES CONTRAINTES PROBLÉMATIQUES
SELECT '🧹 SUPPRESSION DES CONTRAINTES' as diagnostic;

-- Supprimer toutes les contraintes possibles
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS fk_clients_current_tier_id;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_loyalty_tier_fkey;

-- 5. VÉRIFIER QU'IL N'Y A PLUS DE CONTRAINTES
SELECT '✅ VÉRIFICATION APRÈS SUPPRESSION' as diagnostic;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id';

-- 6. NETTOYER LES RÉFÉRENCES INCORRECTES
SELECT '🧹 NETTOYAGE DES RÉFÉRENCES' as diagnostic;

UPDATE clients 
SET current_tier_id = NULL;

-- 7. CRÉER LA NOUVELLE CONTRAINTE CORRECTE
SELECT '🔧 CRÉATION DE LA NOUVELLE CONTRAINTE' as diagnostic;

ALTER TABLE clients 
ADD CONSTRAINT clients_current_tier_id_fkey 
FOREIGN KEY (current_tier_id) 
REFERENCES loyalty_tiers_advanced(id);

-- 8. ASSIGNER LES NIVEAUX
SELECT '🔧 ASSIGNATION DES NIVEAUX' as diagnostic;

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

-- 9. VÉRIFICATION FINALE
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

-- 10. VÉRIFIER LA NOUVELLE CONTRAINTE
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

-- 11. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 La contrainte pointe maintenant vers loyalty_tiers_advanced.' as next_step;
SELECT '🔄 Rafraîchissez la page pour voir les changements.' as instruction;





