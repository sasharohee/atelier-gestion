-- Vérification des colonnes existantes dans la table clients
-- Pour identifier quelles colonnes sont réellement présentes

SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérification spécifique des nouvelles colonnes
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
AND column_name IN (
    'region', 
    'postal_code', 
    'city', 
    'accounting_code', 
    'cni', 
    'address_complement', 
    'company_name', 
    'siren', 
    'vat'
)
ORDER BY column_name;
