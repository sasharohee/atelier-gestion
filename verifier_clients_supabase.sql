-- VÉRIFICATION DES CLIENTS DANS SUPABASE
-- Exécutez ce script pour voir tous les clients et leurs user_id

-- ========================================
-- ÉTAPE 1: VÉRIFIER TOUS LES CLIENTS
-- ========================================
SELECT 
    'TOUS LES CLIENTS' as section,
    COUNT(*) as total_clients
FROM clients;

-- ========================================
-- ÉTAPE 2: CLIENTS PAR USER_ID
-- ========================================
SELECT 
    'CLIENTS PAR USER_ID' as section,
    user_id,
    COUNT(*) as nombre_clients,
    CASE 
        WHEN user_id IS NULL THEN 'Sans utilisateur'
        WHEN user_id = '00000000-0000-0000-0000-000000000000'::uuid THEN 'Système'
        ELSE 'Utilisateur spécifique'
    END as type_utilisateur
FROM clients 
GROUP BY user_id
ORDER BY nombre_clients DESC;

-- ========================================
-- ÉTAPE 3: DÉTAILS DES CLIENTS RÉCENTS
-- ========================================
SELECT 
    'DÉTAILS DES CLIENTS RÉCENTS' as section,
    id,
    first_name,
    last_name,
    email,
    user_id,
    created_at,
    CASE 
        WHEN user_id IS NULL THEN 'Sans utilisateur'
        WHEN user_id = '00000000-0000-0000-0000-000000000000'::uuid THEN 'Système'
        ELSE 'Utilisateur: ' || user_id::text
    END as type_utilisateur
FROM clients 
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- ÉTAPE 4: CLIENTS AVEC LES NOUVEAUX CHAMPS
-- ========================================
SELECT 
    'CLIENTS AVEC NOUVEAUX CHAMPS' as section,
    id,
    first_name,
    last_name,
    email,
    accounting_code,
    cni_identifier,
    region,
    city,
    company_name,
    user_id
FROM clients 
WHERE 
    accounting_code IS NOT NULL AND accounting_code != '' OR
    cni_identifier IS NOT NULL AND cni_identifier != '' OR
    region IS NOT NULL AND region != '' OR
    city IS NOT NULL AND city != '' OR
    company_name IS NOT NULL AND company_name != ''
ORDER BY created_at DESC;

-- ========================================
-- ÉTAPE 5: TEST D'ACCÈS RLS
-- ========================================
-- Simuler l'accès d'un utilisateur connecté
DO $$
DECLARE
    test_user_id UUID := 'e454cc8c-3e40-4f72-bf26-4f6f43e78d0b'; -- Remplacez par votre user_id
    accessible_clients_count INTEGER;
BEGIN
    -- Compter les clients accessibles pour cet utilisateur
    SELECT COUNT(*) INTO accessible_clients_count
    FROM clients 
    WHERE 
        user_id = test_user_id OR
        user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
        user_id IS NULL;
    
    RAISE NOTICE '🔍 Test d''accès RLS pour utilisateur %: % clients accessibles', test_user_id, accessible_clients_count;
    
    -- Lister les clients accessibles
    RAISE NOTICE '📋 Clients accessibles:';
    FOR client_record IN 
        SELECT id, first_name, last_name, email, user_id
        FROM clients 
        WHERE 
            user_id = test_user_id OR
            user_id = '00000000-0000-0000-0000-000000000000'::uuid OR
            user_id IS NULL
        ORDER BY created_at DESC
    LOOP
        RAISE NOTICE '  - % % (%): user_id = %', 
            client_record.first_name, 
            client_record.last_name, 
            client_record.email,
            client_record.user_id;
    END LOOP;
END $$;
