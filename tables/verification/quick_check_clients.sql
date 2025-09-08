-- Vérification rapide des données des clients
-- Exécutez ce script dans Supabase pour voir les données en base

-- 1. Vérifier la structure de la table
SELECT '=== STRUCTURE DE LA TABLE ===' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
AND column_name IN ('company_name', 'vat_number', 'siren_number', 'address_complement', 'region', 'postal_code', 'city')
ORDER BY column_name;

-- 2. Vérifier les données des clients
SELECT '=== DONNÉES DES CLIENTS ===' as info;
SELECT 
    id,
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    address_complement,
    region,
    postal_code,
    city,
    accounting_code,
    cni_identifier,
    internal_note
FROM public.clients 
ORDER BY created_at DESC
LIMIT 5;

-- 3. Vérifier spécifiquement le client avec email 'sasharo@gmail.com'
SELECT '=== CLIENT SPECIFIQUE ===' as info;
SELECT 
    id,
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    address_complement,
    region,
    postal_code,
    city,
    accounting_code,
    cni_identifier,
    internal_note
FROM public.clients 
WHERE email = 'sasharo@gmail.com' OR email = 'sasharo@gmail.co'
ORDER BY created_at DESC;
