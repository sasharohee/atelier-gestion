-- SOLUTION IMMÉDIATE : Débloquer l'accès aux paramètres système
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer toutes les politiques RLS existantes
DROP POLICY IF EXISTS "Admins can view system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can update system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can create system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can delete system settings" ON system_settings;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON system_settings;
DROP POLICY IF EXISTS "Allow update for admins" ON system_settings;
DROP POLICY IF EXISTS "Allow insert for admins" ON system_settings;
DROP POLICY IF EXISTS "Allow delete for admins" ON system_settings;
DROP POLICY IF EXISTS "Temporary allow all" ON system_settings;

-- 2. Créer une politique simple qui permet tout
CREATE POLICY "Allow all operations" ON system_settings
  FOR ALL USING (true) WITH CHECK (true);

-- 3. Vérifier que ça fonctionne
SELECT 'Test de lecture' as info, COUNT(*) as count FROM system_settings;

-- 4. Vérifier les nouvelles politiques
SELECT 'Politiques créées' as info, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'system_settings';
