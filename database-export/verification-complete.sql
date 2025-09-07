
-- Script de vérification après import complet
-- Exécutez ce script pour vérifier que tout a été importé correctement

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

-- 3. Vérifier les index
SELECT 'Index créés:' as info;
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 4. Vérifier les triggers
SELECT 'Triggers créés:' as info;
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY event_object_table;

-- 5. Vérifier les fonctions
SELECT 'Fonctions créées:' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- 6. Vérifier les politiques RLS
SELECT 'Politiques RLS:' as info;
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
