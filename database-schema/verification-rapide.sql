
-- Vérification rapide après import
-- Exécutez ce script après l'import principal

-- 1. Lister toutes les tables
SELECT 'Tables créées:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. Vérifier les index
SELECT 'Index créés:' as info;
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 3. Vérifier les triggers
SELECT 'Triggers créés:' as info;
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY event_object_table;
