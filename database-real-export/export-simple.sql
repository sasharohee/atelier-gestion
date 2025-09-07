
-- ============================================
-- EXPORT SIMPLE DES VRAIES TABLES
-- ============================================

-- Ce script doit être exécuté dans votre base de données de PRODUCTION
-- pour récupérer la structure réelle

-- 1. Lister toutes les tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- 2. Pour chaque table, générer le CREATE TABLE
-- (Exécutez ceci pour chaque table trouvée)

-- Exemple pour une table nommée 'ma_table':
-- SELECT 'CREATE TABLE ma_table (' || chr(10) ||
--        string_agg(
--            '    ' || column_name || ' ' || data_type || 
--            CASE WHEN character_maximum_length IS NOT NULL 
--                 THEN '(' || character_maximum_length || ')'
--                 ELSE '' END ||
--            CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
--            CASE WHEN column_default IS NOT NULL 
--                 THEN ' DEFAULT ' || column_default ELSE '' END,
--            ',' || chr(10)
--        ) || chr(10) || ');' as create_sql
-- FROM information_schema.columns 
-- WHERE table_name = 'ma_table' AND table_schema = 'public';

-- 3. Générer les contraintes
SELECT 
    'ALTER TABLE ' || tc.table_name || ' ADD CONSTRAINT ' || tc.constraint_name || 
    ' ' || tc.constraint_type || ' (' || string_agg(kcu.column_name, ', ') || ');' as constraint_sql
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
GROUP BY tc.table_name, tc.constraint_name, tc.constraint_type
ORDER BY tc.table_name;
