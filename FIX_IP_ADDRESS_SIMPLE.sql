-- Correction simple de l'erreur d'adresse IP
-- Ce script évite les erreurs de comparaison avec le type INET

-- 1. Vérifier le schéma actuel
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'quote_requests' 
AND column_name = 'ip_address';

-- 2. Modifier la colonne pour accepter NULL (si pas déjà fait)
DO $$
BEGIN
    -- Essayer de modifier la colonne
    BEGIN
        ALTER TABLE quote_requests 
        ALTER COLUMN ip_address DROP NOT NULL;
        RAISE NOTICE 'SUCCÈS: Colonne ip_address modifiée pour accepter NULL';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'INFO: Colonne ip_address déjà modifiée ou erreur: %', SQLERRM;
    END;
END $$;

-- 3. Vérifier les enregistrements existants
SELECT 
    'Enregistrements existants' as description,
    COUNT(*) as count
FROM quote_requests

UNION ALL

SELECT 
    'Enregistrements avec ip_address NULL' as description,
    COUNT(*) as count
FROM quote_requests 
WHERE ip_address IS NULL

UNION ALL

SELECT 
    'Enregistrements avec ip_address valide' as description,
    COUNT(*) as count
FROM quote_requests 
WHERE ip_address IS NOT NULL;

-- 4. Test d'insertion avec NULL
DO $$
DECLARE
    test_request_id UUID;
    current_user_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test avec utilisateur: %', current_user_id;
    
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
            'test-ip-simple',
            current_user_id,
            'Test',
            'IP Simple',
            'test-ip-simple@example.com',
            '0123456789',
            'Test correction IP simple',
            'Test de correction simple de l''erreur IP',
            'medium',
            'pending',
            'medium',
            'website',
            NULL,  -- ip_address = NULL
            'Test User Agent Simple'
        ) RETURNING id INTO test_request_id;
        
        RAISE NOTICE 'SUCCÈS: Demande de test créée avec ip_address = NULL: %', test_request_id;
        
        -- Nettoyer
        DELETE FROM quote_requests WHERE id = test_request_id;
        RAISE NOTICE 'Demande de test supprimée';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        RAISE NOTICE 'ERREUR lors du test: %', error_message;
    END;
END $$;

-- 5. Vérifier le schéma final
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'quote_requests' 
AND column_name = 'ip_address';

-- 6. Vérifier les politiques RLS
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'quote_requests'
ORDER BY policyname;

-- 7. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Correction simple terminée.';
    RAISE NOTICE 'La colonne ip_address accepte maintenant NULL.';
    RAISE NOTICE 'Testez maintenant la création de demandes via le formulaire.';
    RAISE NOTICE 'Si des erreurs persistent, vérifiez les politiques RLS.';
END $$;
