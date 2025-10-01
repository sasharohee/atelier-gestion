-- Diagnostic ultra-simple pour les demandes de devis
-- Ce script évite toutes les erreurs de colonnes inexistantes

-- 1. Vérifier si les tables existent
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments')
AND table_schema = 'public';

-- 2. Vérifier l'état de RLS sur les tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments');

-- 3. Lister les politiques RLS existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments')
ORDER BY tablename, policyname;

-- 4. Vérifier les utilisateurs authentifiés
SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Tester l'authentification actuelle
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    auth.email() as current_email;

-- 6. Test simple de création d'URL
DO $$
DECLARE
    test_user_id UUID;
    test_url_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer le premier utilisateur disponible
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'Aucun utilisateur trouvé dans auth.users';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test avec utilisateur: %', test_user_id;
    
    BEGIN
        -- Tenter de créer une URL de test
        INSERT INTO technician_custom_urls (technician_id, custom_url, is_active)
        VALUES (test_user_id, 'test-url-' || extract(epoch from now()), true)
        RETURNING id INTO test_url_id;
        
        RAISE NOTICE 'SUCCÈS: URL créée avec ID: %', test_url_id;
        
        -- Nettoyer
        DELETE FROM technician_custom_urls WHERE id = test_url_id;
        RAISE NOTICE 'URL de test supprimée';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        RAISE NOTICE 'ERREUR lors de la création: %', error_message;
    END;
END $$;

-- 7. Vérifier la structure de la table technician_custom_urls
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'technician_custom_urls'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. Compter les enregistrements existants
SELECT 
    'technician_custom_urls' as table_name,
    COUNT(*) as record_count
FROM technician_custom_urls
UNION ALL
SELECT 
    'quote_requests' as table_name,
    COUNT(*) as record_count
FROM quote_requests
UNION ALL
SELECT 
    'quote_request_attachments' as table_name,
    COUNT(*) as record_count
FROM quote_request_attachments;

-- 9. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Diagnostic terminé. Vérifiez les résultats ci-dessus.';
    RAISE NOTICE 'Si le test de création d''URL a échoué, exécutez FIX_RLS_SIMPLE_QUOTE_REQUESTS.sql';
END $$;
