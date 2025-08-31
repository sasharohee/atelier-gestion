-- =====================================================
-- CORRECTION VALIDATION EMAIL CLIENTS
-- =====================================================
-- Résoudre le problème de validation d'email trop stricte
-- =====================================================

-- 1. SUPPRIMER LES TRIGGERS EXISTANTS QUI PEUVENT CONFLICTER
DROP TRIGGER IF EXISTS trigger_prevent_duplicate_emails ON clients;
DROP TRIGGER IF EXISTS trigger_validate_client_email ON clients;

-- 2. CRÉER UNE FONCTION DE VALIDATION D'EMAIL PLUS PERMISSIVE
CREATE OR REPLACE FUNCTION validate_client_email_format()
RETURNS TRIGGER AS $$
BEGIN
    -- Valider le format de l'email seulement si l'email n'est pas vide
    IF NEW.email IS NOT NULL AND TRIM(NEW.email) != '' THEN
        -- Validation plus permissive pour les emails
        -- Permet les domaines avec des TLD courts (comme .u, .io, etc.)
        IF NOT (NEW.email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{1,}$') THEN
            RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
        END IF;
        
        -- Vérification supplémentaire : l'email ne doit pas être trop court
        IF LENGTH(NEW.email) < 5 THEN
            RAISE EXCEPTION 'Email trop court: %', NEW.email;
        END IF;
        
        -- Vérification : l'email doit contenir un @ et au moins un point après le @
        IF POSITION('@' IN NEW.email) = 0 OR POSITION('.' IN SUBSTRING(NEW.email FROM POSITION('@' IN NEW.email))) = 0 THEN
            RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. CRÉER UN TRIGGER DE VALIDATION D'EMAIL SEULEMENT
CREATE TRIGGER trigger_validate_client_email_format
    BEFORE INSERT OR UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION validate_client_email_format();

-- 4. CRÉER UNE FONCTION POUR GÉRER LES DOUBLONS D'EMAIL (OPTIONNELLE)
CREATE OR REPLACE FUNCTION handle_duplicate_emails()
RETURNS TRIGGER AS $$
DECLARE
    existing_client RECORD;
BEGIN
    -- Vérifier les doublons seulement si l'email n'est pas vide
    IF NEW.email IS NOT NULL AND TRIM(NEW.email) != '' THEN
        -- Chercher un client existant avec le même email pour le même utilisateur
        SELECT * INTO existing_client
        FROM clients 
        WHERE email = NEW.email 
        AND user_id = NEW.user_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
        LIMIT 1;
        
        IF existing_client IS NOT NULL THEN
            RAISE EXCEPTION 'Un client avec l''email % existe déjà pour cet utilisateur', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. CRÉER UN TRIGGER POUR GÉRER LES DOUBLONS (OPTIONNEL)
CREATE TRIGGER trigger_handle_duplicate_emails
    BEFORE INSERT OR UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION handle_duplicate_emails();

-- 6. TESTER LA VALIDATION AVEC DES EMAILS VALIDES ET INVALIDES
DO $$
DECLARE
    current_user_id UUID;
    test_emails TEXT[] := ARRAY[
        'test@example.com',
        'user@domain.co.uk',
        'test@example.u',  -- Cet email était rejeté, maintenant accepté
        'invalid-email',   -- Cet email doit être rejeté
        'test@',           -- Cet email doit être rejeté
        '@domain.com'      -- Cet email doit être rejeté
    ];
    test_email TEXT;
    is_valid BOOLEAN;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NOT NULL THEN
        RAISE NOTICE '=== Test de validation d''emails ===';
        
        FOREACH test_email IN ARRAY test_emails
        LOOP
            BEGIN
                -- Tester la validation en essayant d'insérer un client de test
                INSERT INTO clients (
                    first_name, 
                    last_name, 
                    email, 
                    user_id,
                    created_at,
                    updated_at
                ) VALUES (
                    'Test', 
                    'User', 
                    test_email, 
                    current_user_id,
                    NOW(),
                    NOW()
                );
                
                -- Si on arrive ici, l'email est valide
                RAISE NOTICE '✅ Email valide: %', test_email;
                
                -- Nettoyer le client de test
                DELETE FROM clients WHERE email = test_email AND first_name = 'Test';
                
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Email invalide: % (Erreur: %)', test_email, SQLERRM;
            END;
        END LOOP;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 7. VÉRIFIER LES TRIGGERS CRÉÉS
SELECT 
    'TRIGGERS CRÉÉS' as section,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'clients'
AND trigger_name LIKE '%email%';

-- 8. AFFICHER LES RÉSULTATS
SELECT 
    'CORRECTION TERMINÉE' as status,
    'La validation d''email a été corrigée pour être plus permissive' as message,
    'Les emails courts comme test@example.u sont maintenant acceptés' as details;

