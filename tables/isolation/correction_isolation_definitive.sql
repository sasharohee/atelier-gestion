-- =====================================================
-- CORRECTION ISOLATION DÉFINITIVE
-- =====================================================

SELECT 'CORRECTION ISOLATION DÉFINITIVE' as section;

-- 1. NETTOYER LES TRIGGERS ET FONCTIONS EXISTANTS
-- =====================================================

-- Supprimer tous les triggers dépendants
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS set_order_isolation();
DROP FUNCTION IF EXISTS test_auth_status();

-- 2. S'ASSURER QUE CHAQUE UTILISATEUR A UN WORKSHOP_ID UNIQUE
-- =====================================================

-- Créer une table temporaire pour stocker les nouveaux workshop_id
CREATE TEMP TABLE user_workshop_mapping AS
SELECT
    user_id,
    email,
    gen_random_uuid() as new_workshop_id
FROM subscription_status
ORDER BY created_at;

-- Mettre à jour tous les utilisateurs avec des workshop_id uniques
UPDATE subscription_status
SET workshop_id = mapping.new_workshop_id
FROM user_workshop_mapping mapping
WHERE subscription_status.user_id = mapping.user_id;

-- 3. VÉRIFIER QU'IL N'Y A PLUS DE DOUBLONS
-- =====================================================

SELECT 
    'VÉRIFICATION DOUBLONS' as verification,
    COUNT(*) as total_users,
    COUNT(DISTINCT workshop_id) as unique_workshop_ids,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT workshop_id) THEN '✅ AUCUN DOUBLON'
        ELSE '❌ DOUBLONS DÉTECTÉS'
    END as status
FROM subscription_status;

-- 4. CRÉER UNE FONCTION D'ISOLATION ROBUSTE
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id uuid;
    current_workshop_id uuid;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION
        WHEN OTHERS THEN
            current_user_id := NULL;
    END;
    
    -- Si pas d'utilisateur authentifié, utiliser un workshop_id par défaut
    IF current_user_id IS NULL THEN
        NEW.workshop_id := '00000000-0000-0000-0000-000000000000'::uuid;
        NEW.created_by := NULL;
        NEW.updated_at := CURRENT_TIMESTAMP;
        RAISE NOTICE 'Utilisateur non authentifié, utilisation du workshop_id par défaut';
        RETURN NEW;
    END IF;
    
    -- Récupérer le workshop_id de l'utilisateur
    BEGIN
        SELECT workshop_id INTO current_workshop_id
        FROM subscription_status
        WHERE user_id = current_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            current_workshop_id := NULL;
    END;
    
    -- Si pas de workshop_id, en créer un nouveau
    IF current_workshop_id IS NULL THEN
        current_workshop_id := gen_random_uuid();
        
        -- Mettre à jour l'utilisateur
        BEGIN
            UPDATE subscription_status 
            SET workshop_id = current_workshop_id
            WHERE user_id = current_user_id;
            
            RAISE NOTICE 'Nouveau workshop_id créé pour l''utilisateur: %', current_workshop_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Impossible de mettre à jour subscription_status, utilisation du workshop_id généré';
        END;
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

-- 5. CRÉER LE TRIGGER
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 6. CORRIGER LES COMMANDES EXISTANTES
-- =====================================================

-- Mettre à jour toutes les commandes pour qu'elles correspondent aux nouveaux workshop_id
UPDATE orders
SET workshop_id = subscription_status.workshop_id
FROM subscription_status
WHERE orders.created_by = subscription_status.user_id
  AND orders.workshop_id != subscription_status.workshop_id;

-- 7. RECRÉER LES POLITIQUES RLS AVEC UNE LOGIQUE STRICTE
-- =====================================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- Recréer les politiques avec une logique stricte
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT
    USING (workshop_id IN (
        SELECT workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid()
    ));

CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT
    WITH CHECK (workshop_id IN (
        SELECT workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid()
    ));

CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE
    USING (workshop_id IN (
        SELECT workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid()
    ))
    WITH CHECK (workshop_id IN (
        SELECT workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid()
    ));

CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE
    USING (workshop_id IN (
        SELECT workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid()
    ));

-- 8. CRÉER UNE FONCTION DE TEST
-- =====================================================

CREATE OR REPLACE FUNCTION test_isolation()
RETURNS TABLE (
    user_id uuid,
    email text,
    workshop_id uuid,
    orders_count bigint,
    isolation_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.user_id,
        ss.email,
        ss.workshop_id,
        COUNT(o.id) as orders_count,
        CASE 
            WHEN COUNT(o.id) = 0 THEN 'Aucune commande'
            WHEN COUNT(o.id) = COUNT(CASE WHEN o.workshop_id = ss.workshop_id THEN 1 END) THEN '✅ ISOLATION CORRECTE'
            ELSE '❌ ISOLATION INCORRECTE'
        END as isolation_status
    FROM subscription_status ss
    LEFT JOIN orders o ON ss.user_id = o.created_by
    GROUP BY ss.user_id, ss.email, ss.workshop_id
    ORDER BY ss.email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. VÉRIFIER LA CORRECTION
-- =====================================================

-- Vérifier les utilisateurs
SELECT 
    'UTILISATEURS APRÈS CORRECTION' as verification,
    COUNT(*) as total_users,
    COUNT(DISTINCT workshop_id) as unique_workshop_ids
FROM subscription_status;

-- Vérifier les commandes
SELECT 
    'COMMANDES APRÈS CORRECTION' as verification,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as orders_with_workshop_id
FROM orders;

-- Vérifier l'isolation
SELECT 
    'TEST ISOLATION' as verification,
    'Exécuter SELECT * FROM test_isolation();' as instruction;

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION DÉFINITIVE APPLIQUÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Chaque utilisateur a un workshop_id unique et les politiques RLS sont strictes' as description;
