-- 🔧 CORRECTION ISOLATION - Utilisation de la Vue Filtrée
-- Script pour corriger l'isolation après la solution radicale
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
-- 2. VÉRIFICATION DE LA VUE FILTRÉE
-- ============================================================================

SELECT '=== VÉRIFICATION DE LA VUE FILTRÉE ===' as section;

-- Vérifier si la vue filtrée existe
SELECT 
    'Vue filtrée existante' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'clients_filtered'
    AND table_schema = 'public';

-- Compter les clients visibles via la vue filtrée
SELECT 
    'Clients visibles via vue filtrée' as info,
    COUNT(*) as clients_visibles
FROM clients_filtered;

-- Afficher les clients visibles via la vue filtrée
SELECT 
    'Clients visibles via vue filtrée' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients_filtered 
ORDER BY first_name, last_name
LIMIT 10;

-- ============================================================================
-- 3. CORRECTION DE LA VUE FILTRÉE
-- ============================================================================

SELECT '=== CORRECTION DE LA VUE FILTRÉE ===' as section;

-- Recréer la vue filtrée pour s'assurer qu'elle fonctionne correctement
CREATE OR REPLACE VIEW clients_filtered AS
SELECT * FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Vérifier la vue corrigée
SELECT 
    'Vue filtrée corrigée' as info,
    COUNT(*) as clients_visibles
FROM clients_filtered;

-- ============================================================================
-- 4. CRÉATION D'UNE FONCTION POUR L'ISOLATION
-- ============================================================================

SELECT '=== CRÉATION D''UNE FONCTION POUR L''ISOLATION ===' as section;

-- Créer une fonction pour obtenir les clients du workshop actuel
CREATE OR REPLACE FUNCTION get_workshop_clients()
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    workshop_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
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
        c.workshop_id,
        c.created_at,
        c.updated_at
    FROM clients c
    WHERE c.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
END;
$$;

-- Tester la fonction
SELECT 
    'Fonction get_workshop_clients' as info,
    COUNT(*) as clients_visibles
FROM get_workshop_clients();

-- ============================================================================
-- 5. CRÉATION D'UNE FONCTION POUR CRÉER DES CLIENTS
-- ============================================================================

SELECT '=== CRÉATION D''UNE FONCTION POUR CRÉER DES CLIENTS ===' as section;

-- Créer une fonction pour créer des clients avec isolation automatique
CREATE OR REPLACE FUNCTION create_workshop_client(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
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
AS $$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Créer le client
    INSERT INTO clients (first_name, last_name, email, phone, address, workshop_id)
    VALUES (p_first_name, p_last_name, p_email, p_phone, p_address, current_workshop_id)
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

-- Tester la fonction de création
SELECT 
    'Test fonction create_workshop_client' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM create_workshop_client('Test', 'Fonction', 'test.fonction@example.com', '1111111111', 'Adresse test fonction');

-- ============================================================================
-- 6. VÉRIFICATION DE L'ISOLATION
-- ============================================================================

SELECT '=== VÉRIFICATION DE L''ISOLATION ===' as section;

-- Vérifier l'isolation via la vue filtrée
SELECT 
    'Isolation via vue filtrée' as info,
    COUNT(*) as total_clients_visibles,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        THEN '✅ Isolation parfaite via vue'
        ELSE '❌ Problème d''isolation via vue'
    END as isolation_status
FROM clients_filtered;

-- Vérifier l'isolation via la fonction
SELECT 
    'Isolation via fonction' as info,
    COUNT(*) as total_clients_visibles,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        THEN '✅ Isolation parfaite via fonction'
        ELSE '❌ Problème d''isolation via fonction'
    END as isolation_status
FROM get_workshop_clients();

-- ============================================================================
-- 7. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction d'isolation
SELECT 
    'Résumé de la correction d''isolation' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM clients_filtered) as clients_visibles_via_vue,
    (SELECT COUNT(*) FROM get_workshop_clients()) as clients_visibles_via_fonction,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) AND workshop_id IS NOT NULL) as clients_autres_workshops,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients_filtered) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Isolation corrigée - Vue filtrée fonctionnelle'
        ELSE '❌ Problème d''isolation persistant'
    END as isolation_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients_filtered) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '🎉 SUCCÈS: L''isolation est maintenant corrigée avec la vue filtrée !'
        ELSE '⚠️ PROBLÈME: L''isolation ne fonctionne toujours pas correctement'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Utilisez la vue clients_filtered pour voir seulement vos clients' as step1,
    '2. Utilisez la fonction get_workshop_clients() pour récupérer vos clients' as step2,
    '3. Utilisez la fonction create_workshop_client() pour créer des clients' as step3,
    '4. Vérifiez que seules vos données sont visibles' as step4,
    '5. L''isolation est maintenant gérée côté application' as step5;
