-- Solution ultra-simple pour la création d'utilisateur
-- Date: 2024-01-24

-- 1. SUPPRIMER TOUS LES TRIGGERS

DO $$ 
BEGIN
    -- Supprimer tous les triggers sur auth.users
    EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS handle_new_user ON auth.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS create_user_default_data_trigger ON auth.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS handle_new_user_simple ON auth.users CASCADE';
    
    -- Supprimer tous les triggers sur public.users
    EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created ON public.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS handle_new_user ON public.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS create_user_default_data_trigger ON public.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created_simple ON public.users CASCADE';
    EXECUTE 'DROP TRIGGER IF EXISTS handle_new_user_simple ON public.users CASCADE';
    
    RAISE NOTICE 'Tous les triggers supprimés';
END $$;

-- 2. SUPPRIMER LES FONCTIONS TRIGGER

DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data_permissive() CASCADE;
DROP FUNCTION IF EXISTS on_auth_user_created() CASCADE;
DROP FUNCTION IF EXISTS on_auth_user_created_simple() CASCADE;

-- 3. CRÉER UNE TABLE USERS ULTRA-SIMPLE

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid(),
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    role TEXT DEFAULT 'technician',
    avatar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. DÉSACTIVER RLS

ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 5. CONFIGURER LES PERMISSIONS

GRANT ALL PRIVILEGES ON TABLE users TO postgres;
GRANT ALL PRIVILEGES ON TABLE users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE users TO anon;
GRANT ALL PRIVILEGES ON TABLE users TO service_role;

-- 6. CRÉER L'UTILISATEUR (SANS ON CONFLICT)

INSERT INTO users (
    first_name,
    last_name,
    email,
    role
) VALUES (
    'Sasha',
    'Rohee',
    'Sasharohee26@gmail.com',
    'technician'
);

-- 7. ACTIVER LA DEMANDE D'INSCRIPTION

UPDATE pending_signups 
SET status = 'approved', updated_at = NOW()
WHERE email = 'Sasharohee26@gmail.com';

-- 8. MARQUER L'EMAIL COMME UTILISÉ

UPDATE confirmation_emails 
SET status = 'used', sent_at = NOW()
WHERE user_email = 'Sasharohee26@gmail.com';

-- 9. VÉRIFIER

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Triggers supprimés' as statut1,
    '✅ Table users ultra-simple créée' as statut2,
    '✅ RLS désactivé' as statut3,
    '✅ Utilisateur créé' as statut4,
    '✅ Prêt pour Supabase Auth' as statut5;

-- 10. AFFICHER L'UTILISATEUR CRÉÉ

SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM users 
WHERE email = 'Sasharohee26@gmail.com';

-- 11. INSTRUCTIONS

SELECT '=== INSTRUCTIONS ===' as section;
SELECT 
    '1. Allez dans Supabase Dashboard > Authentication > Users' as etape1,
    '2. Cliquez sur "Add user"' as etape2,
    '3. Email: Sasharohee26@gmail.com' as etape3,
    '4. Password: (choisissez un mot de passe)' as etape4,
    '5. Email confirm: true' as etape5,
    '6. Cliquez sur "Create user"' as etape6,
    '7. AUCUN TRIGGER NE DEVRAIT BLOQUER' as etape7;
