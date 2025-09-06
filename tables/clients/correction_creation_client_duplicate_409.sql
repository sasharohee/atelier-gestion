-- Correction de l'erreur 409 lors de la création de clients
-- Problème: Le trigger prevent_duplicate_emails empêche la création de clients avec des emails existants
-- Solution: Modifier le trigger pour permettre la création de clients même s'ils existent déjà

-- ============================================================================
-- 1. ANALYSE DU PROBLÈME
-- ============================================================================

-- Vérifier si le trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_prevent_duplicate_emails'
AND event_object_table = 'clients';

-- ============================================================================
-- 2. SOLUTION 1: SUPPRIMER LE TRIGGER RESTRICTIF
-- ============================================================================

-- Supprimer le trigger qui empêche les doublons
DROP TRIGGER IF EXISTS trigger_prevent_duplicate_emails ON clients;
DROP FUNCTION IF EXISTS prevent_duplicate_emails();

-- ============================================================================
-- 3. SOLUTION 2: CRÉER UN TRIGGER PLUS PERMISSIF
-- ============================================================================

-- Créer une fonction de validation plus permissive
CREATE OR REPLACE FUNCTION validate_client_email()
RETURNS TRIGGER AS $$
BEGIN
    -- Valider le format de l'email seulement
    IF NEW.email IS NOT NULL AND NEW.email != '' THEN
        IF NOT (NEW.email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer un trigger de validation d'email seulement (sans restriction de doublon)
CREATE TRIGGER trigger_validate_client_email
    BEFORE INSERT OR UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION validate_client_email();

-- ============================================================================
-- 4. SOLUTION 3: FONCTION POUR CRÉER UN CLIENT AVEC GESTION DE DOUBLON
-- ============================================================================

-- Créer une fonction RPC pour créer un client avec gestion intelligente des doublons
CREATE OR REPLACE FUNCTION create_client_smart(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_client_id UUID;
    v_existing_client RECORD;
    v_result JSON;
BEGIN
    -- Utiliser l'utilisateur connecté si aucun user_id fourni
    IF p_user_id IS NULL THEN
        p_user_id := auth.uid();
    END IF;
    
    -- Si un email est fourni, vérifier s'il existe déjà
    IF p_email IS NOT NULL AND p_email != '' THEN
        SELECT * INTO v_existing_client
        FROM clients 
        WHERE email = p_email 
        AND user_id = p_user_id
        LIMIT 1;
        
        IF v_existing_client IS NOT NULL THEN
            -- Client existant trouvé, retourner les informations
            RETURN json_build_object(
                'success', true,
                'action', 'existing_client_found',
                'message', 'Un client avec cet email existe déjà',
                'client_id', v_existing_client.id,
                'client_data', json_build_object(
                    'id', v_existing_client.id,
                    'firstName', v_existing_client.first_name,
                    'lastName', v_existing_client.last_name,
                    'email', v_existing_client.email,
                    'phone', v_existing_client.phone,
                    'address', v_existing_client.address,
                    'notes', v_existing_client.notes,
                    'createdAt', v_existing_client.created_at,
                    'updatedAt', v_existing_client.updated_at
                )
            );
        END IF;
    END IF;
    
    -- Créer le nouveau client
    INSERT INTO clients (
        first_name,
        last_name,
        email,
        phone,
        address,
        notes,
        user_id,
        created_at,
        updated_at
    ) VALUES (
        p_first_name,
        p_last_name,
        p_email,
        p_phone,
        p_address,
        p_notes,
        p_user_id,
        NOW(),
        NOW()
    ) RETURNING id INTO v_client_id;
    
    -- Retourner le succès
    RETURN json_build_object(
        'success', true,
        'action', 'client_created',
        'message', 'Client créé avec succès',
        'client_id', v_client_id
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_client_smart(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;

-- ============================================================================
-- 5. SOLUTION 4: FONCTION POUR CRÉER UN CLIENT FORCÉ (IGNORE LES DOUBLONS)
-- ============================================================================

-- Créer une fonction pour forcer la création d'un client (même s'il existe déjà)
CREATE OR REPLACE FUNCTION create_client_force(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_client_id UUID;
    v_unique_email TEXT;
    v_counter INTEGER := 1;
BEGIN
    -- Utiliser l'utilisateur connecté si aucun user_id fourni
    IF p_user_id IS NULL THEN
        p_user_id := auth.uid();
    END IF;
    
    -- Si un email est fourni et qu'il existe déjà, générer un email unique
    IF p_email IS NOT NULL AND p_email != '' THEN
        v_unique_email := p_email;
        
        -- Chercher un email unique en ajoutant un numéro
        WHILE EXISTS (
            SELECT 1 FROM clients 
            WHERE email = v_unique_email 
            AND user_id = p_user_id
        ) LOOP
            v_unique_email := SPLIT_PART(p_email, '@', 1) || v_counter || '@' || SPLIT_PART(p_email, '@', 2);
            v_counter := v_counter + 1;
        END LOOP;
    END IF;
    
    -- Créer le client avec l'email unique
    INSERT INTO clients (
        first_name,
        last_name,
        email,
        phone,
        address,
        notes,
        user_id,
        created_at,
        updated_at
    ) VALUES (
        p_first_name,
        p_last_name,
        v_unique_email,
        p_phone,
        p_address,
        p_notes,
        p_user_id,
        NOW(),
        NOW()
    ) RETURNING id INTO v_client_id;
    
    -- Retourner le succès
    RETURN json_build_object(
        'success', true,
        'action', 'client_created_force',
        'message', 'Client créé avec succès (email modifié si nécessaire)',
        'client_id', v_client_id,
        'email_used', v_unique_email,
        'email_modified', CASE WHEN v_unique_email != p_email THEN true ELSE false END
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_client_force(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;

-- ============================================================================
-- 6. VÉRIFICATION DE LA CORRECTION
-- ============================================================================

-- Vérifier que le trigger restrictif a été supprimé
SELECT 
    'Trigger restrictif supprimé' as status,
    COUNT(*) as remaining_triggers
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_prevent_duplicate_emails'
AND event_object_table = 'clients';

-- Vérifier que le nouveau trigger de validation existe
SELECT 
    'Nouveau trigger de validation' as status,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_validate_client_email'
AND event_object_table = 'clients';

-- Vérifier que les nouvelles fonctions existent
SELECT 
    'Fonctions créées' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('create_client_smart', 'create_client_force')
AND routine_schema = 'public';

-- ============================================================================
-- 7. TEST DE LA CORRECTION
-- ============================================================================

-- Test 1: Créer un client avec un email unique
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '=== Test 1: Création client avec email unique ===';
    
    test_result := create_client_smart(
        'Test', 'Client', 'test.unique@example.com', 
        '0123456789', 'Adresse test', 'Note test'
    );
    
    RAISE NOTICE 'Résultat: %', test_result;
END $$;

-- Test 2: Créer un client avec un email existant (doit retourner le client existant)
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '=== Test 2: Création client avec email existant ===';
    
    test_result := create_client_smart(
        'Test2', 'Client2', 'test.unique@example.com', 
        '0123456789', 'Adresse test2', 'Note test2'
    );
    
    RAISE NOTICE 'Résultat: %', test_result;
END $$;

-- Test 3: Forcer la création d'un client avec un email existant
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '=== Test 3: Création forcée avec email existant ===';
    
    test_result := create_client_force(
        'Test3', 'Client3', 'test.unique@example.com', 
        '0123456789', 'Adresse test3', 'Note test3'
    );
    
    RAISE NOTICE 'Résultat: %', test_result;
END $$;

-- ============================================================================
-- 8. NETTOYAGE DES TESTS
-- ============================================================================

-- Supprimer les clients de test
DELETE FROM clients WHERE email LIKE 'test.%@example.com';

-- ============================================================================
-- 9. MESSAGE DE CONFIRMATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== CORRECTION ERREUR 409 TERMINÉE ===';
    RAISE NOTICE '✅ Trigger restrictif supprimé';
    RAISE NOTICE '✅ Nouveau trigger de validation créé';
    RAISE NOTICE '✅ Fonction create_client_smart créée (gestion intelligente)';
    RAISE NOTICE '✅ Fonction create_client_force créée (création forcée)';
    RAISE NOTICE '';
    RAISE NOTICE 'Options disponibles :';
    RAISE NOTICE '1. Utiliser create_client_smart() pour une gestion intelligente';
    RAISE NOTICE '2. Utiliser create_client_force() pour forcer la création';
    RAISE NOTICE '3. Créer directement via INSERT (plus d''erreur 409)';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ Les clients peuvent maintenant être créés même avec des emails existants';
END $$;
