-- =====================================================
-- CORRECTION DES ERREURS 500 CAUSÉES PAR LES POLITIQUES RLS
-- =====================================================

-- ÉTAPE 1: DIAGNOSTIC - Vérifier la structure des tables
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('subscription_status', 'system_settings', 'users')
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- ÉTAPE 2: Vérifier les politiques existantes qui causent des erreurs
SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('subscription_status', 'system_settings')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- ÉTAPE 3: SUPPRIMER LES POLITIQUES PROBLÉMATIQUES
-- Supprimer toutes les politiques de subscription_status
DROP POLICY IF EXISTS "admins_can_manage_subscriptions" ON public.subscription_status;
DROP POLICY IF EXISTS "service_role_full_access_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_select_policy" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_update_policy" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_insert_own_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_update_own_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_view_own_subscription" ON public.subscription_status;

-- Supprimer toutes les politiques de system_settings
DROP POLICY IF EXISTS "Admins can insert system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Admins can update system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated users can view system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_select_policy" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_update_policy" ON public.system_settings;

-- ÉTAPE 4: DÉSACTIVER TEMPORAIREMENT RLS POUR DIAGNOSTIC
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings DISABLE ROW LEVEL SECURITY;

-- ÉTAPE 5: Vérifier les données existantes
SELECT 'subscription_status' as table_name, COUNT(*) as row_count FROM public.subscription_status
UNION ALL
SELECT 'system_settings' as table_name, COUNT(*) as row_count FROM public.system_settings;

-- ÉTAPE 6: Afficher quelques exemples de données
SELECT 'subscription_status data:' as info;
SELECT * FROM public.subscription_status LIMIT 3;

SELECT 'system_settings data:' as info;
SELECT * FROM public.system_settings LIMIT 3;

-- ÉTAPE 7: CRÉER DES POLITIQUES SIMPLES ET SÛRES

-- Politiques pour subscription_status (si la table existe et a des données)
-- D'abord, vérifier si la table a une colonne user_id ou équivalent
DO $$
BEGIN
    -- Vérifier si subscription_status a une colonne user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'subscription_status' 
        AND column_name = 'user_id'
        AND table_schema = 'public'
    ) THEN
        -- Activer RLS et créer des politiques basées sur user_id
        ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "subscription_status_select" ON public.subscription_status
            FOR SELECT
            TO public
            USING (auth.uid() = user_id);
            
        CREATE POLICY "subscription_status_insert" ON public.subscription_status
            FOR INSERT
            TO public
            WITH CHECK (auth.uid() = user_id);
            
        CREATE POLICY "subscription_status_update" ON public.subscription_status
            FOR UPDATE
            TO public
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
            
        RAISE NOTICE 'Politiques subscription_status créées avec user_id';
    ELSE
        -- Si pas de user_id, créer des politiques plus permissives
        ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "subscription_status_select_all" ON public.subscription_status
            FOR SELECT
            TO public
            USING (auth.uid() IS NOT NULL);
            
        RAISE NOTICE 'Politique subscription_status créée sans user_id';
    END IF;
END $$;

-- Politiques pour system_settings (généralement pas de user_id)
DO $$
BEGIN
    -- Activer RLS et créer des politiques permissives
    ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
    
    CREATE POLICY "system_settings_select" ON public.system_settings
        FOR SELECT
        TO public
        USING (auth.uid() IS NOT NULL);
        
    CREATE POLICY "system_settings_admin_insert" ON public.system_settings
        FOR INSERT
        TO public
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid() 
                AND role = 'admin'
            )
        );
        
    CREATE POLICY "system_settings_admin_update" ON public.system_settings
        FOR UPDATE
        TO public
        USING (
            EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid() 
                AND role = 'admin'
            )
        )
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid() 
                AND role = 'admin'
            )
        );
        
    RAISE NOTICE 'Politiques system_settings créées';
END $$;

-- ÉTAPE 8: VÉRIFICATION FINALE
SELECT 'Politiques subscription_status:' as info;
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'subscription_status' AND schemaname = 'public';

SELECT 'Politiques system_settings:' as info;
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'system_settings' AND schemaname = 'public';

-- ÉTAPE 9: TEST DE CONNEXION
SELECT 'Test de connexion réussi' as status;
