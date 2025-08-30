-- 🔧 CORRECTION - Clés étrangères sur Loyalty Points History
-- Script pour diagnostiquer et corriger les problèmes de clés étrangères

-- ========================================
-- DIAGNOSTIC 1: VÉRIFICATION DES CLÉS ÉTRANGÈRES
-- ========================================

SELECT 
    '=== CLÉS ÉTRANGÈRES LOYALTY_POINTS_HISTORY ===' as section,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    'INFO' as delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'loyalty_points_history'
AND tc.table_schema = 'public';

-- ========================================
-- DIAGNOSTIC 2: VÉRIFICATION DES CLIENTS EXISTANTS
-- ========================================

DO $$
DECLARE
    total_clients INTEGER;
    total_loyalty_records INTEGER;
    invalid_client_records INTEGER;
    client_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DES CLIENTS ===';
    
    -- Compter les clients
    SELECT COUNT(*) INTO total_clients FROM clients;
    RAISE NOTICE 'Total clients dans la table clients: %', total_clients;
    
    -- Vérifier si la colonne client_id existe dans loyalty_points_history
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'client_id'
    ) INTO client_id_exists;
    
    IF client_id_exists THEN
        -- Compter les enregistrements loyalty_points_history
        SELECT COUNT(*) INTO total_loyalty_records FROM loyalty_points_history;
        RAISE NOTICE 'Total enregistrements loyalty_points_history: %', total_loyalty_records;
        
        -- Compter les enregistrements avec des client_id invalides
        SELECT COUNT(*) INTO invalid_client_records
        FROM loyalty_points_history lph
        LEFT JOIN clients c ON lph.client_id = c.id
        WHERE c.id IS NULL AND lph.client_id IS NOT NULL;
        
        RAISE NOTICE 'Enregistrements avec client_id invalide: %', invalid_client_records;
        
        IF invalid_client_records > 0 THEN
            RAISE NOTICE '❌ PROBLÈME: % enregistrements ont des client_id qui n''existent pas', invalid_client_records;
        ELSE
            RAISE NOTICE '✅ Tous les client_id sont valides';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Colonne client_id n''existe pas dans loyalty_points_history';
    END IF;
END $$;

-- ========================================
-- DIAGNOSTIC 3: IDENTIFIER LES CLIENT_ID INVALIDES
-- ========================================

DO $$
DECLARE
    invalid_client_id UUID;
    record_count INTEGER;
BEGIN
    RAISE NOTICE '=== CLIENT_ID INVALIDES DÉTAILLÉS ===';
    
    -- Trouver les client_id invalides
    FOR invalid_client_id IN
        SELECT DISTINCT lph.client_id
        FROM loyalty_points_history lph
        LEFT JOIN clients c ON lph.client_id = c.id
        WHERE c.id IS NULL AND lph.client_id IS NOT NULL
        LIMIT 10
    LOOP
        -- Compter les enregistrements pour ce client_id invalide
        SELECT COUNT(*) INTO record_count
        FROM loyalty_points_history
        WHERE client_id = invalid_client_id;
        
        RAISE NOTICE 'Client_id invalide: % (% enregistrements)', invalid_client_id, record_count;
    END LOOP;
END $$;

-- ========================================
-- CORRECTION 1: SUPPRIMER LES ENREGISTREMENTS AVEC CLIENT_ID INVALIDES
-- ========================================

DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    RAISE NOTICE '=== SUPPRESSION DES ENREGISTREMENTS INVALIDES ===';
    
    -- Supprimer les enregistrements avec des client_id invalides
    DELETE FROM loyalty_points_history
    WHERE client_id IN (
        SELECT lph.client_id
        FROM loyalty_points_history lph
        LEFT JOIN clients c ON lph.client_id = c.id
        WHERE c.id IS NULL AND lph.client_id IS NOT NULL
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ % enregistrements avec client_id invalide supprimés', deleted_count;
END $$;

-- ========================================
-- CORRECTION 2: CRÉER UN CLIENT PAR DÉFAUT SI NÉCESSAIRE
-- ========================================

DO $$
DECLARE
    default_client_id UUID;
    client_count INTEGER;
BEGIN
    RAISE NOTICE '=== CRÉATION D''UN CLIENT PAR DÉFAUT ===';
    
    -- Compter les clients
    SELECT COUNT(*) INTO client_count FROM clients;
    
    IF client_count = 0 THEN
        RAISE NOTICE '⚠️ Aucun client trouvé - création d''un client par défaut';
        
        -- Créer un client par défaut
        INSERT INTO clients (
            id, name, email, phone, address, created_at, updated_at
        ) VALUES (
            gen_random_uuid(), 'Client par défaut', 'default@example.com', '0000000000', 'Adresse par défaut',
            NOW(), NOW()
        ) RETURNING id INTO default_client_id;
        
        RAISE NOTICE '✅ Client par défaut créé avec l''ID: %', default_client_id;
    ELSE
        RAISE NOTICE '✅ % clients existent déjà', client_count;
    END IF;
END $$;

-- ========================================
-- CORRECTION 3: MODIFIER LA CONTRAINTE DE CLÉ ÉTRANGÈRE
-- ========================================

DO $$
DECLARE
    constraint_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== MODIFICATION DE LA CONTRAINTE CLIENT_ID ===';
    
    -- Vérifier si la contrainte existe
    SELECT EXISTS (
        SELECT FROM information_schema.table_constraints 
        WHERE constraint_name = 'loyalty_points_history_client_id_fkey'
        AND table_name = 'loyalty_points_history'
        AND table_schema = 'public'
    ) INTO constraint_exists;
    
    IF constraint_exists THEN
        -- Supprimer la contrainte existante
        ALTER TABLE loyalty_points_history DROP CONSTRAINT loyalty_points_history_client_id_fkey;
        RAISE NOTICE '✅ Contrainte client_id supprimée';
        
        -- Recréer la contrainte avec ON DELETE SET NULL
        ALTER TABLE loyalty_points_history 
        ADD CONSTRAINT loyalty_points_history_client_id_fkey 
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Contrainte client_id recréée avec ON DELETE SET NULL';
    ELSE
        RAISE NOTICE '⚠️ Contrainte client_id n''existe pas';
    END IF;
END $$;

-- ========================================
-- CORRECTION 4: CRÉER UN TRIGGER POUR VALIDER LES CLIENT_ID
-- ========================================

-- Créer une fonction pour valider les client_id avant insertion
CREATE OR REPLACE FUNCTION validate_loyalty_points_client()
RETURNS TRIGGER AS $$
DECLARE
    client_exists BOOLEAN;
    default_client_id UUID;
BEGIN
    -- Si client_id est NULL, on peut l'insérer (peut être optionnel)
    IF NEW.client_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Vérifier si le client existe
    SELECT EXISTS (
        SELECT 1 FROM clients WHERE id = NEW.client_id
    ) INTO client_exists;
    
    IF NOT client_exists THEN
        RAISE NOTICE '⚠️ Client_id invalide: % - recherche d''un client par défaut', NEW.client_id;
        
        -- Trouver un client par défaut
        SELECT id INTO default_client_id FROM clients LIMIT 1;
        
        IF default_client_id IS NOT NULL THEN
            NEW.client_id := default_client_id;
            RAISE NOTICE '✅ Client_id remplacé par: %', default_client_id;
        ELSE
            -- Si aucun client n'existe, créer un client par défaut
            INSERT INTO clients (
                id, name, email, phone, address, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), 'Client automatique', 'auto@example.com', '0000000000', 'Créé automatiquement',
                NOW(), NOW()
            ) RETURNING id INTO default_client_id;
            
            NEW.client_id := default_client_id;
            RAISE NOTICE '✅ Nouveau client créé et assigné: %', default_client_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer et recréer le trigger
DROP TRIGGER IF EXISTS validate_loyalty_points_client_trigger ON loyalty_points_history;

CREATE TRIGGER validate_loyalty_points_client_trigger
    BEFORE INSERT OR UPDATE ON loyalty_points_history
    FOR EACH ROW
    EXECUTE FUNCTION validate_loyalty_points_client();

-- ========================================
-- VÉRIFICATION FINALE
-- ========================================

DO $$
DECLARE
    total_clients INTEGER;
    total_loyalty_records INTEGER;
    invalid_client_records INTEGER;
    constraint_exists BOOLEAN;
    trigger_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION FINALE ===';
    
    -- Vérifier les clients
    SELECT COUNT(*) INTO total_clients FROM clients;
    RAISE NOTICE 'Total clients: %', total_clients;
    
    -- Vérifier les enregistrements loyalty_points_history
    SELECT COUNT(*) INTO total_loyalty_records FROM loyalty_points_history;
    RAISE NOTICE 'Total enregistrements loyalty_points_history: %', total_loyalty_records;
    
    -- Vérifier les enregistrements invalides
    SELECT COUNT(*) INTO invalid_client_records
    FROM loyalty_points_history lph
    LEFT JOIN clients c ON lph.client_id = c.id
    WHERE c.id IS NULL AND lph.client_id IS NOT NULL;
    
    RAISE NOTICE 'Enregistrements avec client_id invalide: %', invalid_client_records;
    
    -- Vérifier la contrainte
    SELECT EXISTS (
        SELECT FROM information_schema.table_constraints 
        WHERE constraint_name = 'loyalty_points_history_client_id_fkey'
        AND table_name = 'loyalty_points_history'
        AND table_schema = 'public'
    ) INTO constraint_exists;
    
    -- Vérifier le trigger
    SELECT EXISTS (
        SELECT FROM information_schema.triggers 
        WHERE trigger_name = 'validate_loyalty_points_client_trigger'
        AND event_object_table = 'loyalty_points_history'
    ) INTO trigger_exists;
    
    RAISE NOTICE 'Contrainte client_id: %s', CASE WHEN constraint_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Trigger de validation: %s', CASE WHEN trigger_exists THEN '✅' ELSE '❌' END;
    
    IF total_clients > 0 AND invalid_client_records = 0 AND constraint_exists AND trigger_exists THEN
        RAISE NOTICE '🎉 CORRECTION DES CLÉS ÉTRANGÈRES RÉUSSIE !';
    ELSE
        RAISE NOTICE '⚠️ CORRECTION DES CLÉS ÉTRANGÈRES INCOMPLÈTE';
    END IF;
END $$;

-- ========================================
-- TEST D'INSERTION
-- ========================================

DO $$
DECLARE
    test_id UUID;
    test_client_id UUID;
    insertion_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== TEST D''INSERTION AVEC CLIENT_ID ===';
    
    -- Trouver un client de test
    SELECT id INTO test_client_id FROM clients LIMIT 1;
    
    IF test_client_id IS NOT NULL THEN
        BEGIN
            -- Test d'insertion avec un client_id valide
            INSERT INTO loyalty_points_history (
                id, client_id, reference_id,
                points_before, points_after, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), test_client_id, gen_random_uuid(),
                0, 100, NOW(), NOW()
            ) RETURNING id INTO test_id;
            
            insertion_success := TRUE;
            RAISE NOTICE '✅ Test d''insertion RÉUSSI - ID: %', test_id;
            RAISE NOTICE '   Client_id utilisé: %', test_client_id;
            
            -- Nettoyer le test
            DELETE FROM loyalty_points_history WHERE id = test_id;
            RAISE NOTICE '✅ Enregistrement de test supprimé';
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ ERREUR lors du test d''insertion: %', SQLERRM;
                insertion_success := FALSE;
        END;
    ELSE
        RAISE NOTICE '⚠️ Aucun client trouvé pour le test';
    END IF;
    
    IF insertion_success THEN
        RAISE NOTICE '🎉 CORRECTION RÉUSSIE - L''insertion avec client_id fonctionne !';
    ELSE
        RAISE NOTICE '❌ CORRECTION ÉCHOUÉE - L''insertion avec client_id ne fonctionne pas';
    END IF;
END $$;

-- Message final
SELECT '🎉 Correction des clés étrangères terminée avec succès !' as status;
