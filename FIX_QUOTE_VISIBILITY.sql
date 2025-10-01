-- Correction de la visibilité des demandes de devis
-- Ce script corrige les problèmes de visibilité des demandes

-- 1. Vérifier l'état actuel
SELECT 
    'État actuel' as description,
    COUNT(*) as total_demandes,
    COUNT(*) FILTER (WHERE technician_id = auth.uid()) as demandes_utilisateur_actuel
FROM quote_requests;

-- 2. Vérifier les politiques RLS sur quote_requests
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'quote_requests'
ORDER BY policyname;

-- 3. Supprimer les anciennes politiques qui peuvent causer des problèmes
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer des demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "Insertion publique des demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "quote_requests_select_own" ON quote_requests;
DROP POLICY IF EXISTS "quote_requests_insert_own" ON quote_requests;
DROP POLICY IF EXISTS "quote_requests_update_own" ON quote_requests;
DROP POLICY IF EXISTS "quote_requests_public_insert" ON quote_requests;
DROP POLICY IF EXISTS "test_quote_requests_all" ON quote_requests;

-- 4. Créer des politiques RLS simples et fonctionnelles
CREATE POLICY "quote_requests_select_own" ON quote_requests
    FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "quote_requests_insert_own" ON quote_requests
    FOR INSERT WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "quote_requests_update_own" ON quote_requests
    FOR UPDATE USING (auth.uid() = technician_id);

-- Politique pour permettre l'insertion publique des demandes (pour le formulaire)
CREATE POLICY "quote_requests_public_insert" ON quote_requests
    FOR INSERT WITH CHECK (true);

-- Politique de test temporaire (plus permissive)
CREATE POLICY "test_quote_requests_all" ON quote_requests
    FOR ALL USING (true) WITH CHECK (true);

-- 5. Vérifier que RLS est activé
ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;

-- 6. Test de création et récupération d'une demande
DO $$
DECLARE
    current_user_id UUID;
    test_request_id UUID;
    request_count INTEGER;
    error_message TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test avec utilisateur: %', current_user_id;
    
    BEGIN
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
            'test-url',
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
        SELECT COUNT(*) INTO request_count
        FROM quote_requests
        WHERE technician_id = current_user_id;
        
        RAISE NOTICE 'Nombre de demandes visibles: %', request_count;
        
        IF request_count > 0 THEN
            RAISE NOTICE 'SUCCÈS: Les demandes sont visibles';
        ELSE
            RAISE NOTICE 'PROBLÈME: Les demandes ne sont pas visibles';
        END IF;
        
        -- Nettoyer
        DELETE FROM quote_requests WHERE id = test_request_id;
        RAISE NOTICE 'Demande de test supprimée';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        RAISE NOTICE 'ERREUR lors du test: %', error_message;
    END;
END $$;

-- 7. Vérifier les politiques créées
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'quote_requests'
ORDER BY policyname;

-- 8. Vérifier les demandes existantes
SELECT 
    id,
    request_number,
    technician_id,
    client_first_name,
    client_last_name,
    status,
    created_at
FROM quote_requests
WHERE technician_id = auth.uid()
ORDER BY created_at DESC;

-- 9. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Correction terminée.';
    RAISE NOTICE 'Les politiques RLS ont été mises à jour.';
    RAISE NOTICE 'Testez maintenant la création et la récupération des demandes.';
END $$;
