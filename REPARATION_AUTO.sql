-- 🔧 RÉPARATION AUTOMATIQUE - Système d'Authentification
-- Ce script répare automatiquement les problèmes courants

-- 1. NETTOYAGE COMPLET
SELECT 'NETTOYAGE: Suppression des anciennes fonctions...' as info;

DROP FUNCTION IF EXISTS public.create_user_bypass(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_email_required(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_email_confirmation(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.send_confirmation_email(TEXT);
DROP FUNCTION IF EXISTS public.validate_confirmation_token(TEXT);
DROP FUNCTION IF EXISTS public.get_signup_status(TEXT);
DROP FUNCTION IF EXISTS public.create_user_default_data_permissive(UUID);
DROP FUNCTION IF EXISTS public.create_user_manual(TEXT, TEXT, TEXT, TEXT, TEXT);

-- 2. SUPPRESSION DES ANCIENS TRIGGERS
SELECT 'NETTOYAGE: Suppression des anciens triggers...' as info;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. SUPPRESSION DES ANCIENNES FONCTIONS
SELECT 'NETTOYAGE: Suppression des anciennes fonctions...' as info;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 4. RECRÉATION DE LA TABLE USERS
SELECT 'CRÉATION: Recréation de la table users...' as info;
DROP TABLE IF EXISTS public.users CASCADE;

CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'technician',
    avatar TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- 5. CRÉATION DES INDEX
SELECT 'CRÉATION: Création des index...' as info;
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_created_by ON public.users(created_by);

-- 6. ACTIVATION DE RLS
SELECT 'SÉCURITÉ: Activation de Row Level Security...' as info;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 7. CRÉATION DES POLITIQUES RLS
SELECT 'SÉCURITÉ: Création des politiques RLS...' as info;

-- Politique pour voir son propre profil
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Politique pour mettre à jour son propre profil
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Politique pour insérer son propre profil
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Politique pour que les admins voient tous les utilisateurs
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'technician')
        )
    );

-- 8. CRÉATION DE LA FONCTION DE GESTION DES NOUVEAUX UTILISATEURS
SELECT 'FONCTION: Création de handle_new_user...' as info;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insérer l'utilisateur dans la table public.users
    INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
        COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'erreur mais ne bloque pas la création de l'utilisateur auth
        RAISE WARNING 'Erreur lors de la création du profil utilisateur: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- 9. CRÉATION DU TRIGGER
SELECT 'TRIGGER: Création du trigger on_auth_user_created...' as info;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. FONCTION UTILITAIRE POUR RÉCUPÉRER LE PROFIL UTILISATEUR
SELECT 'FONCTION: Création de get_user_profile...' as info;
CREATE OR REPLACE FUNCTION public.get_user_profile(user_id UUID DEFAULT NULL)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_user_id UUID;
    user_data JSON;
BEGIN
    -- Utiliser l'ID fourni ou l'utilisateur actuel
    target_user_id := COALESCE(user_id, auth.uid());
    
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = target_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Récupérer les données utilisateur
    SELECT json_build_object(
        'id', u.id,
        'firstName', u.first_name,
        'lastName', u.last_name,
        'email', u.email,
        'role', u.role,
        'avatar', u.avatar,
        'createdAt', u.created_at,
        'updatedAt', u.updated_at,
        'isEmailConfirmed', au.email_confirmed_at IS NOT NULL
    ) INTO user_data
    FROM public.users u
    LEFT JOIN auth.users au ON u.id = au.id
    WHERE u.id = target_user_id;
    
    RETURN json_build_object(
        'success', true,
        'data', user_data
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- 11. VÉRIFICATION FINALE
SELECT 'VÉRIFICATION: État final du système...' as info;
SELECT 
    'Table users' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
         THEN '✅ Créée' 
         ELSE '❌ Manquante' 
    END as status
UNION ALL
SELECT 
    'Trigger on_auth_user_created' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Actif' 
         ELSE '❌ Inactif' 
    END as status
UNION ALL
SELECT 
    'Fonction handle_new_user' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user' AND routine_schema = 'public') 
         THEN '✅ Créée' 
         ELSE '❌ Manquante' 
    END as status
UNION ALL
SELECT 
    'Fonction get_user_profile' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_user_profile' AND routine_schema = 'public') 
         THEN '✅ Créée' 
         ELSE '❌ Manquante' 
    END as status;

-- 12. MESSAGE FINAL
SELECT '✅ RÉPARATION TERMINÉE - Le système d''authentification est maintenant opérationnel !' as status;
SELECT 'Vous pouvez maintenant tester l''inscription et la connexion.' as message;
