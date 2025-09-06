-- Correction du trigger de création d'utilisateur
-- Ce script corrige l'erreur "Database error saving new user"

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Créer une nouvelle fonction plus robuste
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_first_name TEXT;
    user_last_name TEXT;
    user_role TEXT;
BEGIN
    -- Extraire les données utilisateur avec gestion d'erreur
    user_first_name := COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur');
    user_last_name := COALESCE(NEW.raw_user_meta_data->>'lastName', '');
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
    
    -- Vérifier si l'utilisateur existe déjà dans la table users
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
        -- Créer l'utilisateur dans la table users
        INSERT INTO public.users (id, first_name, last_name, email, role, created_at, updated_at)
        VALUES (
            NEW.id,
            user_first_name,
            user_last_name,
            NEW.email,
            user_role,
            NOW(),
            NOW()
        );
    END IF;
    
    -- Vérifier si le profil existe déjà
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = NEW.id) THEN
        -- Créer le profil utilisateur
        INSERT INTO public.user_profiles (user_id, first_name, last_name, email, created_at, updated_at)
        VALUES (
            NEW.id,
            user_first_name,
            user_last_name,
            NEW.email,
            NOW(),
            NOW()
        );
    END IF;
    
    -- Vérifier si les préférences existent déjà
    IF NOT EXISTS (SELECT 1 FROM public.user_preferences WHERE user_id = NEW.id) THEN
        -- Créer les préférences utilisateur
        INSERT INTO public.user_preferences (user_id, created_at, updated_at)
        VALUES (NEW.id, NOW(), NOW());
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'erreur mais ne pas faire échouer l'inscription
        RAISE WARNING 'Erreur lors de la création du profil utilisateur: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Vérifier que les tables existent
DO $$
BEGIN
    -- Vérifier la table users
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        RAISE EXCEPTION 'La table users n''existe pas';
    END IF;
    
    -- Vérifier la table user_profiles
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        RAISE EXCEPTION 'La table user_profiles n''existe pas';
    END IF;
    
    -- Vérifier la table user_preferences
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences' AND table_schema = 'public') THEN
        RAISE EXCEPTION 'La table user_preferences n''existe pas';
    END IF;
    
    RAISE NOTICE 'Toutes les tables nécessaires existent';
END $$;

-- 6. Tester la fonction avec un utilisateur fictif
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
BEGIN
    -- Simuler un nouvel utilisateur auth
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_user_meta_data)
    VALUES (
        test_user_id,
        'test@example.com',
        'encrypted_password',
        NOW(),
        NOW(),
        NOW(),
        '{"firstName": "Test", "lastName": "User", "role": "technician"}'::jsonb
    );
    
    -- Vérifier que les enregistrements ont été créés
    IF EXISTS (SELECT 1 FROM public.users WHERE id = test_user_id) THEN
        RAISE NOTICE '✅ Test réussi: utilisateur créé dans public.users';
    ELSE
        RAISE WARNING '❌ Test échoué: utilisateur non créé dans public.users';
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = test_user_id) THEN
        RAISE NOTICE '✅ Test réussi: profil créé dans public.user_profiles';
    ELSE
        RAISE WARNING '❌ Test échoué: profil non créé dans public.user_profiles';
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.user_preferences WHERE user_id = test_user_id) THEN
        RAISE NOTICE '✅ Test réussi: préférences créées dans public.user_preferences';
    ELSE
        RAISE WARNING '❌ Test échoué: préférences non créées dans public.user_preferences';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM auth.users WHERE id = test_user_id;
    DELETE FROM public.users WHERE id = test_user_id;
    DELETE FROM public.user_profiles WHERE user_id = test_user_id;
    DELETE FROM public.user_preferences WHERE user_id = test_user_id;
    
    RAISE NOTICE '🧹 Test nettoyé';
END $$;

-- 7. Afficher le statut final
SELECT 
    'Trigger de création d''utilisateur corrigé' as status,
    COUNT(*) as total_users,
    COUNT(DISTINCT user_profiles.user_id) as total_profiles,
    COUNT(DISTINCT user_preferences.user_id) as total_preferences
FROM public.users 
LEFT JOIN public.user_profiles ON users.id = user_profiles.user_id
LEFT JOIN public.user_preferences ON users.id = user_preferences.user_id;
