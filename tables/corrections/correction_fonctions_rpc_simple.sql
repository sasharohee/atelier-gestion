-- 🔧 CORRECTION FONCTIONS RPC SIMPLE - Types de Base
-- Script pour corriger les fonctions RPC avec des types simples
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DES TYPES DE DONNÉES
-- ============================================================================

SELECT '=== DIAGNOSTIC DES TYPES DE DONNÉES ===' as section;

-- Vérifier la structure de la table clients
SELECT 
    'Structure table clients' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. CORRECTION SIMPLE - FONCTION RPC GET_ISOLATED_CLIENTS
-- ============================================================================

SELECT '=== CORRECTION SIMPLE - FONCTION RPC GET_ISOLATED_CLIENTS ===' as section;

-- Supprimer toutes les anciennes fonctions
DROP FUNCTION IF EXISTS get_isolated_clients();
DROP FUNCTION IF EXISTS create_isolated_client(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS update_isolated_client(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, VARCHAR, TEXT, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, UUID);
DROP FUNCTION IF EXISTS update_isolated_client(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, VARCHAR, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, VARCHAR, TEXT, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, UUID);

-- Créer une fonction simple qui retourne JSON pour éviter les problèmes de types
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

-- Tester la fonction simple
SELECT 
    'Fonction RPC get_isolated_clients simple' as info,
    json_array_length(get_isolated_clients()) as clients_visibles;

-- ============================================================================
-- 3. CORRECTION SIMPLE - FONCTION RPC CREATE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION SIMPLE - FONCTION RPC CREATE_ISOLATED_CLIENT ===' as section;

-- Créer une fonction simple pour créer des clients
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
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
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

-- Tester la fonction simple de création
SELECT 
    'Test fonction RPC create_isolated_client simple' as info,
    create_isolated_client('Test', 'Simple', 'test.simple@example.com', '5555555555', 'Adresse test simple');

-- ============================================================================
-- 4. CORRECTION SIMPLE - FONCTION RPC UPDATE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION SIMPLE - FONCTION RPC UPDATE_ISOLATED_CLIENT ===' as section;

-- Créer une fonction simple pour modifier des clients
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
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
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
    
    -- Retourner le client modifié en JSON
    SELECT json_build_object(
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
-- 5. CORRECTION SIMPLE - FONCTION RPC DELETE_ISOLATED_CLIENT
-- ============================================================================

SELECT '=== CORRECTION SIMPLE - FONCTION RPC DELETE_ISOLATED_CLIENT ===' as section;

-- Créer une fonction simple pour supprimer des clients
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
        'deleted_count', deleted_count
    );
END;
$$;

-- ============================================================================
-- 6. VÉRIFICATION DES FONCTIONS SIMPLES
-- ============================================================================

SELECT '=== VÉRIFICATION DES FONCTIONS SIMPLES ===' as section;

-- Vérifier que les fonctions existent
SELECT 
    'Fonctions RPC simples' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%isolated%'
    AND routine_schema = 'public'
ORDER BY routine_name;

-- Tester la fonction de récupération
SELECT 
    'Test fonction get_isolated_clients simple' as info,
    json_array_length(get_isolated_clients()) as clients_visibles;

-- Tester la fonction de création
SELECT 
    'Test fonction create_isolated_client simple' as info,
    create_isolated_client('Test', 'Final', 'test.final@example.com', '6666666666', 'Adresse test final');

-- ============================================================================
-- 7. CRÉATION D'UNE VUE SIMPLE POUR L'ISOLATION
-- ============================================================================

SELECT '=== CRÉATION D''UNE VUE SIMPLE POUR L''ISOLATION ===' as section;

-- Créer une vue simple pour l'isolation
CREATE OR REPLACE VIEW clients_isolated_simple AS
SELECT * FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Vérifier la vue simple
SELECT 
    'Vue clients_isolated_simple' as info,
    COUNT(*) as clients_visibles
FROM clients_isolated_simple;

-- ============================================================================
-- 8. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction simple
SELECT 
    'Résumé de la correction simple des fonctions RPC' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT json_array_length(get_isolated_clients())) as clients_visibles_via_rpc,
    (SELECT COUNT(*) FROM clients_isolated_simple) as clients_visibles_via_vue,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%isolated%' AND routine_schema = 'public') as fonctions_rpc_creees,
    CASE 
        WHEN (SELECT json_array_length(get_isolated_clients())) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Fonctions RPC simples et fonctionnelles'
        ELSE '❌ Problème avec les fonctions RPC'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT json_array_length(get_isolated_clients())) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '🎉 SUCCÈS: Les fonctions RPC simples sont maintenant fonctionnelles !'
        ELSE '⚠️ PROBLÈME: Les fonctions RPC ne fonctionnent toujours pas'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Les fonctions RPC utilisent maintenant JSON pour éviter les conflits de types' as step1,
    '2. Utilisez get_isolated_clients() pour récupérer vos clients (retourne JSON)' as step2,
    '3. Utilisez create_isolated_client() pour créer des clients (retourne JSON)' as step3,
    '4. Utilisez update_isolated_client() pour modifier des clients (retourne JSON)' as step4,
    '5. Utilisez delete_isolated_client() pour supprimer des clients (retourne JSON)' as step5,
    '6. Utilisez la vue clients_isolated_simple pour l''affichage direct' as step6;
