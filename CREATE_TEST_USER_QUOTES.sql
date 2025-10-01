-- Script pour créer un utilisateur de test pour les demandes de devis
-- Ce script résout le problème d'ID utilisateur inexistant

-- 1. Vérifier les utilisateurs existants
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. Créer un utilisateur de test si aucun n'existe
-- ATTENTION: Cette approche ne fonctionne que si vous avez les permissions admin
-- Sinon, utilisez l'interface d'authentification de Supabase

-- 3. Alternative: Vérifier si l'utilisateur actuel existe
SELECT 
    auth.uid() as current_user_id,
    auth.email() as current_email,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'Utilisateur authentifié'
        ELSE 'Aucun utilisateur authentifié'
    END as auth_status;

-- 4. Vérifier les contraintes de clés étrangères
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
WHERE tc.table_name = 'technician_custom_urls'
AND tc.constraint_type = 'FOREIGN KEY';

-- 5. Test de création d'URL avec l'utilisateur actuel
DO $$
DECLARE
    current_user_id UUID;
    test_url_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test avec utilisateur authentifié: %', current_user_id;
    
    BEGIN
        -- Tenter de créer une URL de test
        INSERT INTO technician_custom_urls (technician_id, custom_url, is_active)
        VALUES (current_user_id, 'test-url-' || extract(epoch from now()), true)
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

-- 6. Vérifier les données existantes
SELECT 
    'technician_custom_urls' as table_name,
    COUNT(*) as record_count
FROM technician_custom_urls
UNION ALL
SELECT 
    'quote_requests' as table_name,
    COUNT(*) as record_count
FROM quote_requests;

-- 7. Lister les URLs existantes
SELECT 
    id,
    technician_id,
    custom_url,
    is_active,
    created_at
FROM technician_custom_urls
ORDER BY created_at DESC;

-- 8. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Diagnostic terminé.';
    RAISE NOTICE 'Si vous voyez "Aucun utilisateur authentifié", connectez-vous d''abord dans l''application.';
    RAISE NOTICE 'Si le test de création d''URL a échoué, vérifiez les politiques RLS.';
END $$;
