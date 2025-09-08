-- Script de test pour vérifier les données des clients
-- Ce script vérifie si les données d'entreprise sont bien stockées en base

-- 1. Vérifier la structure de la table
SELECT '=== STRUCTURE DE LA TABLE CLIENTS ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
AND column_name IN ('company_name', 'vat_number', 'siren_number', 'address_complement', 'region', 'postal_code', 'city')
ORDER BY column_name;

-- 2. Vérifier les données des clients
SELECT '=== DONNÉES DES CLIENTS ===' as etape;

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
    internal_note,
    created_at
FROM public.clients 
ORDER BY created_at DESC
LIMIT 10;

-- 3. Compter les clients avec des données d'entreprise
SELECT '=== STATISTIQUES DES DONNÉES ENTREPRISE ===' as etape;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN company_name IS NOT NULL AND company_name != '' THEN 1 END) as clients_with_company_name,
    COUNT(CASE WHEN vat_number IS NOT NULL AND vat_number != '' THEN 1 END) as clients_with_vat_number,
    COUNT(CASE WHEN siren_number IS NOT NULL AND siren_number != '' THEN 1 END) as clients_with_siren_number,
    COUNT(CASE WHEN address_complement IS NOT NULL AND address_complement != '' THEN 1 END) as clients_with_address_complement,
    COUNT(CASE WHEN region IS NOT NULL AND region != '' THEN 1 END) as clients_with_region,
    COUNT(CASE WHEN postal_code IS NOT NULL AND postal_code != '' THEN 1 END) as clients_with_postal_code,
    COUNT(CASE WHEN city IS NOT NULL AND city != '' THEN 1 END) as clients_with_city
FROM public.clients;

-- 4. Afficher les clients avec des données d'entreprise
SELECT '=== CLIENTS AVEC DONNÉES ENTREPRISE ===' as etape;

SELECT 
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    address_complement,
    region,
    postal_code,
    city
FROM public.clients 
WHERE 
    (company_name IS NOT NULL AND company_name != '') OR
    (vat_number IS NOT NULL AND vat_number != '') OR
    (siren_number IS NOT NULL AND siren_number != '') OR
    (address_complement IS NOT NULL AND address_complement != '') OR
    (region IS NOT NULL AND region != '') OR
    (postal_code IS NOT NULL AND postal_code != '') OR
    (city IS NOT NULL AND city != '')
ORDER BY created_at DESC;

-- 5. Test de mise à jour d'un client avec des données d'entreprise
SELECT '=== TEST DE MISE À JOUR ===' as etape;

-- Mettre à jour le premier client avec des données d'entreprise de test
UPDATE public.clients 
SET 
    company_name = 'Test Company Updated',
    vat_number = 'FR12345678901',
    siren_number = '123456789',
    address_complement = 'Bâtiment A, 2ème étage',
    region = 'Île-de-France',
    postal_code = '75001',
    city = 'Paris',
    accounting_code = 'CLI001',
    cni_identifier = 'CNI123456',
    internal_note = 'Client de test avec données complètes',
    updated_at = NOW()
WHERE id = (
    SELECT id FROM public.clients 
    ORDER BY created_at DESC 
    LIMIT 1
);

-- Vérifier la mise à jour
SELECT 
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
WHERE id = (
    SELECT id FROM public.clients 
    ORDER BY updated_at DESC 
    LIMIT 1
);

SELECT '✅ Test terminé!' as resultat;
