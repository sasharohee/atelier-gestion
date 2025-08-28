-- Vérification de la structure de la table clients
-- Pour identifier les différences entre champs TEXT et VARCHAR

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

-- Comparaison avec les champs qui fonctionnent
-- Les champs TEXT qui s'affichent correctement :
-- - first_name (TEXT)
-- - last_name (TEXT) 
-- - email (TEXT)
-- - phone (TEXT)

-- Les champs VARCHAR qui ne s'affichent pas :
-- - region (VARCHAR)
-- - postal_code (VARCHAR)
-- - city (VARCHAR)
-- - accounting_code (VARCHAR)
-- - cni (VARCHAR)
-- - address_complement (VARCHAR)
-- - company_name (VARCHAR)
-- - siren (VARCHAR)
-- - vat (VARCHAR)
