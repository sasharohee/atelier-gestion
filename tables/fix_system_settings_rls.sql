-- SCRIPT POUR CORRIGER LA TABLE system_settings
-- Ce script ajoute l'isolation par utilisateur à la table system_settings

-- 1. AJOUTER LA COLONNE user_id SI ELLE N'EXISTE PAS
ALTER TABLE public.system_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. ACTIVER RLS SUR LA TABLE
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- 3. SUPPRIMER LES ANCIENNES POLITIQUES SI ELLES EXISTENT
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.system_settings;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.system_settings;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.system_settings;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.system_settings;
DROP POLICY IF EXISTS "Users can view own settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can create own settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can delete own settings" ON public.system_settings;

-- 4. CRÉER LES NOUVELLES POLITIQUES RLS
CREATE POLICY "Users can view own settings" ON public.system_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own settings" ON public.system_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON public.system_settings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own settings" ON public.system_settings FOR DELETE USING (auth.uid() = user_id);

-- 5. CRÉER UN INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- 6. VÉRIFICATION
SELECT 
    'system_settings corrigée' as status,
    'RLS activé et politiques créées' as message;
