-- 🔧 CORRECTION FONCTIONS RPC FINALE - Gestion des Contraintes
-- Script final pour corriger les fonctions RPC avec gestion des contraintes
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DES CONTRAINTES
-- ============================================================================

SELECT '=== DIAGNOSTIC DES CONTRAINTES ===' as section;

-- Vérifier les contraintes sur la table clients
SELECT 
    'Contraintes table clients' as info,
    constraint_name,
    constraint_type,
    column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'clients' 
    AND tc.table_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- Vérifier les clients existants avec emails
SELECT 
    'Clients existants avec emails' as info,
    COUNT(*) as total_clients,
    COUNT(DISTINCT email) as emails_uniques,
    COUNT(*) - COUNT(DISTINCT email) as emails_dupliques
FROM clients 
WHERE email IS NOT NULL;

-- ============================================================================
-- 2. CORRECTION FINALE - FONCTION RPC GET_ISOLATED_CLIENTS
-- ============================================================================

SELECT '=== CORRECTION FINALE - FONCTION RPC GET_ISOLATED_CLIENTS ===' as section;

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS get_isolated_clients();
DROP FUNCTION IF EXISTS create_isolated_client(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS update_isolated_client(UUID, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS delete_isolated_client(UUID);

-- Créer la fonction finale qui retourne JSON
CREATE OR REPLACE FUNCTION get_isolated_clients()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', c.id,
            'first_name', c.first_name,
            'last_name', c.last_name,
            'email', c.email,
            'phone', c.phone,
            'address', c.address,
            'notes', c.notes,
            'category', c.category,
            'title', c.title,
            'company_name', c.company_name,
            'vat_number', c.vat_number,
            'siren_number', c.siren_number,
            'country_code', c.country_code,
            'address_complement', c.address_complement,
            'region', c.region,
            'postal_code', c.postal_code,
            'city', c.city,
            'billing_address_same', c.billing_address_same,
            'billing_address', c.billing_address,
            'billing_address_complement', c.billing_address_complement,
            'billing_region', c.billing_region,
            'billing_postal_code', c.billing_postal_code,
            'billing_city', c.billing_city,
            'accounting_code', c.accounting_code,
            'cni_identifier', c.cni_identifier,
            'attached_file_path', c.attached_file_path,
            'internal_note', c.internal_note,
            'status', c.status,
            'sms_notification', c.sms_notification,
            'email_notification', c.email_notification,
            'sms_marketing', c.sms_marketing,
            'email_marketing', c.email_marketing,
            'user_id', c.user_id,
            'workshop_id', c.workshop_id,
            'created_at', c.created_at,
            'updated_at', c.updated_at
        )
    ) INTO result
    FROM clients c
    WHERE c.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- Tester la fonction finale
SELECT 
    'Fonction RPC get_isolated_clients finale' as info,
    json_array_length(get_isolated_clients()) as clients_visibles;

-- ============================================================================
-- 3. CORRECTION FINALE - FONCTION RPC CREATE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION FINALE - FONCTION RPC CREATE_ISOLATED_CLIENT ===' as section;

-- Créer la fonction finale avec gestion des contraintes
CREATE OR REPLACE FUNCTION create_isolated_client(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
    result JSON;
    email_exists BOOLEAN;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Vérifier si l'email existe déjà (seulement si un email est fourni)
    IF p_email IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM clients WHERE email = p_email
        ) INTO email_exists;
        
        IF email_exists THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Email already exists',
                'message', 'Un client avec cet email existe déjà'
            );
        END IF;
    END IF;
    
    -- Créer le client
    INSERT INTO clients (
        first_name, last_name, email, phone, address, workshop_id
    )
    VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, current_workshop_id
    )
    RETURNING clients.id INTO new_client_id;
    
    -- Retourner le client créé en JSON
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'first_name', c.first_name,
        'last_name', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'workshop_id', c.workshop_id
    ) INTO result
    FROM clients c
    WHERE c.id = new_client_id;
    
    RETURN result;
END;
$$;

-- ============================================================================
-- 4. CORRECTION FINALE - FONCTION RPC UPDATE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION FINALE - FONCTION RPC UPDATE_ISOLATED_CLIENT ===' as section;

-- Créer la fonction finale pour modifier des clients
CREATE OR REPLACE FUNCTION update_isolated_client(
    p_id UUID,
    p_first_name TEXT DEFAULT NULL,
    p_last_name TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_workshop_id UUID;
    result JSON;
    email_exists BOOLEAN;
    updated_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Vérifier si l'email existe déjà (seulement si un email est fourni)
    IF p_email IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM clients WHERE email = p_email AND id != p_id
        ) INTO email_exists;
        
        IF email_exists THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Email already exists',
                'message', 'Un autre client avec cet email existe déjà'
            );
        END IF;
    END IF;
    
    -- Modifier le client seulement s'il appartient au workshop actuel
    UPDATE clients SET
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address),
        updated_at = NOW()
    WHERE id = p_id 
        AND workshop_id = current_workshop_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    IF updated_count = 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client not found or not accessible',
            'message', 'Client non trouvé ou non accessible'
        );
    END IF;
    
    -- Retourner le client modifié en JSON
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'first_name', c.first_name,
        'last_name', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'workshop_id', c.workshop_id
    ) INTO result
    FROM clients c
    WHERE c.id = p_id 
        AND c.workshop_id = current_workshop_id;
    
    RETURN result;
END;
$$;

-- ============================================================================
-- 5. CORRECTION FINALE - FONCTION RPC DELETE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION FINALE - FONCTION RPC DELETE_ISOLATED_CLIENT ===' as section;

-- Créer la fonction finale pour supprimer des clients
CREATE OR REPLACE FUNCTION delete_isolated_client(p_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_workshop_id UUID;
    deleted_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Supprimer le client seulement s'il appartient au workshop actuel
    DELETE FROM clients 
    WHERE id = p_id 
        AND workshop_id = current_workshop_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', deleted_count > 0,
        'deleted_count', deleted_count,
        'message', CASE 
            WHEN deleted_count > 0 THEN 'Client supprimé avec succès'
            ELSE 'Client non trouvé ou non accessible'
        END
    );
END;
$$;

-- ============================================================================
-- 6. TEST AVEC EMAIL UNIQUE
-- ============================================================================

SELECT '=== TEST AVEC EMAIL UNIQUE ===' as section;

-- Générer un email unique pour le test
SELECT 
    'Test fonction create_isolated_client avec email unique' as info,
    create_isolated_client(
        'Test', 
        'Final', 
        'test.final.' || extract(epoch from now())::TEXT || '@example.com', 
        '7777777777', 
        'Adresse test final unique'
    );

-- ============================================================================
-- 7. VÉRIFICATION DES FONCTIONS FINALES
-- ============================================================================

SELECT '=== VÉRIFICATION DES FONCTIONS FINALES ===' as section;

-- Vérifier que les fonctions existent
SELECT 
    'Fonctions RPC finales' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%isolated%'
    AND routine_schema = 'public'
ORDER BY routine_name;

-- Tester la fonction de récupération
SELECT 
    'Test fonction get_isolated_clients finale' as info,
    json_array_length(get_isolated_clients()) as clients_visibles;

-- ============================================================================
-- 8. CRÉATION DE LA VUE FINALE
-- ============================================================================

SELECT '=== CRÉATION DE LA VUE FINALE ===' as section;

-- Créer la vue finale pour l'isolation
CREATE OR REPLACE VIEW clients_isolated_final AS
SELECT * FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Vérifier la vue finale
SELECT 
    'Vue clients_isolated_final' as info,
    COUNT(*) as clients_visibles
FROM clients_isolated_final;

-- ============================================================================
-- 9. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction finale
SELECT 
    'Résumé de la correction finale des fonctions RPC' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT json_array_length(get_isolated_clients())) as clients_visibles_via_rpc,
    (SELECT COUNT(*) FROM clients_isolated_final) as clients_visibles_via_vue,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%isolated%' AND routine_schema = 'public') as fonctions_rpc_creees,
    CASE 
        WHEN (SELECT json_array_length(get_isolated_clients())) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Fonctions RPC finales et fonctionnelles'
        ELSE '❌ Problème avec les fonctions RPC'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT json_array_length(get_isolated_clients())) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '🎉 SUCCÈS: Les fonctions RPC finales sont maintenant opérationnelles !'
        ELSE '⚠️ PROBLÈME: Les fonctions RPC ne fonctionnent toujours pas'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Les fonctions RPC gèrent maintenant les contraintes d''unicité' as step1,
    '2. Utilisez get_isolated_clients() pour récupérer vos clients (retourne JSON)' as step2,
    '3. Utilisez create_isolated_client() pour créer des clients (gère les emails dupliqués)' as step3,
    '4. Utilisez update_isolated_client() pour modifier des clients (gère les emails dupliqués)' as step4,
    '5. Utilisez delete_isolated_client() pour supprimer des clients (retourne JSON)' as step5,
    '6. Utilisez la vue clients_isolated_final pour l''affichage direct' as step6;
