-- Créer l'utilisateur s'il n'existe pas
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier d'abord si l'utilisateur existe
DO $$
DECLARE
    user_exists BOOLEAN;
    user_id UUID;
BEGIN
    -- Vérifier si l'utilisateur existe
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = 'sasharohee@icloud.com'
    ) INTO user_exists;
    
    IF user_exists THEN
        RAISE NOTICE 'Utilisateur deja existant';
        -- Récupérer l'ID de l'utilisateur
        SELECT id INTO user_id FROM auth.users WHERE email = 'sasharohee@icloud.com';
        RAISE NOTICE 'ID utilisateur: %', user_id;
        
        -- Vérifier la synchronisation avec public.users
        IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = user_id) THEN
            INSERT INTO public.users (id, email, created_at, updated_at)
            VALUES (user_id, 'sasharohee@icloud.com', NOW(), NOW());
            RAISE NOTICE 'Utilisateur synchronise avec public.users';
        ELSE
            RAISE NOTICE 'Utilisateur deja synchronise';
        END IF;
        
    ELSE
        RAISE NOTICE 'Utilisateur non trouve - creation necessaire via interface Supabase';
    END IF;
END $$;




