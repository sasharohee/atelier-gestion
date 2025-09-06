-- Vérification de la structure exacte de la table clients
-- Ce script affiche tous les détails des colonnes pour identifier le problème

-- 1. Afficher toutes les colonnes avec leurs détails
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- 3. Afficher un exemple de client avec toutes les colonnes
SELECT 
    'EXEMPLE CLIENT' as info,
    *
FROM clients 
ORDER BY created_at DESC 
LIMIT 1;

-- 4. Vérifier spécifiquement les champs problématiques
SELECT 
    'VÉRIFICATION CHAMPS PROBLÉMATIQUES' as section,
    id,
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    postal_code,
    accounting_code,
    cni_identifier,
    region,
    city,
    address_complement,
    internal_note,
    created_at
FROM clients 
ORDER BY created_at DESC 
LIMIT 3;

-- 5. Compter les clients avec des valeurs dans chaque champ
SELECT 
    'STATISTIQUES DES CHAMPS' as section,
    'company_name' as champ,
    COUNT(*) as total_clients,
    COUNT(company_name) as avec_valeur,
    COUNT(*) - COUNT(company_name) as sans_valeur
FROM clients
UNION ALL
SELECT 
    'STATISTIQUES DES CHAMPS' as section,
    'vat_number' as champ,
    COUNT(*) as total_clients,
    COUNT(vat_number) as avec_valeur,
    COUNT(*) - COUNT(vat_number) as sans_valeur
FROM clients
UNION ALL
SELECT 
    'STATISTIQUES DES CHAMPS' as section,
    'siren_number' as champ,
    COUNT(*) as total_clients,
    COUNT(siren_number) as avec_valeur,
    COUNT(*) - COUNT(siren_number) as sans_valeur
FROM clients
UNION ALL
SELECT 
    'STATISTIQUES DES CHAMPS' as section,
    'postal_code' as champ,
    COUNT(*) as total_clients,
    COUNT(postal_code) as avec_valeur,
    COUNT(*) - COUNT(postal_code) as sans_valeur
FROM clients
UNION ALL
SELECT 
    'STATISTIQUES DES CHAMPS' as section,
    'accounting_code' as champ,
    COUNT(*) as total_clients,
    COUNT(accounting_code) as avec_valeur,
    COUNT(*) - COUNT(accounting_code) as sans_valeur
FROM clients
UNION ALL
SELECT 
    'STATISTIQUES DES CHAMPS' as section,
    'cni_identifier' as champ,
    COUNT(*) as total_clients,
    COUNT(cni_identifier) as avec_valeur,
    COUNT(*) - COUNT(cni_identifier) as sans_valeur
FROM clients;
