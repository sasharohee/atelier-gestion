-- 🔧 CORRECTION SIMPLE - Isolation Points de Fidélité
-- Script simple et robuste qui évite tous les problèmes de syntaxe

-- ============================================================================
-- 1. DÉSACTIVER RLS TEMPORAIREMENT
-- ============================================================================

ALTER TABLE loyalty_tiers DISABLE ROW LEVEL SECURITY;
ALTER TABLE referrals DISABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
-- ============================================================================

-- Supprimer toutes les politiques pour client_loyalty_points
DROP POLICY IF EXISTS "client_loyalty_points_full_access" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_read_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_insert_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_update_policy" ON client_loyalty_points;
DROP POLICY IF EXISTS "client_loyalty_points_delete_policy" ON client_loyalty_points;

-- Supprimer toutes les politiques pour referrals
DROP POLICY IF EXISTS "referrals_full_access" ON referrals;
DROP POLICY IF EXISTS "referrals_read_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_insert_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_update_policy" ON referrals;
DROP POLICY IF EXISTS "referrals_delete_policy" ON referrals;

-- Supprimer toutes les politiques pour loyalty_points_history
DROP POLICY IF EXISTS "loyalty_points_history_full_access" ON loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_read_policy" ON loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_insert_policy" ON loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_update_policy" ON loyalty_points_history;
DROP POLICY IF EXISTS "loyalty_points_history_delete_policy" ON loyalty_points_history;

-- Supprimer toutes les politiques pour loyalty_rules
DROP POLICY IF EXISTS "loyalty_rules_full_access" ON loyalty_rules;
DROP POLICY IF EXISTS "loyalty_rules_read_policy" ON loyalty_rules;
DROP POLICY IF EXISTS "loyalty_rules_insert_policy" ON loyalty_rules;
DROP POLICY IF EXISTS "loyalty_rules_update_policy" ON loyalty_rules;
DROP POLICY IF EXISTS "loyalty_rules_delete_policy" ON loyalty_rules;

-- Supprimer toutes les politiques pour loyalty_tiers
DROP POLICY IF EXISTS "loyalty_tiers_read_policy" ON loyalty_tiers;

-- ============================================================================
-- 3. SUPPRIMER TOUTES LES CONTRAINTES EXISTANTES
-- ============================================================================

ALTER TABLE public.client_loyalty_points DROP CONSTRAINT IF EXISTS client_loyalty_points_user_id_fkey CASCADE;
ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS referrals_user_id_fkey CASCADE;
ALTER TABLE public.loyalty_points_history DROP CONSTRAINT IF EXISTS loyalty_points_history_user_id_fkey CASCADE;
ALTER TABLE public.loyalty_rules DROP CONSTRAINT IF EXISTS loyalty_rules_user_id_fkey CASCADE;

-- ============================================================================
-- 4. SUPPRIMER ET RECRÉER LES COLONNES USER_ID
-- ============================================================================

-- Supprimer et recréer la colonne user_id pour client_loyalty_points
ALTER TABLE public.client_loyalty_points DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.client_loyalty_points ADD COLUMN user_id UUID;

-- Supprimer et recréer la colonne user_id pour referrals
ALTER TABLE public.referrals DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.referrals ADD COLUMN user_id UUID;

-- Supprimer et recréer la colonne user_id pour loyalty_points_history
ALTER TABLE public.loyalty_points_history DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.loyalty_points_history ADD COLUMN user_id UUID;

-- Supprimer et recréer la colonne user_id pour loyalty_rules
ALTER TABLE public.loyalty_rules DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.loyalty_rules ADD COLUMN user_id UUID;

-- ============================================================================
-- 5. MISE À JOUR DES DONNÉES EXISTANTES
-- ============================================================================

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
-- 6. AJOUT DES CONTRAINTES ET INDEX
-- ============================================================================

-- Ajouter les contraintes de clé étrangère
ALTER TABLE public.client_loyalty_points 
ADD CONSTRAINT client_loyalty_points_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.referrals 
ADD CONSTRAINT referrals_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.loyalty_points_history 
ADD CONSTRAINT loyalty_points_history_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.loyalty_rules 
ADD CONSTRAINT loyalty_rules_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Rendre user_id obligatoire
ALTER TABLE public.client_loyalty_points ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.referrals ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.loyalty_points_history ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.loyalty_rules ALTER COLUMN user_id SET NOT NULL;

-- Créer les index
CREATE INDEX IF NOT EXISTS idx_client_loyalty_points_user_id ON public.client_loyalty_points(user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_user_id ON public.referrals(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_points_history_user_id ON public.loyalty_points_history(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_user_id ON public.loyalty_rules(user_id);

-- ============================================================================
-- 7. ACTIVATION DE RLS ET CRÉATION DES POLITIQUES
-- ============================================================================

-- Activer RLS sur toutes les tables
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules ENABLE ROW LEVEL SECURITY;

-- Politiques pour loyalty_tiers (lecture pour tous les utilisateurs authentifiés)
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
-- 8. VÉRIFICATION FINALE
-- ============================================================================

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

SELECT '✅ CORRECTION SIMPLE TERMINÉE - Isolation des données points de fidélité activée' as status;
