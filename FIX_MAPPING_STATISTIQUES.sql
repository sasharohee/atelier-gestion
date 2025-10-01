-- Correction du mapping des statistiques
-- Ce script corrige le problème de mapping entre la fonction RPC et le frontend

-- 1. Vérifier la structure actuelle de la fonction RPC
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_quote_request_stats';

-- 2. Recréer la fonction RPC avec la bonne structure
CREATE OR REPLACE FUNCTION get_quote_request_stats(technician_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total', COUNT(*),
        'pending', COUNT(*) FILTER (WHERE status = 'pending'),
        'inReview', COUNT(*) FILTER (WHERE status = 'in_review'),
        'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
        'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
        'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
        'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
        'byUrgency', json_build_object(
            'low', COUNT(*) FILTER (WHERE urgency = 'low'),
            'medium', COUNT(*) FILTER (WHERE urgency = 'medium'),
            'high', COUNT(*) FILTER (WHERE urgency = 'high')
        ),
        'byStatus', json_build_object(
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

-- 3. Tester la fonction recréée
SELECT get_quote_request_stats(auth.uid()) as new_stats;

-- 4. Vérifier la structure JSON
SELECT 
    jsonb_pretty(get_quote_request_stats(auth.uid())) as pretty_stats;

-- 5. Vérifier les clés importantes
SELECT 
    (get_quote_request_stats(auth.uid())->>'total')::int as total,
    (get_quote_request_stats(auth.uid())->>'pending')::int as pending,
    (get_quote_request_stats(auth.uid())->>'inReview')::int as inReview,
    (get_quote_request_stats(auth.uid())->>'quoted')::int as quoted,
    (get_quote_request_stats(auth.uid())->>'accepted')::int as accepted,
    (get_quote_request_stats(auth.uid())->>'rejected')::int as rejected;

-- 6. Test de mise à jour d'une demande vers "in_review"
DO $$
DECLARE
    current_user_id UUID;
    test_request_id UUID;
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
END $$;

-- 7. Vérifier les statistiques après mise à jour
SELECT 
    'Après mise à jour' as description,
    (get_quote_request_stats(auth.uid())->>'inReview')::int as inReview_count;

-- 8. Vérifier les demandes par statut après mise à jour
SELECT 
    status,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid()
GROUP BY status
ORDER BY status;

-- 9. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Correction terminée.';
    RAISE NOTICE 'La fonction RPC utilise maintenant "inReview" au lieu de "in_review".';
    RAISE NOTICE 'Testez maintenant l''affichage des statistiques.';
END $$;
