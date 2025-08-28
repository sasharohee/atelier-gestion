-- 🔧 CORRECTION ULTIME - Isolation Points de Fidélité
-- Script qui gère tous les cas de dépendances et résout définitivement le problème

-- ============================================================================
-- 1. DIAGNOSTIC COMPLET
-- ============================================================================

SELECT '=== DIAGNOSTIC COMPLET ===' as section;

-- Vérifier toutes les politiques existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
ORDER BY tablename, policyname;

-- Vérifier toutes les contraintes existantes
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public'
    AND tc.table_name IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
    AND kcu.column_name = 'user_id'
ORDER BY tc.table_name;

-- ============================================================================
-- 2. NETTOYAGE COMPLET - SUPPRIMER TOUT
-- ============================================================================

SELECT '=== NETTOYAGE COMPLET ===' as section;

-- Désactiver RLS temporairement pour pouvoir nettoyer
ALTER TABLE loyalty_tiers DISABLE ROW LEVEL SECURITY;
ALTER TABLE referrals DISABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules DISABLE ROW LEVEL SECURITY;

-- Supprimer TOUTES les politiques existantes (avec wildcard)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
            AND tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON %I.%I', 
            policy_record.policyname, 
            policy_record.schemaname, 
            policy_record.tablename);
        RAISE NOTICE 'Politique supprimée: %s sur %s.%s', 
            policy_record.policyname, 
            policy_record.schemaname, 
            policy_record.tablename;
    END LOOP;
END $$;

-- Supprimer TOUTES les contraintes existantes
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
            AND tc.table_name IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
            AND kcu.column_name = 'user_id'
            AND tc.constraint_type = 'FOREIGN KEY'
    LOOP
        EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I CASCADE', 
            constraint_record.table_name, 
            constraint_record.constraint_name);
        RAISE NOTICE 'Contrainte supprimée: %s sur %s', 
            constraint_record.constraint_name, 
            constraint_record.table_name;
    END LOOP;
END $$;

-- ============================================================================
-- 3. RECRÉATION PROPRE DES COLONNES USER_ID
-- ============================================================================

SELECT '=== RECRÉATION DES COLONNES USER_ID ===' as section;

-- Supprimer et recréer la colonne user_id pour client_loyalty_points
ALTER TABLE public.client_loyalty_points DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.client_loyalty_points ADD COLUMN user_id UUID;
SELECT 'Colonne user_id recréée pour client_loyalty_points' as status;

-- Supprimer et recréer la colonne user_id pour referrals
ALTER TABLE public.referrals DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.referrals ADD COLUMN user_id UUID;
SELECT 'Colonne user_id recréée pour referrals' as status;

-- Supprimer et recréer la colonne user_id pour loyalty_points_history
ALTER TABLE public.loyalty_points_history DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.loyalty_points_history ADD COLUMN user_id UUID;
SELECT 'Colonne user_id recréée pour loyalty_points_history' as status;

-- Supprimer et recréer la colonne user_id pour loyalty_rules
ALTER TABLE public.loyalty_rules DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.loyalty_rules ADD COLUMN user_id UUID;
SELECT 'Colonne user_id recréée pour loyalty_rules' as status;

-- ============================================================================
-- 4. MISE À JOUR DES DONNÉES EXISTANTES
-- ============================================================================

SELECT '=== MISE À JOUR DES DONNÉES ===' as section;

-- Mettre à jour client_loyalty_points avec le user_id du client
UPDATE public.client_loyalty_points 
SET user_id = (
    SELECT c.user_id 
    FROM public.clients c 
    WHERE c.id = client_loyalty_points.client_id
)
WHERE user_id IS NULL;
SELECT 'Données client_loyalty_points mises à jour' as status;

-- Mettre à jour referrals avec le user_id du client parrain
UPDATE public.referrals 
SET user_id = (
    SELECT c.user_id 
    FROM public.clients c 
    WHERE c.id = referrals.referrer_client_id
)
WHERE user_id IS NULL;
SELECT 'Données referrals mises à jour' as status;

-- Mettre à jour loyalty_points_history avec le user_id du client
UPDATE public.loyalty_points_history 
SET user_id = (
    SELECT c.user_id 
    FROM public.clients c 
    WHERE c.id = loyalty_points_history.client_id
)
WHERE user_id IS NULL;
SELECT 'Données loyalty_points_history mises à jour' as status;

-- Mettre à jour loyalty_rules avec le premier utilisateur admin
UPDATE public.loyalty_rules 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL;
SELECT 'Données loyalty_rules mises à jour' as status;

-- ============================================================================
-- 5. AJOUT DES CONTRAINTES ET INDEX
-- ============================================================================

SELECT '=== AJOUT DES CONTRAINTES ET INDEX ===' as section;

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
-- 6. ACTIVATION DE RLS ET CRÉATION DES POLITIQUES
-- ============================================================================

SELECT '=== ACTIVATION RLS ET POLITIQUES ===' as section;

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
-- 7. VÉRIFICATION FINALE
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

-- Vérifier les contraintes de clé étrangère
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON rc.unique_constraint_name = ccu.constraint_name
  AND rc.unique_constraint_schema = ccu.table_schema
WHERE tc.table_name IN ('client_loyalty_points', 'referrals', 'loyalty_points_history', 'loyalty_rules')
  AND kcu.column_name = 'user_id'
  AND tc.constraint_type = 'FOREIGN KEY';

-- Vérifier les politiques RLS
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

SELECT '✅ CORRECTION ULTIME TERMINÉE - Isolation des données points de fidélité activée' as status;
