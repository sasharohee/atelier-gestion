-- Diagnostic des statistiques de statuts
-- Ce script vérifie pourquoi les statuts "in_review" ne s'affichent pas dans les statistiques

-- 1. Vérifier l'utilisateur actuel
SELECT 
    auth.uid() as current_user_id,
    auth.email() as current_email;

-- 2. Vérifier les demandes existantes avec leurs statuts
SELECT 
    id,
    request_number,
    status,
    client_first_name,
    client_last_name,
    created_at
FROM quote_requests 
WHERE technician_id = auth.uid()
ORDER BY created_at DESC;

-- 3. Compter les demandes par statut
SELECT 
    status,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid()
GROUP BY status
ORDER BY status;

-- 4. Tester la fonction RPC get_quote_request_stats
SELECT get_quote_request_stats(auth.uid()) as stats_result;

-- 5. Vérifier spécifiquement les demandes "in_review"
SELECT 
    'Demandes en cours d''examen' as description,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid() 
AND status = 'in_review';

-- 6. Vérifier les demandes "pending"
SELECT 
    'Demandes en attente' as description,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid() 
AND status = 'pending';

-- 7. Vérifier les demandes "accepted"
SELECT 
    'Demandes acceptées' as description,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid() 
AND status = 'accepted';

-- 8. Test de mise à jour d'un statut vers "in_review"
DO $$
DECLARE
    current_user_id UUID;
    test_request_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    -- Trouver une demande en attente pour la mettre en cours d'examen
    SELECT id INTO test_request_id
    FROM quote_requests 
    WHERE technician_id = current_user_id 
    AND status = 'pending'
    LIMIT 1;
    
    IF test_request_id IS NOT NULL THEN
        -- Mettre à jour le statut
        UPDATE quote_requests 
        SET status = 'in_review',
            updated_at = NOW()
        WHERE id = test_request_id;
        
        RAISE NOTICE 'SUCCÈS: Demande % mise en cours d''examen', test_request_id;
    ELSE
        RAISE NOTICE 'INFO: Aucune demande en attente trouvée pour le test';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
    RAISE NOTICE 'ERREUR lors du test: %', error_message;
END $$;

-- 9. Vérifier les statistiques après mise à jour
SELECT get_quote_request_stats(auth.uid()) as stats_after_update;

-- 10. Vérifier les demandes par statut après mise à jour
SELECT 
    status,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid()
GROUP BY status
ORDER BY status;

-- 11. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Diagnostic terminé.';
    RAISE NOTICE 'Vérifiez que les demandes "in_review" sont bien comptées.';
    RAISE NOTICE 'Si le problème persiste, vérifiez la fonction RPC get_quote_request_stats.';
END $$;
