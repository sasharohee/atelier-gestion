-- Diagnostic simplifié pour les demandes de devis
-- Ce script évite les erreurs de colonnes inexistantes

-- 1. Vérifier l'état de RLS sur les tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments');

-- 2. Lister toutes les politiques RLS existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments')
ORDER BY tablename, policyname;

-- 3. Vérifier les utilisateurs authentifiés
SELECT 
    id,
    email,
    created_at,
    last_sign_in_at,
    email_confirmed_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. Vérifier les profils utilisateurs (si la table existe)
SELECT 
    user_id,
    first_name,
    last_name,
    email
FROM user_profiles 
ORDER BY created_at DESC 
LIMIT 10;

-- 5. Tester la fonction d'authentification
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    auth.email() as current_email;

-- 6. Vérifier les permissions sur les tables
SELECT 
    table_name,
    privilege_type,
    grantee
FROM information_schema.table_privileges 
WHERE table_name IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments')
AND table_schema = 'public';

-- 7. Créer une fonction de test pour l'authentification
CREATE OR REPLACE FUNCTION test_auth_for_quotes()
RETURNS TABLE(
    is_authenticated BOOLEAN,
    user_id UUID,
    user_email TEXT,
    can_create_urls BOOLEAN,
    can_create_requests BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        auth.uid() IS NOT NULL as is_authenticated,
        auth.uid() as user_id,
        auth.email() as user_email,
        auth.uid() IS NOT NULL as can_create_urls,
        true as can_create_requests;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Exécuter le test d'authentification
SELECT * FROM test_auth_for_quotes();

-- 9. Vérifier les contraintes de clés étrangères
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments')
AND tc.constraint_type = 'FOREIGN KEY';

-- 10. Test de création d'URL avec gestion d'erreur
DO $$
DECLARE
    test_user_id UUID;
    test_url_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer un utilisateur de test
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
        
        RAISE NOTICE 'URL créée avec succès, ID: %', test_url_id;
        
        -- Nettoyer
        DELETE FROM technician_custom_urls WHERE id = test_url_id;
        RAISE NOTICE 'URL de test supprimée';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        RAISE NOTICE 'Erreur lors de la création: %', error_message;
    END;
END $$;

-- 11. Vérifier si les tables existent
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments')
AND table_schema = 'public';

-- 12. Vérifier la structure des tables
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'technician_custom_urls'
AND table_schema = 'public'
ORDER BY ordinal_position;
