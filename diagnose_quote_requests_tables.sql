-- Script de diagnostic pour les tables des demandes de devis
-- À exécuter dans l'éditeur SQL de Supabase pour voir l'état actuel des tables

-- 1. Vérifier si les tables existent
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('user_profiles', 'technician_custom_urls', 'quote_requests', 'quote_request_attachments')
ORDER BY tablename;

-- 2. Vérifier la structure de la table quote_requests si elle existe
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'quote_requests'
ORDER BY ordinal_position;

-- 3. Vérifier les contraintes existantes
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
AND tc.table_name = 'quote_requests'
ORDER BY tc.constraint_type, kcu.column_name;

-- 4. Vérifier les index existants
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename = 'quote_requests';

-- 5. Vérifier les fonctions existantes
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_quote_request_stats', 'generate_quote_request_number')
ORDER BY routine_name;

-- 6. Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('user_profiles', 'technician_custom_urls', 'quote_requests', 'quote_request_attachments')
ORDER BY tablename, policyname;
