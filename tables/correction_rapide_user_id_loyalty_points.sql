-- =====================================================
-- CORRECTION RAPIDE USER_ID LOYALTY_POINTS_HISTORY
-- =====================================================
-- Problème: La colonne user_id est NOT NULL mais n'est pas remplie
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

-- 2. Rendre la colonne user_id nullable temporairement
ALTER TABLE public.loyalty_points_history ALTER COLUMN user_id DROP NOT NULL;

-- 3. Mettre à jour les enregistrements existants
UPDATE public.loyalty_points_history 
SET user_id = '00000000-0000-0000-0000-000000000000'::UUID 
WHERE user_id IS NULL;

-- 4. Ajouter une valeur par défaut
ALTER TABLE public.loyalty_points_history 
ALTER COLUMN user_id SET DEFAULT '00000000-0000-0000-0000-000000000000'::UUID;

-- 5. Rendre la colonne NOT NULL
ALTER TABLE public.loyalty_points_history ALTER COLUMN user_id SET NOT NULL;

-- 6. Vérification
SELECT 
    'Correction terminée' as status,
    COUNT(*) as total_records,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as avec_user_id
FROM public.loyalty_points_history;

SELECT '✅ CORRECTION RAPIDE TERMINÉE' as status;
