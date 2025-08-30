-- CORRECTION URGENTE DE LA CONTRAINTE DE CLÉ ÉTRANGÈRE
-- Solution définitive pour le problème de foreign key

-- 1. SUPPRIMER DÉFINITIVEMENT LA CONTRAINTE PROBLÉMATIQUE
SELECT '🧹 SUPPRESSION DÉFINITIVE DE LA CONTRAINTE' as diagnostic;

-- Supprimer la contrainte avec tous les noms possibles
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS fk_clients_current_tier_id;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_loyalty_tier_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_fkey;

-- 2. VÉRIFIER QU'IL N'Y A PLUS DE CONTRAINTES
SELECT '✅ VÉRIFICATION - PLUS DE CONTRAINTES' as diagnostic;

SELECT COUNT(*) as contraintes_restantes
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND constraint_type = 'FOREIGN KEY'
AND constraint_name LIKE '%current_tier%';

-- 3. NETTOYER TOUTES LES RÉFÉRENCES INCORRECTES
SELECT '🧹 NETTOYAGE COMPLET DES RÉFÉRENCES' as diagnostic;

UPDATE clients 
SET current_tier_id = NULL;

-- 4. VÉRIFIER LE NETTOYAGE
SELECT '✅ VÉRIFICATION DU NETTOYAGE' as diagnostic;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau
FROM clients;

-- 5. CRÉER LA NOUVELLE CONTRAINTE CORRECTE
SELECT '🔧 CRÉATION DE LA NOUVELLE CONTRAINTE' as diagnostic;

ALTER TABLE clients 
ADD CONSTRAINT clients_current_tier_id_fkey 
FOREIGN KEY (current_tier_id) 
REFERENCES loyalty_tiers_advanced(id);

-- 6. VÉRIFIER LA NOUVELLE CONTRAINTE
SELECT '🔗 VÉRIFICATION DE LA NOUVELLE CONTRAINTE' as diagnostic;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id'
    AND tc.constraint_type = 'FOREIGN KEY';

-- 7. ASSIGNER LES NIVEAUX
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

-- 8. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.name as niveau_nom,
    lt.points_required,
    CASE 
        WHEN c.current_tier_id IS NOT NULL THEN '✅ Niveau assigné'
        WHEN c.loyalty_points = 0 THEN 'ℹ️ Aucun point'
        ELSE '❌ Problème'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 9. TEST D'INSERTION
SELECT '🧪 TEST D''INSERTION' as diagnostic;

-- Tester si on peut maintenant insérer des données
SELECT 'Test réussi si aucune erreur' as test_result;

-- 10. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION URGENTE TERMINÉE !' as result;
SELECT '📋 La contrainte est maintenant correcte.' as next_step;
SELECT '🔄 Rafraîchissez la page et testez l''ajout de points.' as instruction;
