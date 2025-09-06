-- =====================================================
-- NETTOYAGE DONNÉES ORDERS POUR ISOLATION
-- =====================================================

-- ATTENTION : Ce script supprime les commandes qui ne respectent pas l'isolation
-- Exécuter avec précaution !

SELECT 'NETTOYAGE DONNÉES ORDERS' as section;

-- 1. IDENTIFIER LES COMMANDES PROBLÉMATIQUES
-- =====================================================

-- Commandes sans workshop_id
SELECT 
    'COMMANDES SANS WORKSHOP_ID' as probleme,
    COUNT(*) as nombre,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
WHERE workshop_id IS NULL;

-- Commandes sans created_by
SELECT 
    'COMMANDES SANS CREATED_BY' as probleme,
    COUNT(*) as nombre,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
WHERE created_by IS NULL;

-- Commandes avec workshop_id invalide
SELECT 
    'COMMANDES WORKSHOP_ID INVALIDE' as probleme,
    COUNT(*) as nombre,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
WHERE workshop_id IS NOT NULL 
  AND workshop_id NOT IN (
    SELECT DISTINCT workshop_id 
    FROM subscription_status 
    WHERE workshop_id IS NOT NULL
  );

-- 2. SAUVEGARDER LES DONNÉES AVANT SUPPRESSION
-- =====================================================

-- Créer une table de sauvegarde
CREATE TABLE IF NOT EXISTS orders_backup_isolation AS
SELECT * FROM orders;

-- 3. SUPPRIMER LES COMMANDES PROBLÉMATIQUES
-- =====================================================

-- Supprimer les commandes sans workshop_id
DELETE FROM orders 
WHERE workshop_id IS NULL;

-- Supprimer les commandes sans created_by
DELETE FROM orders 
WHERE created_by IS NULL;

-- Supprimer les commandes avec workshop_id invalide
DELETE FROM orders 
WHERE workshop_id IS NOT NULL 
  AND workshop_id NOT IN (
    SELECT DISTINCT workshop_id 
    FROM subscription_status 
    WHERE workshop_id IS NOT NULL
  );

-- 4. VÉRIFIER LE NETTOYAGE
-- =====================================================

-- Compter les commandes restantes
SELECT 
    'COMMANDES APRÈS NETTOYAGE' as verification,
    COUNT(*) as total_commandes,
    COUNT(DISTINCT workshop_id) as workshops_distincts,
    COUNT(DISTINCT created_by) as utilisateurs_distincts
FROM orders;

-- Vérifier qu'il n'y a plus de commandes problématiques
SELECT 
    'VÉRIFICATION FINALE' as verification,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_created_by,
    COUNT(CASE WHEN workshop_id IS NOT NULL 
               AND workshop_id NOT IN (
                   SELECT DISTINCT workshop_id 
                   FROM subscription_status 
                   WHERE workshop_id IS NOT NULL
               ) THEN 1 END) as workshop_id_invalide
FROM orders;

-- 5. AFFICHER LES COMMANDES RESTANTES
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    total_amount,
    workshop_id,
    created_by,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 6. RÉSULTAT
-- =====================================================

SELECT 
    'NETTOYAGE TERMINÉ' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Données nettoyées pour l''isolation' as description;
