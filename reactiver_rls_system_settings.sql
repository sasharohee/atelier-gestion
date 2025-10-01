-- =====================================================
-- RÉACTIVATION DES POLITIQUES RLS DE LA TABLE SYSTEM_SETTINGS
-- =====================================================

-- ÉTAPE 1: Activer RLS sur la table system_settings
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- ÉTAPE 2: Supprimer les anciennes politiques (si elles existent)
DROP POLICY IF EXISTS "Admins can insert system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Admins can update system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated users can view system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_select_policy" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_update_policy" ON public.system_settings;

-- ÉTAPE 3: Créer les 5 politiques RLS

-- 1. Politique: Admins can insert system_settings
CREATE POLICY "Admins can insert system_settings" ON public.system_settings
    FOR INSERT
    TO public
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 2. Politique: Admins can update system_settings
CREATE POLICY "Admins can update system_settings" ON public.system_settings
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

-- 3. Politique: Authenticated users can view system_settings
CREATE POLICY "Authenticated users can view system_settings" ON public.system_settings
    FOR SELECT
    TO public
    USING (auth.uid() IS NOT NULL);

-- 4. Politique: system_settings_select_policy
CREATE POLICY "system_settings_select_policy" ON public.system_settings
    FOR SELECT
    TO public
    USING (
        auth.uid() IS NOT NULL OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'technician')
        )
    );

-- 5. Politique: system_settings_update_policy
CREATE POLICY "system_settings_update_policy" ON public.system_settings
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

-- ÉTAPE 4: Vérification
SELECT 'RLS activé sur system_settings' as status, 
       (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'system_settings') as nb_policies;

-- Afficher les politiques créées
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'system_settings' 
ORDER BY policyname;

