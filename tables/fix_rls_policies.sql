-- Script pour corriger les politiques RLS de system_settings
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les politiques actuelles
SELECT 'Politiques actuelles' as info, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'system_settings';

-- 2. Supprimer les politiques existantes qui peuvent être trop restrictives
DROP POLICY IF EXISTS "Admins can view system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can update system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can create system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can delete system settings" ON system_settings;

-- 3. Créer des politiques plus permissives pour les tests
-- Politique pour permettre la lecture à tous les utilisateurs connectés
CREATE POLICY "Allow read for authenticated users" ON system_settings
  FOR SELECT USING (auth.role() = 'authenticated');

-- Politique pour permettre la modification aux administrateurs
CREATE POLICY "Allow update for admins" ON system_settings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre l'insertion aux administrateurs
CREATE POLICY "Allow insert for admins" ON system_settings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre la suppression aux administrateurs
CREATE POLICY "Allow delete for admins" ON system_settings
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 4. Alternative : Politique temporaire pour tous les utilisateurs (pour les tests)
-- DÉCOMMENTER LA LIGNE SUIVANTE SI LES POLITIQUES CI-DESSUS NE FONCTIONNENT PAS
-- CREATE POLICY "Temporary allow all" ON system_settings FOR ALL USING (true);

-- 5. Vérifier les nouvelles politiques
SELECT 'Nouvelles politiques' as info, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'system_settings';

-- 6. Test de lecture (doit fonctionner maintenant)
SELECT 'Test de lecture' as info, COUNT(*) as count FROM system_settings;

-- 7. Vérifier que l'utilisateur actuel est bien administrateur
SELECT 'Utilisateur actuel' as info, 
       auth.uid() as user_id,
       u.email,
       u.role
FROM users u 
WHERE u.id = auth.uid();
