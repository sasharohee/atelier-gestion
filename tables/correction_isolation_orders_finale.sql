-- =====================================================
-- CORRECTION ISOLATION ORDERS - VERSION FINALE
-- =====================================================

SELECT 'CORRECTION ISOLATION ORDERS FINALE' as section;

-- 1. VÉRIFIER ET AJOUTER LA COLONNE WORKSHOP_ID SI NÉCESSAIRE
-- =====================================================

-- Ajouter la colonne workshop_id à subscription_status si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'subscription_status' 
          AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE subscription_status ADD COLUMN workshop_id uuid;
        RAISE NOTICE 'Colonne workshop_id ajoutée à subscription_status';
    ELSE
        RAISE NOTICE 'Colonne workshop_id existe déjà dans subscription_status';
    END IF;
END $$;

-- 2. CRÉER UN WORKSHOP_ID PAR DÉFAUT POUR TOUS LES UTILISATEURS
-- =====================================================

DO $$
DECLARE
    default_workshop_id uuid;
BEGIN
    -- Créer un workshop_id par défaut
    default_workshop_id := gen_random_uuid();
    
    -- Mettre à jour tous les utilisateurs sans workshop_id
    UPDATE subscription_status 
    SET workshop_id = default_workshop_id
    WHERE workshop_id IS NULL;
    
    RAISE NOTICE 'Workshop_id par défaut créé: %', default_workshop_id;
    RAISE NOTICE 'Utilisateurs mis à jour avec le workshop_id par défaut';
END $$;

-- 3. ACTIVER RLS SUR LA TABLE ORDERS
-- =====================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 4. SUPPRIMER LES ANCIENNES POLITIQUES (SI ELLES EXISTENT)
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 5. SUPPRIMER LES ANCIENS TRIGGERS DÉPENDANTS (SI ILS EXISTENT)
-- =====================================================

DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- 6. SUPPRIMER L'ANCIENNE FONCTION (SI ELLE EXISTE)
-- =====================================================

DROP FUNCTION IF EXISTS set_order_isolation();

-- 7. CRÉER LA NOUVELLE FONCTION D'ISOLATION ROBUSTE
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    user_workshop_id uuid;
    user_id uuid;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    user_id := auth.uid();
    
    -- Vérifier si l'utilisateur est authentifié
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié.';
    END IF;
    
    -- Essayer de récupérer le workshop_id depuis le JWT
    user_workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
    
    -- Si pas dans le JWT, récupérer depuis subscription_status
    IF user_workshop_id IS NULL THEN
        SELECT workshop_id INTO user_workshop_id
        FROM subscription_status
        WHERE user_id = auth.uid();
        
        -- Si toujours NULL, créer un workshop_id par défaut
        IF user_workshop_id IS NULL THEN
            -- Créer un nouveau workshop_id
            user_workshop_id := gen_random_uuid();
            
            -- Mettre à jour l'utilisateur
            UPDATE subscription_status 
            SET workshop_id = user_workshop_id
            WHERE user_id = auth.uid();
            
            RAISE NOTICE 'Nouveau workshop_id créé pour l''utilisateur: %', user_workshop_id;
        END IF;
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

-- 8. CRÉER LE TRIGGER POUR LA TABLE ORDERS
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 9. CRÉER LES POLITIQUES RLS POUR ORDERS
-- =====================================================

-- Politique pour SELECT (lecture)
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid 
           OR workshop_id IN (
               SELECT workshop_id 
               FROM subscription_status 
               WHERE user_id = auth.uid()
           ));

-- Politique pour INSERT (création)
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT
    WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid 
                OR workshop_id IN (
                    SELECT workshop_id 
                    FROM subscription_status 
                    WHERE user_id = auth.uid()
                ));

-- Politique pour UPDATE (modification)
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid 
           OR workshop_id IN (
               SELECT workshop_id 
               FROM subscription_status 
               WHERE user_id = auth.uid()
           ))
    WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid 
                OR workshop_id IN (
                    SELECT workshop_id 
                    FROM subscription_status 
                    WHERE user_id = auth.uid()
                ));

-- Politique pour DELETE (suppression)
CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid 
           OR workshop_id IN (
               SELECT workshop_id 
               FROM subscription_status 
               WHERE user_id = auth.uid()
           ));

-- 10. VÉRIFIER LA CONFIGURATION
-- =====================================================

-- Vérifier que RLS est activé sur orders
SELECT 
    'RLS ACTIVÉ SUR ORDERS' as verification,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'orders';

-- Vérifier les politiques créées pour orders
SELECT 
    'POLITIQUES CRÉÉES POUR ORDERS' as verification,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Vérifier le trigger créé pour orders
SELECT 
    'TRIGGER CRÉÉ POUR ORDERS' as verification,
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

-- Vérifier la colonne workshop_id dans subscription_status
SELECT 
    'COLONNE WORKSHOP_ID' as verification,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND column_name = 'workshop_id';

-- Vérifier les utilisateurs avec workshop_id
SELECT 
    'UTILISATEURS AVEC WORKSHOP_ID' as verification,
    COUNT(*) as total_utilisateurs,
    COUNT(workshop_id) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM subscription_status;

-- 11. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION CORRIGÉE FINALE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Isolation des données complètement configurée' as description;
