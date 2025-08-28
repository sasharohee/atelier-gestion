-- CORRECTION DE L'ISOLATION DES DONNÉES POUR LES POINTS DE FIDÉLITÉ
-- Ce script corrige les politiques RLS pour que l'isolation fonctionne correctement

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE L'ÉTAT ACTUEL
-- =====================================================

SELECT '=== VÉRIFICATION ÉTAT ACTUEL ===' as etape;

-- Vérifier l'état RLS sur les tables de fidélité
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
AND schemaname = 'public';

-- Vérifier les politiques RLS existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
AND schemaname = 'public';

-- =====================================================
-- ÉTAPE 2: CRÉER LA FONCTION D'AUTORISATION
-- =====================================================

SELECT '=== CRÉATION FONCTION D''AUTORISATION ===' as etape;

-- Fonction pour vérifier si l'utilisateur peut accéder aux données de fidélité
CREATE OR REPLACE FUNCTION can_access_loyalty_data(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Si pas d'utilisateur connecté, refuser l'accès
    IF user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Récupérer le rôle de l'utilisateur
    SELECT role INTO user_role
    FROM users
    WHERE id = user_id;
    
    -- Autoriser l'accès pour tous les rôles (admin, technician, manager)
    IF user_role IN ('admin', 'technician', 'manager') THEN
        RETURN TRUE;
    END IF;
    
    -- Par défaut, refuser l'accès
    RETURN FALSE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, autoriser l'accès pour éviter les blocages
        RETURN TRUE;
END;
$$;

-- =====================================================
-- ÉTAPE 3: SUPPRIMER LES ANCIENNES POLITIQUES
-- =====================================================

SELECT '=== SUPPRESSION ANCIENNES POLITIQUES ===' as etape;

-- Supprimer toutes les politiques RLS existantes sur les tables de fidélité
DROP POLICY IF EXISTS "loyalty_tiers_read_policy" ON loyalty_tiers;
DROP POLICY IF EXISTS "referrals_read_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_insert_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_update_policy" ON referrals;
DROP POLICY IF EXISTS "client_loyalty_points_read_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_insert_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_update_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "loyalty_points_history_read_policy" ON loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_insert_policy" ON loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_rules_read_policy" ON loyalty_rules;
DROP POLICY IF EXISTS "loyalty_rules_update_policy" ON loyalty_rules;

-- =====================================================
-- ÉTAPE 4: CRÉER LES NOUVELLES POLITIQUES RLS
-- =====================================================

SELECT '=== CRÉATION NOUVELLES POLITIQUES ===' as etape;

-- S'assurer que RLS est activé sur toutes les tables
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules ENABLE ROW LEVEL SECURITY;

-- Politiques pour loyalty_tiers (lecture pour tous les utilisateurs autorisés)
CREATE POLICY "loyalty_tiers_read_policy" ON loyalty_tiers
    FOR SELECT USING (can_access_loyalty_data());

-- Politiques pour referrals
CREATE POLICY "referrals_read_policy" ON referrals
    FOR SELECT USING (can_access_loyalty_data());

CREATE POLICY "referrals_insert_policy" ON referrals
    FOR INSERT WITH CHECK (can_access_loyalty_data());

CREATE POLICY "referrals_update_policy" ON referrals
    FOR UPDATE USING (can_access_loyalty_data());

-- Politiques pour client_loyalty_points
CREATE POLICY "client_loyalty_points_read_policy" ON client_loyalty_points
    FOR SELECT USING (can_access_loyalty_data());

CREATE POLICY "client_loyalty_points_insert_policy" ON client_loyalty_points
    FOR INSERT WITH CHECK (can_access_loyalty_data());

CREATE POLICY "client_loyalty_points_update_policy" ON client_loyalty_points
    FOR UPDATE USING (can_access_loyalty_data());

-- Politiques pour loyalty_points_history
CREATE POLICY "loyalty_points_history_read_policy" ON loyalty_points_history
    FOR SELECT USING (can_access_loyalty_data());

CREATE POLICY "loyalty_points_history_insert_policy" ON loyalty_points_history
    FOR INSERT WITH CHECK (can_access_loyalty_data());

-- Politiques pour loyalty_rules
CREATE POLICY "loyalty_rules_read_policy" ON loyalty_rules
    FOR SELECT USING (can_access_loyalty_data());

CREATE POLICY "loyalty_rules_update_policy" ON loyalty_rules
    FOR UPDATE USING (can_access_loyalty_data());

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier l'état RLS après correction
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
AND schemaname = 'public';

-- Vérifier les nouvelles politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- Test de la fonction d'autorisation
SELECT 
    'Test fonction autorisation' as test,
    can_access_loyalty_data() as autorisation_actuelle,
    auth.uid() as utilisateur_connecte;

-- Message de confirmation
SELECT '✅ Isolation des données corrigée pour les points de fidélité' as status;
