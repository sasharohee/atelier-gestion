-- TEST SIMPLE - Vérifier que les clients sont bien là
-- Exécutez ce script pour voir tous les clients

SELECT 
    id,
    first_name,
    last_name,
    email,
    user_id,
    accounting_code,
    cni_identifier,
    region,
    city,
    company_name,
    created_at
FROM clients 
ORDER BY created_at DESC;
