-- =====================================================
-- CORRECTION AMBIGUÏTÉ USER_ID (CORRIGÉ)
-- =====================================================

SELECT 'CORRECTION AMBIGUÏTÉ USER_ID CORRIGÉE' as section;

-- 1. SUPPRIMER LE TRIGGER D'ABORD
-- =====================================================

DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;

-- 2. SUPPRIMER L'ANCIENNE FONCTION
-- =====================================================

DROP FUNCTION IF EXISTS set_order_isolation();

-- 3. CRÉER LA NOUVELLE FONCTION SANS AMBIGUÏTÉ
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id uuid;
    current_workshop_id uuid;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    current_user_id := auth.uid();
    
    -- Vérifier si l'utilisateur est authentifié
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié.';
    END IF;
    
    -- Essayer de récupérer le workshop_id depuis le JWT
    current_workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
    
    -- Si pas dans le JWT, récupérer depuis subscription_status
    IF current_workshop_id IS NULL THEN
        SELECT workshop_id INTO current_workshop_id
        FROM subscription_status
        WHERE subscription_status.user_id = current_user_id;
        
        -- Si toujours NULL, créer un workshop_id par défaut
        IF current_workshop_id IS NULL THEN
            -- Créer un nouveau workshop_id
            current_workshop_id := gen_random_uuid();
            
            -- Mettre à jour l'utilisateur
            UPDATE subscription_status 
            SET workshop_id = current_workshop_id
            WHERE subscription_status.user_id = current_user_id;
            
            RAISE NOTICE 'Nouveau workshop_id créé pour l''utilisateur: %', current_workshop_id;
        END IF;
    END IF;
    
    -- Assigner les valeurs
    NEW.workshop_id := current_workshop_id;
    NEW.created_by := current_user_id;
    
    -- Si created_at n'est pas défini, le définir
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- Toujours mettre à jour updated_at
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RECRÉER LE TRIGGER
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 5. VÉRIFIER LA NOUVELLE FONCTION
-- =====================================================

SELECT 
    'FONCTION CORRIGÉE' as verification,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 6. VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    'TRIGGER RECRÉÉ' as verification,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 7. VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS' as verification,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 8. TESTER LA FONCTION (SIMULATION)
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
    'AMBIGUÏTÉ CORRIGÉE COMPLÈTE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Fonction d''isolation corrigée sans ambiguïté et trigger recréé' as description;
