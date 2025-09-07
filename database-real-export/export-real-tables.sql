
-- ============================================
-- EXPORT DES VRAIES TABLES DE PRODUCTION
-- Généré automatiquement le 2025-09-06T16:55:33.619Z
-- Source: https://wlqyrmntfxwdvkzzsujv.supabase.co
-- ============================================

-- IMPORTANT: Ce script doit être exécuté dans votre base de données de PRODUCTION
-- pour récupérer la structure réelle de toutes les tables

-- 1. Script pour lister toutes les tables existantes
-- ================================================

-- Lister toutes les tables du schéma public
SELECT 'Tables existantes dans la production:' as info;
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 2. Script pour exporter la structure de chaque table
-- ===================================================

-- Générer les commandes CREATE TABLE pour toutes les tables
SELECT 
    'CREATE TABLE ' || tablename || ' (' || chr(10) ||
    string_agg(
        '    ' || column_name || ' ' || data_type || 
        CASE 
            WHEN character_maximum_length IS NOT NULL 
            THEN '(' || character_maximum_length || ')'
            ELSE ''
        END ||
        CASE 
            WHEN is_nullable = 'NO' THEN ' NOT NULL'
            ELSE ''
        END ||
        CASE 
            WHEN column_default IS NOT NULL 
            THEN ' DEFAULT ' || column_default
            ELSE ''
        END,
        ',' || chr(10)
    ) || chr(10) || ');' as create_table_sql
FROM information_schema.columns c
JOIN pg_tables t ON c.table_name = t.tablename
WHERE c.table_schema = 'public' 
  AND t.schemaname = 'public'
GROUP BY t.tablename
ORDER BY t.tablename;

-- 3. Script pour exporter les contraintes (clés primaires, étrangères, etc.)
-- =======================================================================

-- Contraintes de clé primaire
SELECT 
    'ALTER TABLE ' || tc.table_name || ' ADD CONSTRAINT ' || tc.constraint_name || 
    ' PRIMARY KEY (' || string_agg(kcu.column_name, ', ') || ');' as primary_key_sql
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
GROUP BY tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

-- Contraintes de clé étrangère
SELECT 
    'ALTER TABLE ' || tc.table_name || ' ADD CONSTRAINT ' || tc.constraint_name || 
    ' FOREIGN KEY (' || kcu.column_name || ') REFERENCES ' || 
    ccu.table_name || '(' || ccu.column_name || ');' as foreign_key_sql
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- 4. Script pour exporter les index
-- ================================

SELECT 
    'CREATE INDEX ' || indexname || ' ON ' || tablename || 
    ' (' || indexdef || ');' as create_index_sql
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 5. Script pour exporter les triggers
-- ===================================

SELECT 
    'CREATE TRIGGER ' || trigger_name || 
    ' BEFORE ' || event_manipulation || ' ON ' || event_object_table ||
    ' FOR EACH ROW EXECUTE FUNCTION ' || action_statement || ';' as create_trigger_sql
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 6. Script pour exporter les fonctions
-- ====================================

SELECT 
    'CREATE OR REPLACE FUNCTION ' || routine_name || '(' || 
    COALESCE(
        (SELECT string_agg(
            parameter_name || ' ' || data_type,
            ', '
        )
        FROM information_schema.parameters p
        WHERE p.specific_name = r.specific_name
        AND p.parameter_mode = 'IN'),
        ''
    ) || ') RETURNS ' || data_type || ' AS $$' || chr(10) ||
    '-- Fonction exportée automatiquement' || chr(10) ||
    '$$ LANGUAGE ' || external_language || ';' as create_function_sql
FROM information_schema.routines r
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 7. Script pour exporter les politiques RLS
-- =========================================

SELECT 
    'CREATE POLICY "' || policyname || '" ON ' || tablename ||
    ' FOR ' || cmd || ' USING (' || qual || ');' as create_policy_sql
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 8. Script pour exporter les données (optionnel)
-- ==============================================

-- ATTENTION: Décommentez les lignes suivantes si vous voulez exporter les données
-- (Attention: cela peut être volumineux et prendre du temps)

/*
-- Exporter les données de chaque table
DO $$
DECLARE
    table_name text;
    sql_query text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
    LOOP
        sql_query := 'SELECT ''INSERT INTO ' || table_name || ' VALUES ('' || 
                     string_agg(''('' || quote_literal(column_name) || '')'', '', '') || 
                     '');'' FROM ' || table_name;
        EXECUTE sql_query;
    END LOOP;
END $$;
*/

-- 9. Instructions pour l'utilisateur
-- =================================

SELECT 'INSTRUCTIONS POUR L''UTILISATEUR:' as info;
SELECT '1. Exécutez ce script dans votre base de données de PRODUCTION' as instruction;
SELECT '2. Copiez les résultats dans un fichier SQL' as instruction;
SELECT '3. Adaptez le script selon vos besoins' as instruction;
SELECT '4. Exécutez le script adapté dans votre base de développement' as instruction;

-- ============================================
-- FIN DU SCRIPT D'EXPORT DES VRAIES TABLES
-- ============================================
