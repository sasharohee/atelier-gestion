-- Diagnostic de la visibilité des demandes de devis
-- Ce script aide à identifier pourquoi les demandes ne sont pas visibles

-- 1. Vérifier l'utilisateur actuellement authentifié
SELECT 
    auth.uid() as current_user_id,
    auth.email() as current_email,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'Utilisateur authentifié'
        ELSE 'Aucun utilisateur authentifié'
    END as auth_status;

-- 2. Vérifier les URLs personnalisées existantes
SELECT 
    id,
    technician_id,
    custom_url,
    is_active,
    created_at
FROM technician_custom_urls
ORDER BY created_at DESC;

-- 3. Vérifier les demandes de devis existantes
SELECT 
    id,
    request_number,
    custom_url,
    technician_id,
    client_first_name,
    client_last_name,
    client_email,
    status,
    created_at
FROM quote_requests
ORDER BY created_at DESC;

-- 4. Vérifier la correspondance entre utilisateur et demandes
SELECT 
    'Demandes pour utilisateur actuel' as description,
    COUNT(*) as count
FROM quote_requests
WHERE technician_id = auth.uid()

UNION ALL

SELECT 
    'Demandes pour toutes les URLs de l''utilisateur' as description,
    COUNT(*) as count
FROM quote_requests qr
JOIN technician_custom_urls tcu ON qr.technician_id = tcu.technician_id
WHERE tcu.technician_id = auth.uid()

UNION ALL

SELECT 
    'Total des demandes' as description,
    COUNT(*) as count
FROM quote_requests;

-- 5. Vérifier les URLs de l'utilisateur actuel
SELECT 
    'URLs de l''utilisateur actuel' as description,
    COUNT(*) as count
FROM technician_custom_urls
WHERE technician_id = auth.uid();

-- 6. Test de création d'une demande de test
DO $$
DECLARE
    current_user_id UUID;
    test_url_id UUID;
    test_request_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test avec utilisateur: %', current_user_id;
    
    -- Créer une URL de test
    BEGIN
        INSERT INTO technician_custom_urls (technician_id, custom_url, is_active)
        VALUES (current_user_id, 'test-url-' || extract(epoch from now()), true)
        RETURNING id INTO test_url_id;
        
        RAISE NOTICE 'URL de test créée: %', test_url_id;
        
        -- Créer une demande de test
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
            source
        ) VALUES (
            'QR-TEST-' || extract(epoch from now()),
            'test-url-' || extract(epoch from now()),
            current_user_id,
            'Test',
            'Client',
            'test@example.com',
            '0123456789',
            'Test de demande',
            'Problème de test',
            'medium',
            'pending',
            'medium',
            'website'
        ) RETURNING id INTO test_request_id;
        
        RAISE NOTICE 'Demande de test créée: %', test_request_id;
        
        -- Vérifier que la demande est visible
        IF EXISTS (
            SELECT 1 FROM quote_requests 
            WHERE id = test_request_id 
            AND technician_id = current_user_id
        ) THEN
            RAISE NOTICE 'SUCCÈS: La demande est visible pour l''utilisateur';
        ELSE
            RAISE NOTICE 'PROBLÈME: La demande n''est pas visible pour l''utilisateur';
        END IF;
        
        -- Nettoyer
        DELETE FROM quote_requests WHERE id = test_request_id;
        DELETE FROM technician_custom_urls WHERE id = test_url_id;
        RAISE NOTICE 'Données de test supprimées';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        RAISE NOTICE 'ERREUR lors du test: %', error_message;
    END;
END $$;

-- 7. Vérifier les politiques RLS sur quote_requests
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'quote_requests'
ORDER BY policyname;

-- 8. Vérifier les statistiques
SELECT 
    'Statistiques pour utilisateur actuel' as description,
    json_build_object(
        'total', COUNT(*),
        'pending', COUNT(*) FILTER (WHERE status = 'pending'),
        'in_review', COUNT(*) FILTER (WHERE status = 'in_review'),
        'quoted', COUNT(*) FILTER (WHERE status = 'quoted')
    ) as stats
FROM quote_requests
WHERE technician_id = auth.uid();

-- 9. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Diagnostic terminé.';
    RAISE NOTICE 'Vérifiez que les demandes sont bien associées au bon utilisateur.';
    RAISE NOTICE 'Si les demandes ne sont pas visibles, vérifiez les politiques RLS.';
END $$;
