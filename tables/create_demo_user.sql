-- CRÉATION D'UN UTILISATEUR DE DÉMONSTRATION
-- Ce script crée un utilisateur de test pour l'application

-- ============================================================================
-- 1. CRÉATION DE L'UTILISATEUR DANS AUTH.USERS
-- ============================================================================

-- Note: Cette partie doit être exécutée manuellement dans l'interface Supabase
-- car nous ne pouvons pas créer directement des utilisateurs via SQL

/*
ÉTAPES MANUELLES DANS SUPABASE :

1. Aller dans Authentication > Users
2. Cliquer sur "Add User"
3. Remplir les informations :
   - Email: demo@atelier.fr
   - Password: Demo123!
   - User Metadata (JSON):
   {
     "firstName": "Demo",
     "lastName": "Utilisateur",
     "role": "admin"
   }
4. Cliquer sur "Create User"
*/

-- ============================================================================
-- 2. CRÉATION DE L'UTILISATEUR DANS LA TABLE USERS
-- ============================================================================

-- Créer la table users si elle n'existe pas
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'technician' CHECK (role IN ('admin', 'manager', 'technician')),
  avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insérer l'utilisateur de démonstration (remplacer USER_ID par l'ID réel)
-- Vous devez d'abord créer l'utilisateur dans Authentication > Users
-- puis récupérer son ID et le remplacer ci-dessous

/*
INSERT INTO users (id, first_name, last_name, email, role)
VALUES (
    'USER_ID_FROM_AUTH', -- Remplacez par l'ID réel de l'utilisateur créé
    'Demo',
    'Utilisateur',
    'demo@atelier.fr',
    'admin'
) ON CONFLICT (id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = NOW();
*/

-- ============================================================================
-- 3. VÉRIFICATION
-- ============================================================================

-- Vérifier les utilisateurs dans auth.users
SELECT 
    'Utilisateurs auth.users' as check_type,
    id,
    email,
    raw_user_meta_data,
    created_at
FROM auth.users
ORDER BY created_at DESC;

-- Vérifier les utilisateurs dans la table users
SELECT 
    'Utilisateurs table users' as check_type,
    id,
    first_name,
    last_name,
    email,
    role
FROM users
ORDER BY created_at DESC;

-- ============================================================================
-- 4. INFORMATIONS DE CONNEXION
-- ============================================================================

/*
INFORMATIONS DE CONNEXION POUR L'APPLICATION :

Email: demo@atelier.fr
Mot de passe: Demo123!

OU

Email: [votre-email-créé]
Mot de passe: [votre-mot-de-passe-créé]
*/
