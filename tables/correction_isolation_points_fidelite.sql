-- 🔧 CORRECTION - Isolation des Données Points de Fidélité
-- Ce script ajoute l'isolation des données par utilisateur aux tables de fidélité

-- ============================================================================
-- 1. DIAGNOSTIC INITIAL
-- ============================================================================

-- Vérifier la structure actuelle des tables de fidélité
SELECT '=== DIAGNOSTIC INITIAL ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
ORDER BY table_name, ordinal_position;

-- Vérifier les politiques RLS actuelles
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
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
ORDER BY tablename, policyname;

-- ============================================================================
-- 2. AJOUT DES COLONNES USER_ID
-- ============================================================================

SELECT '=== AJOUT DES COLONNES USER_ID ===' as section;

-- Ajouter user_id à client_loyalty_points
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'client_loyalty_points' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.client_loyalty_points ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à client_loyalty_points';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans client_loyalty_points';
    END IF;
END $$;

-- Ajouter user_id à referrals
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'referrals' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.referrals ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à referrals';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans referrals';
    END IF;
END $$;

-- Ajouter user_id à loyalty_points_history
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_points_history' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.loyalty_points_history ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à loyalty_points_history';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans loyalty_points_history';
    END IF;
END $$;

-- Ajouter user_id à loyalty_rules
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_rules' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.loyalty_rules ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à loyalty_rules';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans loyalty_rules';
    END IF;
END $$;

-- Note: loyalty_tiers reste global (pas de user_id car c'est une configuration système)

-- ============================================================================
-- 3. MISE À JOUR DES DONNÉES EXISTANTES
-- ============================================================================

SELECT '=== MISE À JOUR DES DONNÉES EXISTANTES ===' as section;

-- Mettre à jour client_loyalty_points avec le user_id du client
UPDATE public.client_loyalty_points 
SET user_id = (
    SELECT c.user_id 
    FROM public.clients c 
    WHERE c.id = client_loyalty_points.client_id
)
WHERE user_id IS NULL;

-- Mettre à jour referrals avec le user_id du client parrain
UPDATE public.referrals 
SET user_id = (
    SELECT c.user_id 
    FROM public.clients c 
    WHERE c.id = referrals.referrer_client_id
)
WHERE user_id IS NULL;

-- Mettre à jour loyalty_points_history avec le user_id du client
UPDATE public.loyalty_points_history 
SET user_id = (
    SELECT c.user_id 
    FROM public.clients c 
    WHERE c.id = loyalty_points_history.client_id
)
WHERE user_id IS NULL;

-- Mettre à jour loyalty_rules avec le premier utilisateur admin
UPDATE public.loyalty_rules 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;

-- ============================================================================
-- 4. AJOUT DES CONTRAINTES NOT NULL
-- ============================================================================

SELECT '=== AJOUT DES CONTRAINTES NOT NULL ===' as section;

-- Rendre user_id obligatoire pour client_loyalty_points
ALTER TABLE public.client_loyalty_points ALTER COLUMN user_id SET NOT NULL;

-- Rendre user_id obligatoire pour referrals
ALTER TABLE public.referrals ALTER COLUMN user_id SET NOT NULL;

-- Rendre user_id obligatoire pour loyalty_points_history
ALTER TABLE public.loyalty_points_history ALTER COLUMN user_id SET NOT NULL;

-- Rendre user_id obligatoire pour loyalty_rules
ALTER TABLE public.loyalty_rules ALTER COLUMN user_id SET NOT NULL;

-- ============================================================================
-- 5. CRÉATION DES INDEX
-- ============================================================================

SELECT '=== CRÉATION DES INDEX ===' as section;

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_client_loyalty_points_user_id ON public.client_loyalty_points(user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_user_id ON public.referrals(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_points_history_user_id ON public.loyalty_points_history(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_user_id ON public.loyalty_rules(user_id);

-- ============================================================================
-- 6. SUPPRESSION DES ANCIENNES POLITIQUES RLS
-- ============================================================================

SELECT '=== SUPPRESSION DES ANCIENNES POLITIQUES RLS ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "loyalty_tiers_read_policy" ON loyalty_tiers;
DROP POLICY IF EXISTS "referrals_read_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_insert_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_update_policy" ON referrals;
DROP POLICY IF EXISTS "client_loyalty_points_read_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_insert_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_update_policy" ON client_loyalty_points;

-- ============================================================================
-- 7. ACTIVATION DE RLS
-- ============================================================================

SELECT '=== ACTIVATION DE RLS ===' as section;

-- Activer RLS sur toutes les tables
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 8. CRÉATION DES NOUVELLES POLITIQUES RLS
-- ============================================================================

SELECT '=== CRÉATION DES NOUVELLES POLITIQUES RLS ===' as section;

-- Politiques pour loyalty_tiers (lecture pour tous les utilisateurs autorisés)
CREATE POLICY "loyalty_tiers_read_policy" ON loyalty_tiers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Politiques pour referrals
CREATE POLICY "referrals_read_policy" ON referrals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "referrals_insert_policy" ON referrals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "referrals_update_policy" ON referrals
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "referrals_delete_policy" ON referrals
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour client_loyalty_points
CREATE POLICY "client_loyalty_points_read_policy" ON client_loyalty_points
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "client_loyalty_points_insert_policy" ON client_loyalty_points
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "client_loyalty_points_update_policy" ON client_loyalty_points
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "client_loyalty_points_delete_policy" ON client_loyalty_points
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour loyalty_points_history
CREATE POLICY "loyalty_points_history_read_policy" ON loyalty_points_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "loyalty_points_history_insert_policy" ON loyalty_points_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loyalty_points_history_update_policy" ON loyalty_points_history
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loyalty_points_history_delete_policy" ON loyalty_points_history
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour loyalty_rules
CREATE POLICY "loyalty_rules_read_policy" ON loyalty_rules
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "loyalty_rules_insert_policy" ON loyalty_rules
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loyalty_rules_update_policy" ON loyalty_rules
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loyalty_rules_delete_policy" ON loyalty_rules
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 9. MISE À JOUR DES FONCTIONS
-- ============================================================================

SELECT '=== MISE À JOUR DES FONCTIONS ===' as section;

-- Mettre à jour la fonction add_loyalty_points pour inclure user_id
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT 'Points ajoutés manuellement'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_client_loyalty client_loyalty_points%ROWTYPE;
    v_tier loyalty_tiers%ROWTYPE;
    v_user_id UUID;
BEGIN
    -- Récupérer le user_id du client
    SELECT user_id INTO v_user_id
    FROM public.clients
    WHERE id = p_client_id;
    
    -- Vérifier que l'utilisateur connecté a accès à ce client
    IF v_user_id != auth.uid() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé à ce client'
        );
    END IF;
    
    -- Vérifier si le client existe déjà dans la table des points
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    IF v_client_loyalty IS NULL THEN
        -- Créer une nouvelle entrée
        INSERT INTO client_loyalty_points (client_id, total_points, used_points, user_id)
        VALUES (p_client_id, p_points, 0, v_user_id)
        RETURNING * INTO v_client_loyalty;
    ELSE
        -- Mettre à jour les points existants
        UPDATE client_loyalty_points
        SET 
            total_points = client_loyalty_points.total_points + p_points,
            updated_at = NOW()
        WHERE client_id = p_client_id
        RETURNING * INTO v_client_loyalty;
    END IF;
    
    -- Calculer le nouveau niveau
    SELECT * INTO v_tier
    FROM loyalty_tiers
    WHERE min_points <= (v_client_loyalty.total_points - v_client_loyalty.used_points)
    ORDER BY min_points DESC
    LIMIT 1;
    
    -- Mettre à jour le niveau si nécessaire
    IF v_tier.id != v_client_loyalty.current_tier_id THEN
        UPDATE client_loyalty_points
        SET current_tier_id = v_tier.id
        WHERE client_id = p_client_id;
    END IF;
    
    -- Ajouter l'historique
    INSERT INTO loyalty_points_history (
        client_id, 
        points_change, 
        points_type, 
        source_type, 
        description, 
        created_by,
        user_id
    ) VALUES (
        p_client_id, 
        p_points, 
        'earned', 
        'manual', 
        p_description,
        auth.uid(),
        v_user_id
    );
    
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', v_client_loyalty.client_id,
            'total_points', v_client_loyalty.total_points,
            'used_points', v_client_loyalty.used_points,
            'available_points', v_client_loyalty.total_points - v_client_loyalty.used_points,
            'current_tier', v_tier.name
        )
    );
END;
$$;

-- ============================================================================
-- 10. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure finale
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
    AND column_name = 'user_id'
ORDER BY table_name;

-- Vérifier les politiques RLS finales
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
ORDER BY tablename, policyname;

-- Compter les données par utilisateur
SELECT 
    'client_loyalty_points' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM client_loyalty_points
UNION ALL
SELECT 
    'referrals' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM referrals
UNION ALL
SELECT 
    'loyalty_points_history' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM loyalty_points_history
UNION ALL
SELECT 
    'loyalty_rules' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM loyalty_rules;

SELECT '✅ CORRECTION TERMINÉE - Isolation des données points de fidélité activée' as status;
