-- =====================================================
-- CORRECTION DE LA COLONNE CREATED_BY DANS LOYALTY_POINTS_HISTORY
-- =====================================================
-- Problème: auth.uid() peut retourner NULL, causant une erreur de contrainte
-- =====================================================

-- 1. Créer l'utilisateur système s'il n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = '00000000-0000-0000-0000-000000000000') THEN
        INSERT INTO auth.users (id, email, created_at, updated_at)
        VALUES ('00000000-0000-0000-0000-000000000000', 'system@atelier.com', NOW(), NOW());
        RAISE NOTICE '✅ Utilisateur système créé';
    ELSE
        RAISE NOTICE 'ℹ️ Utilisateur système existe déjà';
    END IF;
END $$;

-- 2. Vérifier la structure actuelle de loyalty_points_history
SELECT 
    'Structure actuelle loyalty_points_history' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'loyalty_points_history'
    AND (column_name = 'created_by' OR column_name = 'user_id')
ORDER BY ordinal_position;

-- 3. S'assurer que les colonnes created_by et user_id peuvent accepter NULL
DO $$
BEGIN
    -- Vérifier si la colonne created_by est NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'loyalty_points_history' 
            AND column_name = 'created_by'
            AND is_nullable = 'NO'
    ) THEN
        -- Rendre la colonne nullable temporairement
        ALTER TABLE public.loyalty_points_history ALTER COLUMN created_by DROP NOT NULL;
        RAISE NOTICE '✅ Colonne created_by rendue nullable';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne created_by est déjà nullable';
    END IF;
    
    -- Vérifier si la colonne user_id est NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'loyalty_points_history' 
            AND column_name = 'user_id'
            AND is_nullable = 'NO'
    ) THEN
        -- Rendre la colonne nullable temporairement
        ALTER TABLE public.loyalty_points_history ALTER COLUMN user_id DROP NOT NULL;
        RAISE NOTICE '✅ Colonne user_id rendue nullable';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id est déjà nullable';
    END IF;
END $$;

-- 4. Mettre à jour les enregistrements existants avec created_by et user_id NULL
UPDATE public.loyalty_points_history 
SET created_by = '00000000-0000-0000-0000-000000000000'::UUID 
WHERE created_by IS NULL;

UPDATE public.loyalty_points_history 
SET user_id = '00000000-0000-0000-0000-000000000000'::UUID 
WHERE user_id IS NULL;

-- 5. Vérifier les données mises à jour
SELECT 
    'Données mises à jour' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as avec_created_by,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_created_by,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as avec_user_id,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_user_id
FROM public.loyalty_points_history;

-- 6. Maintenant, rendre les colonnes NOT NULL avec une valeur par défaut
DO $$
BEGIN
    -- Ajouter une valeur par défaut pour created_by
    ALTER TABLE public.loyalty_points_history 
    ALTER COLUMN created_by SET DEFAULT '00000000-0000-0000-0000-000000000000'::UUID;
    
    -- Rendre la colonne created_by NOT NULL
    ALTER TABLE public.loyalty_points_history 
    ALTER COLUMN created_by SET NOT NULL;
    
    -- Ajouter une valeur par défaut pour user_id
    ALTER TABLE public.loyalty_points_history 
    ALTER COLUMN user_id SET DEFAULT '00000000-0000-0000-0000-000000000000'::UUID;
    
    -- Rendre la colonne user_id NOT NULL
    ALTER TABLE public.loyalty_points_history 
    ALTER COLUMN user_id SET NOT NULL;
    
    RAISE NOTICE '✅ Colonnes created_by et user_id configurées avec valeur par défaut et NOT NULL';
END $$;

-- 7. Vérification finale
SELECT 
    'Vérification finale' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'loyalty_points_history'
    AND (column_name = 'created_by' OR column_name = 'user_id')
ORDER BY column_name;

SELECT '✅ CORRECTION TERMINÉE' as status;
