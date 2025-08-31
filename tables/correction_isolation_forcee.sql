-- =====================================================
-- CORRECTION ISOLATION FORCÉE
-- =====================================================

SELECT 'CORRECTION ISOLATION FORCÉE' as section;

-- 1. NETTOYER COMPLÈTEMENT
-- =====================================================

-- Supprimer tous les triggers
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- Supprimer toutes les fonctions
DROP FUNCTION IF EXISTS set_order_isolation();
DROP FUNCTION IF EXISTS test_auth_status();
DROP FUNCTION IF EXISTS test_isolation();

-- Supprimer toutes les politiques RLS
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 2. SUPPRIMER TOUTES LES COMMANDES EXISTANTES
-- =====================================================

DELETE FROM orders;

-- 3. RÉINITIALISER LES WORKSHOP_ID
-- =====================================================

-- Supprimer tous les workshop_id existants
UPDATE subscription_status SET workshop_id = NULL;

-- Attribuer des workshop_id uniques
UPDATE subscription_status 
SET workshop_id = gen_random_uuid()
WHERE workshop_id IS NULL;

-- 4. VÉRIFIER QU'IL N'Y A PLUS DE DOUBLONS
-- =====================================================

SELECT 
    'VÉRIFICATION WORKSHOP_ID UNIQUES' as verification,
    COUNT(*) as total_users,
    COUNT(DISTINCT workshop_id) as unique_workshop_ids,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT workshop_id) THEN '✅ AUCUN DOUBLON'
        ELSE '❌ DOUBLONS DÉTECTÉS'
    END as status
FROM subscription_status;

-- 5. CRÉER UNE FONCTION D'ISOLATION SIMPLE ET EFFICACE
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    user_workshop_id uuid;
BEGIN
    -- Récupérer le workshop_id de l'utilisateur connecté
    SELECT workshop_id INTO user_workshop_id
    FROM subscription_status
    WHERE user_id = auth.uid();
    
    -- Si pas de workshop_id, en créer un
    IF user_workshop_id IS NULL THEN
        user_workshop_id := gen_random_uuid();
        UPDATE subscription_status 
        SET workshop_id = user_workshop_id
        WHERE user_id = auth.uid();
    END IF;
    
    -- Assigner les valeurs
    NEW.workshop_id := user_workshop_id;
    NEW.created_by := auth.uid();
    
    -- Timestamps
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRÉER LE TRIGGER
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 7. CRÉER DES POLITIQUES RLS TRÈS STRICTES
-- =====================================================

-- Politique de lecture : uniquement les commandes du workshop_id de l'utilisateur
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT
    USING (
        workshop_id = (
            SELECT workshop_id 
            FROM subscription_status 
            WHERE user_id = auth.uid()
        )
    );

-- Politique d'insertion : uniquement avec le workshop_id de l'utilisateur
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT
    WITH CHECK (
        workshop_id = (
            SELECT workshop_id 
            FROM subscription_status 
            WHERE user_id = auth.uid()
        )
    );

-- Politique de mise à jour : uniquement les commandes du workshop_id de l'utilisateur
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE
    USING (
        workshop_id = (
            SELECT workshop_id 
            FROM subscription_status 
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        workshop_id = (
            SELECT workshop_id 
            FROM subscription_status 
            WHERE user_id = auth.uid()
        )
    );

-- Politique de suppression : uniquement les commandes du workshop_id de l'utilisateur
CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE
    USING (
        workshop_id = (
            SELECT workshop_id 
            FROM subscription_status 
            WHERE user_id = auth.uid()
        )
    );

-- 8. CRÉER UNE FONCTION DE TEST SIMPLE
-- =====================================================

CREATE OR REPLACE FUNCTION test_isolation_simple()
RETURNS TABLE (
    user_email text,
    user_workshop_id uuid,
    orders_count bigint,
    isolation_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.email,
        ss.workshop_id,
        COUNT(o.id) as orders_count,
        CASE 
            WHEN COUNT(o.id) = 0 THEN 'Aucune commande'
            WHEN COUNT(o.id) = COUNT(CASE WHEN o.workshop_id = ss.workshop_id THEN 1 END) 
                THEN '✅ ISOLATION CORRECTE'
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

-- Vérifier les politiques
SELECT 
    'POLITIQUES RLS APRÈS CORRECTION' as verification,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE tablename = 'orders';

-- Vérifier la fonction
SELECT 
    'FONCTION APRÈS CORRECTION' as verification,
    COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation';

-- Vérifier le trigger
SELECT 
    'TRIGGER APRÈS CORRECTION' as verification,
    COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION FORCÉE APPLIQUÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Base de données nettoyée et isolation recréée de zéro' as description;
