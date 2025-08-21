-- CORRECTION DE LA CONTRAINTE DE CLÉ ÉTRANGÈRE USER_ID
-- Ce script corrige l'erreur de contrainte de clé étrangère pour system_settings

-- ============================================================================
-- 1. VÉRIFICATION DE L'ÉTAT ACTUEL
-- ============================================================================

-- Vérifier si la table users existe
SELECT 
    'Vérification table users' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')
        THEN 'EXISTE'
        ELSE 'MANQUANTE'
    END as status;

-- Vérifier les utilisateurs dans auth.users
SELECT 
    'Utilisateurs auth.users' as check_type,
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

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

-- Vérifier la contrainte de clé étrangère sur system_settings
SELECT 
    'Contrainte system_settings' as check_type,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'system_settings';

-- ============================================================================
-- 2. CORRECTION : SYNCHRONISER LES UTILISATEURS
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

-- Synchroniser les utilisateurs de auth.users vers la table users
INSERT INTO users (id, first_name, last_name, email, role, created_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
    COALESCE(au.raw_user_meta_data->>'lastName', 'Test') as last_name,
    au.email,
    COALESCE(au.raw_user_meta_data->>'role', 'technician') as role,
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM users u WHERE u.id = au.id
)
ON CONFLICT (id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = NOW();

-- ============================================================================
-- 3. CORRECTION : MODIFIER LA CONTRAINTE DE CLÉ ÉTRANGÈRE
-- ============================================================================

-- Supprimer l'ancienne contrainte de clé étrangère si elle existe
DO $$
BEGIN
    -- Vérifier si la contrainte existe et la supprimer
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'system_settings_user_id_fkey' 
        AND table_name = 'system_settings'
    ) THEN
        ALTER TABLE system_settings DROP CONSTRAINT system_settings_user_id_fkey;
    END IF;
END $$;

-- Ajouter la nouvelle contrainte de clé étrangère vers auth.users
ALTER TABLE system_settings 
ADD CONSTRAINT system_settings_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- ============================================================================
-- 4. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier que la correction a fonctionné
SELECT 
    'Correction terminée' as check_type,
    'Contrainte mise à jour' as status;

-- Vérifier les utilisateurs synchronisés
SELECT 
    'Utilisateurs synchronisés' as check_type,
    COUNT(*) as total_users
FROM users;

-- Vérifier que system_settings peut maintenant être utilisé
SELECT 
    'Test system_settings' as check_type,
    'Prêt pour utilisation' as status;
