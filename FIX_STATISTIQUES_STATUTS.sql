-- Correction des statistiques de statuts
-- Ce script corrige le problème des statistiques qui ne s'affichent pas correctement

-- 1. Vérifier l'état actuel
SELECT 
    'État actuel des demandes' as description,
    status,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid()
GROUP BY status
ORDER BY status;

-- 2. Vérifier la fonction RPC
SELECT get_quote_request_stats(auth.uid()) as current_stats;

-- 3. Recréer la fonction RPC si nécessaire
CREATE OR REPLACE FUNCTION get_quote_request_stats(technician_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total', COUNT(*),
        'pending', COUNT(*) FILTER (WHERE status = 'pending'),
        'in_review', COUNT(*) FILTER (WHERE status = 'in_review'),
        'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
        'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
        'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
        'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
        'by_urgency', json_build_object(
            'low', COUNT(*) FILTER (WHERE urgency = 'low'),
            'medium', COUNT(*) FILTER (WHERE urgency = 'medium'),
            'high', COUNT(*) FILTER (WHERE urgency = 'high')
        ),
        'by_status', json_build_object(
            'pending', COUNT(*) FILTER (WHERE status = 'pending'),
            'in_review', COUNT(*) FILTER (WHERE status = 'in_review'),
            'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
            'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
            'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
            'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
        ),
        'monthly', COUNT(*) FILTER (WHERE created_at >= date_trunc('month', NOW())),
        'weekly', COUNT(*) FILTER (WHERE created_at >= date_trunc('week', NOW())),
        'daily', COUNT(*) FILTER (WHERE created_at >= date_trunc('day', NOW()))
    ) INTO result
    FROM quote_requests
    WHERE technician_id = technician_uuid;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Tester la fonction recréée
SELECT get_quote_request_stats(auth.uid()) as new_stats;

-- 5. Vérifier les permissions sur la fonction
SELECT 
    routine_name,
    routine_type,
    security_type,
    is_deterministic
FROM information_schema.routines 
WHERE routine_name = 'get_quote_request_stats';

-- 6. Test de mise à jour d'une demande vers "in_review"
DO $$
DECLARE
    current_user_id UUID;
    test_request_id UUID;
    error_message TEXT;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié.';
        RETURN;
    END IF;
    
    -- Trouver une demande en attente
    SELECT id INTO test_request_id
    FROM quote_requests 
    WHERE technician_id = current_user_id 
    AND status = 'pending'
    LIMIT 1;
    
    IF test_request_id IS NOT NULL THEN
        -- Mettre à jour vers "in_review"
        UPDATE quote_requests 
        SET status = 'in_review',
            updated_at = NOW()
        WHERE id = test_request_id;
        
        RAISE NOTICE 'SUCCÈS: Demande % mise en cours d''examen', test_request_id;
    ELSE
        RAISE NOTICE 'INFO: Aucune demande en attente trouvée';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
    RAISE NOTICE 'ERREUR: %', error_message;
END $$;

-- 7. Vérifier les statistiques après correction
SELECT 
    'Statistiques après correction' as description,
    status,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid()
GROUP BY status
ORDER BY status;

-- 8. Test final de la fonction RPC
SELECT get_quote_request_stats(auth.uid()) as final_stats;

-- 9. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Correction terminée.';
    RAISE NOTICE 'La fonction RPC a été recréée.';
    RAISE NOTICE 'Testez maintenant l''affichage des statistiques.';
END $$;
