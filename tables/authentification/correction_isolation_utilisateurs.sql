-- =====================================================
-- CORRECTION ISOLATION UTILISATEURS
-- =====================================================

SELECT 'CORRECTION ISOLATION UTILISATEURS' as section;

-- 1. VÉRIFIER L'ÉTAT ACTUEL DES UTILISATEURS
-- =====================================================

SELECT 
    'ÉTAT ACTUEL' as verification,
    user_id,
    email,
    workshop_id,
    status,
    created_at
FROM subscription_status 
ORDER BY created_at DESC;

-- 2. IDENTIFIER LES UTILISATEURS AVEC LE MÊME WORKSHOP_ID
-- =====================================================

SELECT 
    'UTILISATEURS MÊME WORKSHOP' as probleme,
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NOT NULL
GROUP BY workshop_id
HAVING COUNT(*) > 1
ORDER BY nombre_utilisateurs DESC;

-- 3. ATTRIBUER DES WORKSHOP_ID UNIQUES À CHAQUE UTILISATEUR
-- =====================================================

-- Créer une table temporaire pour stocker les nouveaux workshop_id
CREATE TEMP TABLE user_workshop_mapping AS
SELECT 
    user_id,
    email,
    gen_random_uuid() as new_workshop_id
FROM subscription_status
ORDER BY created_at;

-- Mettre à jour les utilisateurs avec des workshop_id uniques
UPDATE subscription_status 
SET workshop_id = mapping.new_workshop_id
FROM user_workshop_mapping mapping
WHERE subscription_status.user_id = mapping.user_id;

-- 4. VÉRIFIER LA CORRECTION
-- =====================================================

SELECT 
    'VÉRIFICATION APRÈS CORRECTION' as verification,
    user_id,
    email,
    workshop_id,
    status
FROM subscription_status 
ORDER BY created_at DESC;

-- 5. VÉRIFIER QU'IL N'Y A PLUS DE DOUBLONS
-- =====================================================

SELECT 
    'VÉRIFICATION DOUBLONS' as verification,
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NOT NULL
GROUP BY workshop_id
HAVING COUNT(*) > 1
ORDER BY nombre_utilisateurs DESC;

-- 6. CORRIGER LES COMMANDES EXISTANTES
-- =====================================================

-- Mettre à jour les commandes pour qu'elles correspondent aux nouveaux workshop_id
UPDATE orders 
SET workshop_id = subscription_status.workshop_id
FROM subscription_status
WHERE orders.created_by = subscription_status.user_id
  AND orders.workshop_id != subscription_status.workshop_id;

-- 7. VÉRIFIER LES COMMANDES APRÈS CORRECTION
-- =====================================================

SELECT 
    'COMMANDES APRÈS CORRECTION' as verification,
    workshop_id,
    created_by,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY workshop_id, created_by
ORDER BY nombre_commandes DESC;

-- 8. VÉRIFIER LA CORRESPONDANCE WORKSHOP_ID / CREATED_BY
-- =====================================================

SELECT 
    'CORRESPONDANCE FINALE' as verification,
    o.workshop_id as order_workshop_id,
    s.workshop_id as user_workshop_id,
    o.created_by,
    s.email,
    COUNT(*) as nombre_commandes
FROM orders o
JOIN subscription_status s ON o.created_by = s.user_id
GROUP BY o.workshop_id, s.workshop_id, o.created_by, s.email
ORDER BY nombre_commandes DESC;

-- 9. RECRÉER LES POLITIQUES RLS POUR S'ASSURER QU'ELLES FONCTIONNENT
-- =====================================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- Recréer les politiques avec une logique plus stricte
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

-- 10. VÉRIFIER LES NOUVELLES POLITIQUES
-- =====================================================

SELECT 
    'POLITIQUES RECRÉÉES' as verification,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 11. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION CORRIGÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Chaque utilisateur a maintenant son propre workshop_id' as description;
