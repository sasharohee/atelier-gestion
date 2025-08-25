-- Trigger pour ajouter automatiquement les nouveaux utilisateurs
-- Date: 2024-01-24
-- Objectif: Ajouter automatiquement les nouveaux utilisateurs à subscription_status

-- 1. CRÉER LA FONCTION POUR LE TRIGGER
CREATE OR REPLACE FUNCTION add_user_to_subscription_status()
RETURNS TRIGGER AS $$
DECLARE
    is_admin BOOLEAN := FALSE;
    first_name TEXT := 'Utilisateur';
    last_name TEXT := '';
BEGIN
    -- Vérifier si c'est un admin
    IF NEW.email = 'srohee32@gmail.com' THEN
        is_admin := TRUE;
        first_name := 'Admin';
        last_name := 'User';
    END IF;
    
    -- Extraire les noms depuis les métadonnées si disponibles
    IF NEW.raw_user_meta_data IS NOT NULL THEN
        IF NEW.raw_user_meta_data->>'firstName' IS NOT NULL THEN
            first_name := NEW.raw_user_meta_data->>'firstName';
        END IF;
        IF NEW.raw_user_meta_data->>'lastName' IS NOT NULL THEN
            last_name := NEW.raw_user_meta_data->>'lastName';
        END IF;
    END IF;
    
    -- Insérer l'utilisateur dans subscription_status
    INSERT INTO subscription_status (
        user_id,
        first_name,
        last_name,
        email,
        is_active,
        subscription_type,
        notes,
        activated_at
    ) VALUES (
        NEW.id,
        first_name,
        last_name,
        NEW.email,
        is_admin, -- Admin = actif, autres = inactif
        CASE WHEN is_admin THEN 'premium' ELSE 'free' END,
        CASE 
            WHEN is_admin THEN 'Administrateur - accès complet'
            ELSE 'Compte créé automatiquement - en attente d''activation par l''administrateur'
        END,
        CASE WHEN is_admin THEN NEW.created_at ELSE NULL END
    );
    
    RAISE NOTICE '✅ Nouvel utilisateur ajouté à subscription_status: % (%) - Admin: %', NEW.email, first_name, is_admin;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CRÉER LE TRIGGER
DROP TRIGGER IF EXISTS trigger_add_user_to_subscription_status ON auth.users;

CREATE TRIGGER trigger_add_user_to_subscription_status
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION add_user_to_subscription_status();

-- 3. VÉRIFIER QUE LE TRIGGER EST CRÉÉ
SELECT 
    '=== TRIGGER CRÉÉ ===' as section,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_add_user_to_subscription_status';

-- 4. TESTER LE TRIGGER (optionnel - pour vérifier qu'il fonctionne)
-- Note: Ce test ne sera exécuté que si vous voulez tester le trigger
/*
DO $$
BEGIN
    RAISE NOTICE '🧪 Test du trigger (simulation)...';
    -- Le trigger sera automatiquement appelé lors de la création d'un nouvel utilisateur
    RAISE NOTICE '✅ Trigger configuré et prêt à fonctionner';
END $$;
*/

-- 5. AFFICHER LE RÉSUMÉ
SELECT 
    '🎉 TRIGGER CONFIGURÉ' as result,
    '✅ Fonction add_user_to_subscription_status créée' as check1,
    '✅ Trigger trigger_add_user_to_subscription_status créé' as check2,
    '✅ Nouveaux utilisateurs ajoutés automatiquement' as check3,
    '✅ Prêt pour les nouvelles inscriptions' as check4;
