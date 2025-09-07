
-- Vérification rapide après import complet
-- Exécutez ce script après l'import principal

-- 1. Vérifier les tables
SELECT 'Tables créées:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. Vérifier les données
SELECT 'Données insérées:' as info;
SELECT 'clients' as table_name, COUNT(*) as count FROM clients
UNION ALL
SELECT 'produits' as table_name, COUNT(*) as count FROM produits
UNION ALL
SELECT 'reparations' as table_name, COUNT(*) as count FROM reparations
UNION ALL
SELECT 'interventions' as table_name, COUNT(*) as count FROM interventions
UNION ALL
SELECT 'factures' as table_name, COUNT(*) as count FROM factures
UNION ALL
SELECT 'utilisateurs' as table_name, COUNT(*) as count FROM utilisateurs;

-- 3. Test d'une requête
SELECT 'Test de requête:' as info;
SELECT c.nom, c.prenom, p.nom as produit, r.statut
FROM clients c
JOIN reparations r ON c.id = r.client_id
JOIN produits p ON r.produit_id = p.id
LIMIT 3;
