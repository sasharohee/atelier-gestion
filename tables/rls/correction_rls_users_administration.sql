-- Correction des politiques RLS pour la table users
-- Problème : L'utilisateur actuel ne peut pas accéder à ses propres données dans la page Administration

SELECT '=== CORRECTION DES POLITIQUES RLS POUR LA TABLE USERS ===' as status;

-- 1. Vérifier l'état actuel des politiques RLS
SELECT 'Vérification des politiques RLS actuelles...' as status;

SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users';

-- 2. Supprimer les anciennes politiques RLS problématiques
SELECT 'Suppression des anciennes politiques RLS...' as status;

DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can delete their own data" ON users;
DROP POLICY IF EXISTS "Users can view users they created" ON users;
DROP POLICY IF EXISTS "Users can update users they created" ON users;
DROP POLICY IF EXISTS "Users can delete users they created" ON users;

-- 3. Créer une fonction d'autorisation pour les utilisateurs
SELECT 'Création de la fonction d''autorisation...' as status;

CREATE OR REPLACE FUNCTION can_access_user_data(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- L'utilisateur peut toujours accéder à ses propres données
  IF user_id = auth.uid() THEN
    RETURN TRUE;
  END IF;
  
  -- L'utilisateur peut accéder aux données des utilisateurs qu'il a créés
  IF EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id 
    AND created_by = auth.uid()
  ) THEN
    RETURN TRUE;
  END IF;
  
  -- L'utilisateur peut voir tous les utilisateurs s'il est admin
  IF EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Activer RLS sur la table users
SELECT 'Activation de RLS sur la table users...' as status;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 5. Créer les nouvelles politiques RLS
SELECT 'Création des nouvelles politiques RLS...' as status;

-- Politique pour SELECT (lecture)
CREATE POLICY "Users can view accessible data" ON users
FOR SELECT USING (
  can_access_user_data(id)
);

-- Politique pour INSERT (création)
CREATE POLICY "Users can create new users" ON users
FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);

-- Politique pour UPDATE (modification)
CREATE POLICY "Users can update accessible data" ON users
FOR UPDATE USING (
  can_access_user_data(id)
) WITH CHECK (
  can_access_user_data(id)
);

-- Politique pour DELETE (suppression)
CREATE POLICY "Users can delete accessible data" ON users
FOR DELETE USING (
  can_access_user_data(id)
);

-- 6. Vérifier les nouvelles politiques
SELECT 'Vérification des nouvelles politiques RLS...' as status;

SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- 7. Test de la fonction d'autorisation
SELECT 'Test de la fonction d''autorisation...' as status;

-- Note: Ce test ne fonctionnera que si un utilisateur est connecté
-- SELECT can_access_user_data(auth.uid()) as can_access_own_data;

SELECT '=== CORRECTION TERMINÉE ===' as status;
SELECT 'Les politiques RLS ont été corrigées pour permettre l''accès aux données utilisateur dans la page Administration.' as message;
