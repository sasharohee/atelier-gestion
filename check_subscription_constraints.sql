-- Diagnostic des contraintes sur subscription_status
-- À exécuter dans Supabase SQL Editor pour voir les valeurs acceptées

-- 1. Vérifier les contraintes sur subscription_status
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.subscription_status'::regclass
AND contype = 'c';

-- 2. Vérifier la structure de la table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Vérifier les valeurs existantes dans subscription_type
SELECT DISTINCT subscription_type, COUNT(*) as count
FROM public.subscription_status 
GROUP BY subscription_type;
