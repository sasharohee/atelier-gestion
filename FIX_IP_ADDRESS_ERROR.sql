-- Correction de l'erreur d'adresse IP
-- Ce script corrige le problème "invalid input syntax for type inet"

-- 1. Vérifier le schéma de la table quote_requests
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'quote_requests' 
AND column_name = 'ip_address';

-- 2. Vérifier les contraintes sur ip_address
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'quote_requests'::regclass
AND conname LIKE '%ip%';

-- 3. Modifier la colonne ip_address pour accepter NULL
ALTER TABLE quote_requests 
ALTER COLUMN ip_address DROP NOT NULL;

-- 4. Mettre à jour les enregistrements avec des chaînes vides
-- Note: On ne peut pas comparer directement ip_address avec '' car c'est un type INET
-- On va d'abord vérifier s'il y a des enregistrements problématiques
SELECT COUNT(*) as problematic_records
FROM quote_requests 
WHERE ip_address::text = '';

-- Si des enregistrements existent, on les met à jour
UPDATE quote_requests 
SET ip_address = NULL 
WHERE ip_address::text = '';

-- 5. Vérifier les données après correction
SELECT 
    id,
    request_number,
    ip_address,
    user_agent,
    created_at
FROM quote_requests 
ORDER BY created_at DESC 
LIMIT 5;

-- 6. Test d'insertion avec NULL
DO $$
DECLARE
    test_request_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    -- Test d'insertion avec ip_address = NULL
    BEGIN
        INSERT INTO quote_requests (
            request_number,
            custom_url,
            technician_id,
            client_first_name,
            client_last_name,
            client_email,
            client_phone,
            description,
            issue_description,
            urgency,
            status,
            priority,
            source,
            ip_address,
            user_agent
        ) VALUES (
            'QR-TEST-IP-' || extract(epoch from now()),
            'test-ip-fix',
            current_user_id,
            'Test',
            'IP Fix',
            'test-ip@example.com',
            '0123456789',
            'Test correction IP',
            'Test de correction de l''erreur IP',
            'medium',
            'pending',
            'medium',
            'website',
            NULL,  -- ip_address = NULL
            'Test User Agent'
        ) RETURNING id INTO test_request_id;
        
        RAISE NOTICE 'SUCCÈS: Demande de test créée avec ip_address = NULL: %', test_request_id;
        
        -- Nettoyer
        DELETE FROM quote_requests WHERE id = test_request_id;
        RAISE NOTICE 'Demande de test supprimée';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERREUR lors du test: %', SQLERRM;
    END;
END $$;

-- 7. Vérifier le schéma final
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'quote_requests' 
AND column_name = 'ip_address';

-- 8. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Correction terminée.';
    RAISE NOTICE 'La colonne ip_address accepte maintenant NULL.';
    RAISE NOTICE 'Les chaînes vides ont été remplacées par NULL.';
    RAISE NOTICE 'Testez maintenant la création de demandes.';
END $$;
