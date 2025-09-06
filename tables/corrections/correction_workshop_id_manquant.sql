-- =====================================================
-- CORRECTION WORKSHOP_ID MANQUANT
-- =====================================================

-- ATTENTION : Ce script corrige les utilisateurs sans workshop_id
-- Exécuter avec précaution !

SELECT 'CORRECTION WORKSHOP_ID MANQUANT' as section;

-- 1. IDENTIFIER LES UTILISATEURS SANS WORKSHOP_ID
-- =====================================================

SELECT 
    'UTILISATEURS SANS WORKSHOP_ID' as probleme,
    COUNT(*) as nombre,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NULL;

-- 2. CRÉER UN WORKSHOP_ID PAR DÉFAUT SI NÉCESSAIRE
-- =====================================================

-- Vérifier s'il existe déjà des workshop_id
DO $$
DECLARE
    existing_workshop_id uuid;
    new_workshop_id uuid;
BEGIN
    -- Récupérer un workshop_id existant ou en créer un nouveau
    SELECT workshop_id INTO existing_workshop_id 
    FROM subscription_status 
    WHERE workshop_id IS NOT NULL 
    LIMIT 1;
    
    IF existing_workshop_id IS NULL THEN
        -- Aucun workshop_id existant, en créer un nouveau
        new_workshop_id := gen_random_uuid();
        RAISE NOTICE 'Création d''un nouveau workshop_id: %', new_workshop_id;
    ELSE
        -- Utiliser le workshop_id existant
        new_workshop_id := existing_workshop_id;
        RAISE NOTICE 'Utilisation du workshop_id existant: %', new_workshop_id;
    END IF;
    
    -- Mettre à jour tous les utilisateurs sans workshop_id
    UPDATE subscription_status 
    SET workshop_id = new_workshop_id
    WHERE workshop_id IS NULL;
    
    RAISE NOTICE 'Utilisateurs mis à jour avec le workshop_id: %', new_workshop_id;
END $$;

-- 3. VÉRIFIER LA CORRECTION
-- =====================================================

SELECT 
    'VÉRIFICATION APRÈS CORRECTION' as verification,
    COUNT(*) as total_utilisateurs,
    COUNT(workshop_id) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM subscription_status;

-- 4. AFFICHER LES UTILISATEURS CORRIGÉS
-- =====================================================

SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    workshop_id,
    status,
    created_at
FROM subscription_status 
ORDER BY created_at DESC;

-- 5. VÉRIFIER LES WORKSHOP_ID DISTINCTS
-- =====================================================

SELECT 
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
GROUP BY workshop_id
ORDER BY nombre_utilisateurs DESC;

-- 6. CORRIGER LA FONCTION D'ISOLATION POUR GÉRER LES CAS D'ERREUR
-- =====================================================

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS set_order_isolation();

-- Créer la nouvelle fonction avec gestion d'erreur
CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    user_workshop_id uuid;
    user_id uuid;
BEGIN
    -- Récupérer le workshop_id de l'utilisateur connecté
    user_workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
    user_id := auth.uid();
    
    -- Vérifier si l'utilisateur a un workshop_id
    IF user_workshop_id IS NULL THEN
        -- Essayer de récupérer le workshop_id depuis la table subscription_status
        SELECT workshop_id INTO user_workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid();
        
        -- Si toujours NULL, lever une erreur
        IF user_workshop_id IS NULL THEN
            RAISE EXCEPTION 'Utilisateur sans workshop_id. Veuillez contacter l''administrateur.';
        END IF;
    END IF;
    
    -- Vérifier si l'utilisateur existe
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié.';
    END IF;
    
    -- Assigner les valeurs
    NEW.workshop_id := user_workshop_id;
    NEW.created_by := user_id;
    
    -- Si created_at n'est pas défini, le définir
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- Toujours mettre à jour updated_at
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. VÉRIFIER LA NOUVELLE FONCTION
-- =====================================================

SELECT 
    'FONCTION CORRIGÉE' as verification,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 8. TESTER LA CRÉATION D'UNE COMMANDE (SIMULATION)
-- =====================================================

-- Note : Cette partie ne peut être testée que par un utilisateur connecté
-- via l'application frontend

SELECT 
    'TEST PRÊT' as test,
    'Fonction corrigée et prête pour les tests' as description,
    'Créer une commande via l''interface pour tester' as instruction;

-- 9. RÉSULTAT
-- =====================================================

SELECT 
    'CORRECTION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Workshop_id manquant corrigé' as description;
