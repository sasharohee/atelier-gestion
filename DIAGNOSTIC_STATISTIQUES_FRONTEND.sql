-- Diagnostic des statistiques pour le frontend
-- Ce script vérifie exactement ce qui est retourné par la fonction RPC

-- 1. Vérifier l'utilisateur actuel
SELECT 
    auth.uid() as current_user_id,
    auth.email() as current_email;

-- 2. Vérifier les demandes existantes
SELECT 
    id,
    request_number,
    status,
    created_at
FROM quote_requests 
WHERE technician_id = auth.uid()
ORDER BY created_at DESC;

-- 3. Compter manuellement par statut
SELECT 
    'Comptage manuel' as description,
    status,
    COUNT(*) as count
FROM quote_requests 
WHERE technician_id = auth.uid()
GROUP BY status
ORDER BY status;

-- 4. Tester la fonction RPC et voir sa structure
SELECT get_quote_request_stats(auth.uid()) as stats_result;

-- 5. Vérifier la structure JSON retournée
SELECT 
    get_quote_request_stats(auth.uid()) as stats_json;

-- 6. Extraire spécifiquement les valeurs importantes
SELECT 
    (get_quote_request_stats(auth.uid())->>'total')::int as total,
    (get_quote_request_stats(auth.uid())->>'pending')::int as pending,
    (get_quote_request_stats(auth.uid())->>'in_review')::int as in_review,
    (get_quote_request_stats(auth.uid())->>'quoted')::int as quoted,
    (get_quote_request_stats(auth.uid())->>'accepted')::int as accepted,
    (get_quote_request_stats(auth.uid())->>'rejected')::int as rejected;

-- 7. Vérifier les clés disponibles dans le JSON
SELECT 
    jsonb_object_keys(get_quote_request_stats(auth.uid())) as available_keys;

-- 8. Test de mise à jour d'une demande vers "in_review"
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

-- 9. Vérifier les statistiques après mise à jour
SELECT 
    'Après mise à jour' as description,
    (get_quote_request_stats(auth.uid())->>'in_review')::int as in_review_count;

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
    RAISE NOTICE 'Vérifiez que la clé "in_review" existe dans le JSON.';
    RAISE NOTICE 'Vérifiez que la valeur est correcte.';
END $$;
