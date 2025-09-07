
-- Script de vérification après import
-- Exécutez ce script dans SQL Editor pour vérifier que tout est correct

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

-- 4. Vérifier les fonctions
SELECT 'Fonctions créées:' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- 5. Vérifier les politiques RLS
SELECT 'Politiques RLS:' as info;
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
