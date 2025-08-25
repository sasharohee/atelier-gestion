-- Correction urgente pour la colonne is_locked manquante
-- Ce script résout l'erreur 42804 dans get_user_lock_status

-- 1. Ajouter la colonne is_locked à user_profiles si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'is_locked'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN is_locked BOOLEAN DEFAULT true;
        RAISE NOTICE 'Colonne is_locked ajoutée à user_profiles';
    ELSE
        RAISE NOTICE 'Colonne is_locked existe déjà';
    END IF;
END $$;

-- 2. Mettre à jour tous les utilisateurs existants pour avoir is_locked = true par défaut
UPDATE public.user_profiles 
SET is_locked = true 
WHERE is_locked IS NULL;

-- 3. Créer un index pour optimiser les requêtes sur is_locked
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_locked ON public.user_profiles(is_locked);

-- 4. Recréer la fonction get_user_lock_status avec les bons types
CREATE OR REPLACE FUNCTION public.get_user_lock_status(user_uuid UUID DEFAULT auth.uid())
RETURNS TABLE(
    user_id UUID,
    is_locked BOOLEAN,
    email TEXT,
    first_name TEXT,
    last_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        COALESCE(up.is_locked, true) as is_locked,
        COALESCE(up.email, u.email) as email,
        COALESCE(up.first_name, u.first_name) as first_name,
        COALESCE(up.last_name, u.last_name) as last_name
    FROM public.user_profiles up
    FULL OUTER JOIN public.users u ON up.user_id = u.id
    WHERE up.user_id = user_uuid OR u.id = user_uuid;
    
    -- Si aucun résultat, retourner un utilisateur verrouillé par défaut
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            user_uuid as user_id,
            true as is_locked,
            '' as email,
            'Utilisateur' as first_name,
            'Nouveau' as last_name;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Recréer la fonction is_user_locked
CREATE OR REPLACE FUNCTION public.is_user_locked(user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
DECLARE
    locked_status BOOLEAN;
BEGIN
    SELECT is_locked INTO locked_status
    FROM public.user_profiles
    WHERE user_id = user_uuid;
    
    RETURN COALESCE(locked_status, true); -- Par défaut verrouillé si pas trouvé
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Recréer la fonction unlock_user
CREATE OR REPLACE FUNCTION public.unlock_user(target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_role TEXT;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT role INTO current_user_role
    FROM public.users
    WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RAISE EXCEPTION 'Accès refusé: seuls les administrateurs peuvent déverrouiller des utilisateurs';
    END IF;
    
    -- Déverrouiller l'utilisateur
    UPDATE public.user_profiles
    SET is_locked = false, updated_at = NOW()
    WHERE user_id = target_user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Recréer la fonction lock_user
CREATE OR REPLACE FUNCTION public.lock_user(target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_role TEXT;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT role INTO current_user_role
    FROM public.users
    WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RAISE EXCEPTION 'Accès refusé: seuls les administrateurs peuvent verrouiller des utilisateurs';
    END IF;
    
    -- Verrouiller l'utilisateur
    UPDATE public.user_profiles
    SET is_locked = true, updated_at = NOW()
    WHERE user_id = target_user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Recréer la fonction get_subscription_stats
CREATE OR REPLACE FUNCTION public.get_subscription_stats()
RETURNS TABLE(
    total_users INTEGER,
    locked_users INTEGER,
    unlocked_users INTEGER,
    admin_users INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_users,
        COUNT(*) FILTER (WHERE COALESCE(up.is_locked, true) = true)::INTEGER as locked_users,
        COUNT(*) FILTER (WHERE COALESCE(up.is_locked, true) = false)::INTEGER as unlocked_users,
        COUNT(*) FILTER (WHERE u.role = 'admin')::INTEGER as admin_users
    FROM public.users u
    LEFT JOIN public.user_profiles up ON u.id = up.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Accorder les permissions
GRANT EXECUTE ON FUNCTION public.is_user_locked(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_lock_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unlock_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lock_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_subscription_stats() TO authenticated;

-- 10. Vérification finale
DO $$
BEGIN
    -- Vérifier que la colonne is_locked existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'is_locked'
    ) THEN
        RAISE NOTICE '✅ Colonne is_locked existe dans user_profiles';
    ELSE
        RAISE NOTICE '❌ Colonne is_locked manquante dans user_profiles';
    END IF;
    
    -- Vérifier que les fonctions existent
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_lock_status') THEN
        RAISE NOTICE '✅ Fonction get_user_lock_status créée';
    ELSE
        RAISE NOTICE '❌ Fonction get_user_lock_status manquante';
    END IF;
END $$;
