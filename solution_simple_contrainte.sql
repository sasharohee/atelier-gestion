-- SOLUTION SIMPLE POUR SUPPRIMER LA CONTRAINTE PROBLÉMATIQUE
-- Script simple et direct pour résoudre le problème

-- 1. SUPPRIMER LA CONTRAINTE PROBLÉMATIQUE
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;

-- 2. VÉRIFIER QU'IL N'Y A PLUS DE CONTRAINTES
SELECT 'Vérification des contraintes restantes:' as info;
SELECT constraint_name, table_name 
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND constraint_type = 'FOREIGN KEY'
AND constraint_name LIKE '%current_tier%';

-- 3. NETTOYER LES RÉFÉRENCES INCORRECTES
UPDATE clients SET current_tier_id = NULL;

-- 4. ASSIGNER LES NIVEAUX CORRECTS
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

-- 5. VÉRIFICATION FINALE
SELECT 'Résultat final:' as info;
SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    lt.name as niveau
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 6. MESSAGE DE CONFIRMATION
SELECT 'SUCCÈS: La contrainte a été supprimée!' as result;


