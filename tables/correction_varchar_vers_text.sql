-- Correction : Conversion des champs VARCHAR en TEXT
-- Pour résoudre le problème d'affichage des nouveaux champs

BEGIN;

-- Conversion des champs VARCHAR en TEXT
ALTER TABLE public.clients 
ALTER COLUMN region TYPE TEXT,
ALTER COLUMN postal_code TYPE TEXT,
ALTER COLUMN city TYPE TEXT,
ALTER COLUMN accounting_code TYPE TEXT,
ALTER COLUMN cni TYPE TEXT,
ALTER COLUMN address_complement TYPE TEXT,
ALTER COLUMN company_name TYPE TEXT,
ALTER COLUMN siren TYPE TEXT,
ALTER COLUMN vat TYPE TEXT;

-- Vérification de la conversion
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
AND column_name IN ('region', 'postal_code', 'city', 'accounting_code', 'cni', 'address_complement', 'company_name', 'siren', 'vat')
ORDER BY column_name;

-- Test d'insertion pour vérifier que tout fonctionne
INSERT INTO public.clients (
    user_id,
    first_name,
    last_name,
    email,
    phone,
    address,
    region,
    postal_code,
    city,
    accounting_code,
    cni,
    address_complement,
    company_name,
    siren,
    vat,
    created_at,
    updated_at
) VALUES (
    'e454cc8c-3e40-4f72-bf26-4f6f43e78d0b',
    'Test',
    'VARCHAR to TEXT',
    'test.varchar@example.com',
    '0123456789',
    '123 Rue Test',
    'Île-de-France',
    '75001',
    'Paris',
    'ACC001',
    '123456789',
    'Bâtiment A',
    'Entreprise Test',
    '123456789',
    'FR12345678901'
);

-- Vérification de l'insertion
SELECT 
    id,
    first_name,
    last_name,
    email,
    region,
    postal_code,
    city,
    accounting_code,
    cni,
    address_complement,
    company_name,
    siren,
    vat
FROM public.clients 
WHERE email = 'test.varchar@example.com';

COMMIT;
