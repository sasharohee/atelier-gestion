-- Script pour vérifier les fonctions RPC disponibles
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier les fonctions RPC disponibles
SELECT '=== FONCTIONS RPC DISPONIBLES ===' as info;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
AND p.proname LIKE '%brand%'
ORDER BY p.proname;

-- 2. Vérifier toutes les fonctions RPC
SELECT '=== TOUTES LES FONCTIONS RPC ===' as info;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
AND p.prokind = 'f'
ORDER BY p.proname;

-- 3. Vérifier les tables existantes
SELECT '=== TABLES EXISTANTES ===' as info;

SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
