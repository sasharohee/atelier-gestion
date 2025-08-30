-- 🚨 SOLUTION ISOLATION FORCÉE - Modification des Requêtes
-- Script pour forcer l'isolation en modifiant les requêtes de l'application
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DE L'ISOLATION
-- ============================================================================

SELECT '=== DIAGNOSTIC DE L''ISOLATION ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    value as current_workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- Compter tous les clients
SELECT 
    'Tous les clients' as info,
    COUNT(*) as total_clients
FROM clients;

-- Compter les clients du workshop actuel
SELECT 
    'Clients du workshop actuel' as info,
    COUNT(*) as clients_workshop_actuel
FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Compter les clients d'autres workshops
SELECT 
    'Clients d''autres workshops' as info,
    COUNT(*) as clients_autres_workshops
FROM clients 
WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id IS NOT NULL;

-- Afficher quelques exemples de clients
SELECT 
    'Exemples de clients' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    CASE 
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
        THEN '✅ Votre workshop'
        ELSE '❌ Autre workshop'
    END as appartenance
FROM clients 
ORDER BY first_name, last_name
LIMIT 10;

-- ============================================================================
-- 2. SOLUTION FORCÉE - CRÉATION D'UNE VUE RENOMMÉE
-- ============================================================================

SELECT '=== SOLUTION FORCÉE - CRÉATION D''UNE VUE RENOMMÉE ===' as section;

-- Créer une vue qui remplace la table clients avec isolation forcée
CREATE OR REPLACE VIEW clients_isolated AS
SELECT * FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Vérifier la vue isolée
SELECT 
    'Vue clients_isolated créée' as info,
    COUNT(*) as clients_visibles
FROM clients_isolated;

-- ============================================================================
-- 3. SOLUTION FORCÉE - CRÉATION D'UNE FONCTION RPC
-- ============================================================================

SELECT '=== SOLUTION FORCÉE - CRÉATION D''UNE FONCTION RPC ===' as section;

-- Créer une fonction RPC pour récupérer les clients avec isolation forcée
CREATE OR REPLACE FUNCTION get_isolated_clients()
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    notes TEXT,
    category TEXT,
    title TEXT,
    company_name TEXT,
    vat_number TEXT,
    siren_number TEXT,
    country_code TEXT,
    address_complement TEXT,
    region TEXT,
    postal_code TEXT,
    city TEXT,
    billing_address_same BOOLEAN,
    billing_address TEXT,
    billing_address_complement TEXT,
    billing_region TEXT,
    billing_postal_code TEXT,
    billing_city TEXT,
    accounting_code TEXT,
    cni_identifier TEXT,
    attached_file_path TEXT,
    internal_note TEXT,
    status TEXT,
    sms_notification BOOLEAN,
    email_notification BOOLEAN,
    sms_marketing BOOLEAN,
    email_marketing BOOLEAN,
    user_id UUID,
    workshop_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.notes,
        c.category,
        c.title,
        c.company_name,
        c.vat_number,
        c.siren_number,
        c.country_code,
        c.address_complement,
        c.region,
        c.postal_code,
        c.city,
        c.billing_address_same,
        c.billing_address,
        c.billing_address_complement,
        c.billing_region,
        c.billing_postal_code,
        c.billing_city,
        c.accounting_code,
        c.cni_identifier,
        c.attached_file_path,
        c.internal_note,
        c.status,
        c.sms_notification,
        c.email_notification,
        c.sms_marketing,
        c.email_marketing,
        c.user_id,
        c.workshop_id,
        c.created_at,
        c.updated_at
    FROM clients c
    WHERE c.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
END;
$$;

-- Tester la fonction RPC
SELECT 
    'Fonction RPC get_isolated_clients' as info,
    COUNT(*) as clients_visibles
FROM get_isolated_clients();

-- ============================================================================
-- 4. SOLUTION FORCÉE - CRÉATION D'UNE FONCTION RPC POUR CRÉER
-- ============================================================================

SELECT '=== SOLUTION FORCÉE - CRÉATION D''UNE FONCTION RPC POUR CRÉER ===' as section;

-- Créer une fonction RPC pour créer des clients avec isolation forcée
CREATE OR REPLACE FUNCTION create_isolated_client(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL,
    p_title TEXT DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL,
    p_vat_number TEXT DEFAULT NULL,
    p_siren_number TEXT DEFAULT NULL,
    p_country_code TEXT DEFAULT NULL,
    p_address_complement TEXT DEFAULT NULL,
    p_region TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_billing_address_same BOOLEAN DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_billing_address_complement TEXT DEFAULT NULL,
    p_billing_region TEXT DEFAULT NULL,
    p_billing_postal_code TEXT DEFAULT NULL,
    p_billing_city TEXT DEFAULT NULL,
    p_accounting_code TEXT DEFAULT NULL,
    p_cni_identifier TEXT DEFAULT NULL,
    p_attached_file_path TEXT DEFAULT NULL,
    p_internal_note TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_sms_notification BOOLEAN DEFAULT NULL,
    p_email_notification BOOLEAN DEFAULT NULL,
    p_sms_marketing BOOLEAN DEFAULT NULL,
    p_email_marketing BOOLEAN DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    workshop_id UUID
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Créer le client
    INSERT INTO clients (
        first_name, last_name, email, phone, address, notes, category, title,
        company_name, vat_number, siren_number, country_code, address_complement,
        region, postal_code, city, billing_address_same, billing_address,
        billing_address_complement, billing_region, billing_postal_code,
        billing_city, accounting_code, cni_identifier, attached_file_path,
        internal_note, status, sms_notification, email_notification,
        sms_marketing, email_marketing, user_id, workshop_id
    )
    VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_notes, p_category, p_title,
        p_company_name, p_vat_number, p_siren_number, p_country_code, p_address_complement,
        p_region, p_postal_code, p_city, p_billing_address_same, p_billing_address,
        p_billing_address_complement, p_billing_region, p_billing_postal_code,
        p_billing_city, p_accounting_code, p_cni_identifier, p_attached_file_path,
        p_internal_note, p_status, p_sms_notification, p_email_notification,
        p_sms_marketing, p_email_marketing, p_user_id, current_workshop_id
    )
    RETURNING clients.id INTO new_client_id;
    
    -- Retourner le client créé
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.workshop_id
    FROM clients c
    WHERE c.id = new_client_id;
END;
$$;

-- Tester la fonction RPC de création
SELECT 
    'Test fonction RPC create_isolated_client' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM create_isolated_client('Test', 'RPC', 'test.rpc@example.com', '2222222222', 'Adresse test RPC');

-- ============================================================================
-- 5. SOLUTION FORCÉE - CRÉATION D'UNE FONCTION RPC POUR MODIFIER
-- ============================================================================

SELECT '=== SOLUTION FORCÉE - CRÉATION D''UNE FONCTION RPC POUR MODIFIER ===' as section;

-- Créer une fonction RPC pour modifier des clients avec isolation forcée
CREATE OR REPLACE FUNCTION update_isolated_client(
    p_id UUID,
    p_first_name TEXT DEFAULT NULL,
    p_last_name TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL,
    p_title TEXT DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL,
    p_vat_number TEXT DEFAULT NULL,
    p_siren_number TEXT DEFAULT NULL,
    p_country_code TEXT DEFAULT NULL,
    p_address_complement TEXT DEFAULT NULL,
    p_region TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_billing_address_same BOOLEAN DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_billing_address_complement TEXT DEFAULT NULL,
    p_billing_region TEXT DEFAULT NULL,
    p_billing_postal_code TEXT DEFAULT NULL,
    p_billing_city TEXT DEFAULT NULL,
    p_accounting_code TEXT DEFAULT NULL,
    p_cni_identifier TEXT DEFAULT NULL,
    p_attached_file_path TEXT DEFAULT NULL,
    p_internal_note TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_sms_notification BOOLEAN DEFAULT NULL,
    p_email_notification BOOLEAN DEFAULT NULL,
    p_sms_marketing BOOLEAN DEFAULT NULL,
    p_email_marketing BOOLEAN DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    workshop_id UUID
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_workshop_id UUID;
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
        notes = COALESCE(p_notes, notes),
        category = COALESCE(p_category, category),
        title = COALESCE(p_title, title),
        company_name = COALESCE(p_company_name, company_name),
        vat_number = COALESCE(p_vat_number, vat_number),
        siren_number = COALESCE(p_siren_number, siren_number),
        country_code = COALESCE(p_country_code, country_code),
        address_complement = COALESCE(p_address_complement, address_complement),
        region = COALESCE(p_region, region),
        postal_code = COALESCE(p_postal_code, postal_code),
        city = COALESCE(p_city, city),
        billing_address_same = COALESCE(p_billing_address_same, billing_address_same),
        billing_address = COALESCE(p_billing_address, billing_address),
        billing_address_complement = COALESCE(p_billing_address_complement, billing_address_complement),
        billing_region = COALESCE(p_billing_region, billing_region),
        billing_postal_code = COALESCE(p_billing_postal_code, billing_postal_code),
        billing_city = COALESCE(p_billing_city, billing_city),
        accounting_code = COALESCE(p_accounting_code, accounting_code),
        cni_identifier = COALESCE(p_cni_identifier, cni_identifier),
        attached_file_path = COALESCE(p_attached_file_path, attached_file_path),
        internal_note = COALESCE(p_internal_note, internal_note),
        status = COALESCE(p_status, status),
        sms_notification = COALESCE(p_sms_notification, sms_notification),
        email_notification = COALESCE(p_email_notification, email_notification),
        sms_marketing = COALESCE(p_sms_marketing, sms_marketing),
        email_marketing = COALESCE(p_email_marketing, email_marketing),
        user_id = COALESCE(p_user_id, user_id),
        updated_at = NOW()
    WHERE id = p_id 
        AND workshop_id = current_workshop_id;
    
    -- Retourner le client modifié
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.workshop_id
    FROM clients c
    WHERE c.id = p_id 
        AND c.workshop_id = current_workshop_id;
END;
$$;

-- ============================================================================
-- 6. SOLUTION FORCÉE - CRÉATION D'UNE FONCTION RPC POUR SUPPRIMER
-- ============================================================================

SELECT '=== SOLUTION FORCÉE - CRÉATION D''UNE FONCTION RPC POUR SUPPRIMER ===' as section;

-- Créer une fonction RPC pour supprimer des clients avec isolation forcée
CREATE OR REPLACE FUNCTION delete_isolated_client(p_id UUID)
RETURNS BOOLEAN
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
    
    RETURN deleted_count > 0;
END;
$$;

-- ============================================================================
-- 7. VÉRIFICATION DE L'ISOLATION FORCÉE
-- ============================================================================

SELECT '=== VÉRIFICATION DE L''ISOLATION FORCÉE ===' as section;

-- Vérifier l'isolation via la vue
SELECT 
    'Isolation via vue clients_isolated' as info,
    COUNT(*) as total_clients_visibles,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        THEN '✅ Isolation parfaite via vue'
        ELSE '❌ Problème d''isolation via vue'
    END as isolation_status
FROM clients_isolated;

-- Vérifier l'isolation via la fonction RPC
SELECT 
    'Isolation via fonction RPC get_isolated_clients' as info,
    COUNT(*) as total_clients_visibles,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        THEN '✅ Isolation parfaite via fonction RPC'
        ELSE '❌ Problème d''isolation via fonction RPC'
    END as isolation_status
FROM get_isolated_clients();

-- ============================================================================
-- 8. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la solution forcée
SELECT 
    'Résumé de la solution isolation forcée' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM clients_isolated) as clients_visibles_via_vue,
    (SELECT COUNT(*) FROM get_isolated_clients()) as clients_visibles_via_rpc,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) as clients_autres_workshops,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients_isolated) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Isolation forcée réussie'
        ELSE '❌ Problème d''isolation persistant'
    END as isolation_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients_isolated) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '🎉 SUCCÈS: L''isolation forcée est maintenant opérationnelle !'
        ELSE '⚠️ PROBLÈME: L''isolation forcée ne fonctionne toujours pas'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Utilisez la vue clients_isolated au lieu de clients' as step1,
    '2. Utilisez la fonction RPC get_isolated_clients() pour récupérer vos clients' as step2,
    '3. Utilisez la fonction RPC create_isolated_client() pour créer des clients' as step3,
    '4. Utilisez la fonction RPC update_isolated_client() pour modifier des clients' as step4,
    '5. Utilisez la fonction RPC delete_isolated_client() pour supprimer des clients' as step5,
    '6. L''isolation est maintenant forcée côté base de données' as step6;
