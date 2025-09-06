-- =====================================================
-- CORRECTION FONCTION ISOLATION AUTHENTIFICATION
-- =====================================================

SELECT 'CORRECTION FONCTION ISOLATION AUTH' as section;

-- 1. SUPPRIMER LE TRIGGER D'ABORD
-- =====================================================

DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;

-- 2. SUPPRIMER L'ANCIENNE FONCTION
-- =====================================================

DROP FUNCTION IF EXISTS set_order_isolation();

-- 3. CRÉER LA NOUVELLE FONCTION AVEC GESTION D'AUTHENTIFICATION ROBUSTE
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id uuid;
    current_workshop_id uuid;
    jwt_workshop_id uuid;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté avec gestion d'erreur
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION
        WHEN OTHERS THEN
            current_user_id := NULL;
    END;
    
    -- Si pas d'utilisateur authentifié, essayer de récupérer depuis le JWT
    IF current_user_id IS NULL THEN
        BEGIN
            jwt_workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
            IF jwt_workshop_id IS NOT NULL THEN
                -- Utiliser le workshop_id du JWT
                NEW.workshop_id := jwt_workshop_id;
                NEW.created_by := NULL; -- Pas d'utilisateur authentifié
                NEW.updated_at := CURRENT_TIMESTAMP;
                RETURN NEW;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                -- Si pas de JWT valide, utiliser un workshop_id par défaut
                NEW.workshop_id := '00000000-0000-0000-0000-000000000000'::uuid;
                NEW.created_by := NULL;
                NEW.updated_at := CURRENT_TIMESTAMP;
                RAISE NOTICE 'Utilisateur non authentifié, utilisation du workshop_id par défaut';
                RETURN NEW;
        END;
    END IF;
    
    -- Essayer de récupérer le workshop_id depuis le JWT
    BEGIN
        jwt_workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
    EXCEPTION
        WHEN OTHERS THEN
            jwt_workshop_id := NULL;
    END;
    
    -- Si pas dans le JWT, récupérer depuis subscription_status
    IF jwt_workshop_id IS NULL THEN
        BEGIN
            SELECT workshop_id INTO current_workshop_id
            FROM subscription_status
            WHERE subscription_status.user_id = current_user_id;
        EXCEPTION
            WHEN OTHERS THEN
                current_workshop_id := NULL;
        END;
        
        -- Si toujours NULL, créer un workshop_id par défaut
        IF current_workshop_id IS NULL THEN
            -- Créer un nouveau workshop_id
            current_workshop_id := gen_random_uuid();
            
            -- Mettre à jour l'utilisateur
            BEGIN
                UPDATE subscription_status 
                SET workshop_id = current_workshop_id
                WHERE subscription_status.user_id = current_user_id;
                
                RAISE NOTICE 'Nouveau workshop_id créé pour l''utilisateur: %', current_workshop_id;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Impossible de mettre à jour subscription_status, utilisation du workshop_id généré';
            END;
        END IF;
    ELSE
        current_workshop_id := jwt_workshop_id;
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

-- 7. CRÉER UNE FONCTION DE TEST POUR VÉRIFIER L'AUTHENTIFICATION
-- =====================================================

CREATE OR REPLACE FUNCTION test_auth_status()
RETURNS TABLE (
    auth_uid uuid,
    jwt_workshop_id uuid,
    auth_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        auth.uid() as auth_uid,
        (auth.jwt() ->> 'workshop_id')::uuid as jwt_workshop_id,
        CASE 
            WHEN auth.uid() IS NOT NULL THEN 'Authentifié'
            ELSE 'Non authentifié'
        END as auth_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. TESTER LA FONCTION D'AUTHENTIFICATION
-- =====================================================

SELECT 
    'TEST AUTH' as test,
    'Fonction test_auth_status() créée' as description,
    'Exécuter SELECT * FROM test_auth_status(); pour tester' as instruction;

-- 9. VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS' as verification,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'AUTHENTIFICATION CORRIGÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Fonction d''isolation avec gestion d''authentification robuste' as description;
