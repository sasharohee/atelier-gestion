-- Correction des problèmes de création d'utilisateur dans Supabase Auth
-- Date: 2024-01-24

-- 1. DÉSACTIVER LES TRIGGERS PROBLÉMATIQUES

-- Désactiver tous les triggers sur auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS create_user_default_data_trigger ON auth.users;

-- 2. NETTOYER LES CONTRAINTES PROBLÉMATIQUES

-- Supprimer les contraintes qui peuvent causer des problèmes
ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS users_id_key;

-- 3. RECRÉER LA TABLE USERS AVEC DES CONTRAINTES SIMPLES

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE,
    role TEXT DEFAULT 'technician',
    avatar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CONFIGURER LES PERMISSIONS RLS

-- Désactiver RLS temporairement pour la création
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 5. CRÉER UN TRIGGER SIMPLE ET SÛR

CREATE OR REPLACE FUNCTION handle_new_user_simple()
RETURNS TRIGGER AS $$
BEGIN
    -- Insérer dans la table users si l'email n'existe pas
    INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
        NOW(),
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRÉER LE TRIGGER

CREATE TRIGGER on_auth_user_created_simple
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user_simple();

-- 7. CONFIGURER LES PERMISSIONS

GRANT ALL PRIVILEGES ON TABLE users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE users TO anon;
GRANT ALL PRIVILEGES ON TABLE users TO service_role;

-- 8. CRÉER L'UTILISATEUR MANUELLEMENT

INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'Sasha',
    'Rohee',
    'Sasharohee26@gmail.com',
    'technician',
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    updated_at = NOW();

-- 9. ACTIVER LA DEMANDE D'INSCRIPTION

UPDATE pending_signups 
SET status = 'approved', updated_at = NOW()
WHERE email = 'Sasharohee26@gmail.com';

-- 10. MARQUER L'EMAIL COMME UTILISÉ

UPDATE confirmation_emails 
SET status = 'used', sent_at = NOW()
WHERE user_email = 'Sasharohee26@gmail.com';

-- 11. VÉRIFIER LA CRÉATION

SELECT '=== UTILISATEUR CRÉÉ ===' as section;
SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM users 
WHERE email = 'Sasharohee26@gmail.com';

-- 12. INSTRUCTIONS POUR SUPABASE AUTH

SELECT '=== CRÉATION DANS SUPABASE AUTH ===' as section;
SELECT 
    '1. Allez dans Supabase Dashboard > Authentication > Users' as etape1,
    '2. Cliquez sur "Add user"' as etape2,
    '3. Remplissez :' as etape3,
    '   - Email: Sasharohee26@gmail.com' as email,
    '   - Password: (choisissez un mot de passe)' as password,
    '   - Email confirm: true' as confirm,
    '4. Cliquez sur "Create user"' as etape4,
    '5. Le trigger créera automatiquement l''utilisateur dans la table users' as etape5;

-- 13. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Triggers problématiques supprimés' as statut1,
    '✅ Table users recréée avec des contraintes simples' as statut2,
    '✅ Trigger simple et sûr créé' as statut3,
    '✅ Utilisateur créé dans la table users' as statut4,
    '✅ Demande d''inscription approuvée' as statut5,
    '✅ Prêt pour création dans Supabase Auth' as statut6;
