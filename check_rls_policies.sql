-- Script pour vérifier les politiques RLS
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier les politiques RLS pour device_categories
SELECT '=== POLITIQUES RLS POUR device_categories ===' as info;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_categories'
ORDER BY policyname;

-- 2. Vérifier les politiques RLS pour device_brands
SELECT '=== POLITIQUES RLS POUR device_brands ===' as info;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_brands'
ORDER BY policyname;

-- 3. Vérifier si RLS est activé sur les tables
SELECT '=== ÉTAT RLS DES TABLES ===' as info;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    relforcerowsecurity as rls_forced
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
AND c.relname IN ('device_categories', 'device_brands', 'device_models', 'brand_categories')
AND c.relkind = 'r';

-- 4. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as info;

SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    current_user as database_user;
