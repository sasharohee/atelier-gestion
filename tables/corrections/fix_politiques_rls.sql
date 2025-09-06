-- FIX POLITIQUES RLS
-- Script pour corriger les politiques RLS de la table system_settings

-- 1. S'ASSURER QUE LA COLONNE USER_ID EXISTE
ALTER TABLE public.system_settings 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- 2. CRÉER L'INDEX
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- 3. SUPPRIMER LES ANCIENNES POLITIQUES
DROP POLICY IF EXISTS "system_settings_access" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_user_isolation" ON public.system_settings;

-- 4. CRÉER LA NOUVELLE POLITIQUE
CREATE POLICY "system_settings_user_isolation" ON public.system_settings
  FOR ALL USING (auth.uid() = user_id);

-- 5. AJOUTER LA CONTRAINTE UNIQUE
ALTER TABLE public.system_settings 
DROP CONSTRAINT IF EXISTS unique_user_key;

ALTER TABLE public.system_settings 
ADD CONSTRAINT unique_user_key UNIQUE (user_id, key);

-- 6. VÉRIFICATION
SELECT 
    'Politiques RLS corrigées' as status,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE tablename = 'system_settings' 
AND schemaname = 'public';
