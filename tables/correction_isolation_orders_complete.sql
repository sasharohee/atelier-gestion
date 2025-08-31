-- =====================================================
-- CORRECTION ISOLATION DONNÉES - TABLE ORDERS
-- =====================================================

-- 1. ACTIVER RLS SUR LA TABLE ORDERS
-- =====================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER LES ANCIENNES POLITIQUES (SI ELLES EXISTENT)
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 3. SUPPRIMER LES ANCIENS TRIGGERS (SI ILS EXISTENT)
-- =====================================================

DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;

-- 4. SUPPRIMER L'ANCIENNE FONCTION (SI ELLE EXISTE)
-- =====================================================

DROP FUNCTION IF EXISTS set_order_isolation();

-- 5. CRÉER LA NOUVELLE FONCTION D'ISOLATION
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
BEGIN
    -- Récupérer le workshop_id de l'utilisateur connecté
    NEW.workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
    
    -- Récupérer l'ID de l'utilisateur connecté
    NEW.created_by := auth.uid();
    
    -- Si created_at n'est pas défini, le définir
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- Toujours mettre à jour updated_at
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRÉER LE TRIGGER POUR L'ISOLATION
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 7. CRÉER LES POLITIQUES RLS
-- =====================================================

-- Politique pour SELECT (lecture)
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politique pour INSERT (création)
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT
    WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politique pour UPDATE (modification)
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid)
    WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politique pour DELETE (suppression)
CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- 8. VÉRIFIER LA CONFIGURATION
-- =====================================================

-- Vérifier que RLS est activé
SELECT 
    'RLS ACTIVÉ' as verification,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'orders';

-- Vérifier les politiques créées
SELECT 
    'POLITIQUES CRÉÉES' as verification,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Vérifier le trigger créé
SELECT 
    'TRIGGER CRÉÉ' as verification,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- Vérifier la fonction créée
SELECT 
    'FONCTION CRÉÉE' as verification,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 9. TESTER L'ISOLATION
-- =====================================================

-- Afficher les commandes actuelles (pour vérification)
SELECT 
    'COMMANDES ACTUELLES' as test,
    COUNT(*) as total_commandes,
    COUNT(DISTINCT workshop_id) as workshops_distincts,
    COUNT(DISTINCT created_by) as utilisateurs_distincts
FROM orders;

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION CORRIGÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Isolation des données activée pour la table orders' as description;
