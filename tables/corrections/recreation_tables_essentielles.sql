-- Recréation des tables essentielles après nettoyage
-- Date: 2024-01-24

-- 1. CRÉER LA TABLE USERS SIMPLE

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

-- 2. CRÉER LA TABLE PENDING_SIGNUPS

CREATE TABLE pending_signups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    role TEXT DEFAULT 'technician',
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CRÉER LA TABLE CONFIRMATION_EMAILS

CREATE TABLE confirmation_emails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email TEXT NOT NULL UNIQUE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending',
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CRÉER LA TABLE SUBSCRIPTION_STATUS

CREATE TABLE subscription_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CRÉER LA TABLE SYSTEM_SETTINGS

CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type TEXT DEFAULT 'string',
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. CONFIGURER LES PERMISSIONS

-- Permissions pour users
GRANT ALL PRIVILEGES ON TABLE users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE users TO anon;
GRANT ALL PRIVILEGES ON TABLE users TO service_role;

-- Permissions pour pending_signups
GRANT ALL PRIVILEGES ON TABLE pending_signups TO authenticated;
GRANT ALL PRIVILEGES ON TABLE pending_signups TO anon;
GRANT ALL PRIVILEGES ON TABLE pending_signups TO service_role;

-- Permissions pour confirmation_emails
GRANT ALL PRIVILEGES ON TABLE confirmation_emails TO authenticated;
GRANT ALL PRIVILEGES ON TABLE confirmation_emails TO anon;
GRANT ALL PRIVILEGES ON TABLE confirmation_emails TO service_role;

-- Permissions pour subscription_status
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- Permissions pour system_settings
GRANT ALL PRIVILEGES ON TABLE system_settings TO authenticated;
GRANT ALL PRIVILEGES ON TABLE system_settings TO anon;
GRANT ALL PRIVILEGES ON TABLE system_settings TO service_role;

-- 7. DÉSACTIVER RLS TEMPORAIREMENT

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE pending_signups DISABLE ROW LEVEL SECURITY;
ALTER TABLE confirmation_emails DISABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings DISABLE ROW LEVEL SECURITY;

-- 8. CRÉER UN TRIGGER SIMPLE POUR LES NOUVEAUX UTILISATEURS

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

-- 9. CRÉER LE TRIGGER

CREATE TRIGGER on_auth_user_created_simple
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user_simple();

-- 10. VÉRIFIER LA CRÉATION

SELECT '=== TABLES CRÉÉES ===' as section;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('users', 'pending_signups', 'confirmation_emails', 'subscription_status', 'system_settings')
ORDER BY table_name;

-- 11. TESTER LA CRÉATION D'UN UTILISATEUR

SELECT '=== TEST DE CRÉATION ===' as section;
INSERT INTO pending_signups (email, first_name, last_name, role, status)
VALUES ('test@example.com', 'Test', 'User', 'technician', 'pending')
ON CONFLICT (email) DO UPDATE SET updated_at = NOW();

SELECT * FROM pending_signups WHERE email = 'test@example.com';

-- 12. NETTOYER LE TEST

DELETE FROM pending_signups WHERE email = 'test@example.com';

-- 13. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Table users créée' as statut1,
    '✅ Table pending_signups créée' as statut2,
    '✅ Table confirmation_emails créée' as statut3,
    '✅ Table subscription_status créée' as statut4,
    '✅ Table system_settings créée' as statut5,
    '✅ Permissions configurées' as statut6,
    '✅ Trigger simple créé' as statut7,
    '✅ Prêt pour création d''utilisateur dans Supabase Auth' as statut8;
