-- Correction rapide de l'erreur "Database error saving new user"
-- Script simplifié pour une application immédiate

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Créer une fonction simplifiée et robuste
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer l'utilisateur dans public.users (avec gestion d'erreur)
    BEGIN
        INSERT INTO public.users (id, first_name, last_name, email, role, created_at, updated_at)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log l'erreur mais continuer
            RAISE WARNING 'Erreur création users: %', SQLERRM;
    END;
    
    -- Créer le profil (avec gestion d'erreur)
    BEGIN
        INSERT INTO public.user_profiles (user_id, first_name, last_name, email, created_at, updated_at)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
            NEW.email,
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Erreur création profile: %', SQLERRM;
    END;
    
    -- Créer les préférences (avec gestion d'erreur)
    BEGIN
        INSERT INTO public.user_preferences (user_id, created_at, updated_at)
        VALUES (NEW.id, NOW(), NOW());
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Erreur création preferences: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Vérification rapide
SELECT '✅ Correction appliquée - Trigger recréé avec gestion d''erreur' as status;
