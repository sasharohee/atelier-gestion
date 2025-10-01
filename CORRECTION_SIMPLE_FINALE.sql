-- 🎯 CORRECTION SIMPLE FINALE
-- À exécuter dans Supabase SQL Editor

-- 1. Créer les entrées subscription_status manquantes
INSERT INTO public.subscription_status (
    user_id, 
    first_name, 
    last_name, 
    email, 
    is_active, 
    subscription_type, 
    created_at, 
    updated_at
)
SELECT 
    u.id,
    COALESCE(u.first_name, 'Utilisateur'),
    COALESCE(u.last_name, 'Anonyme'),
    u.email,
    true,
    'FREE',
    NOW(),
    NOW()
FROM public.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss 
    WHERE ss.user_id = u.id
);

-- 2. Vérifier le résultat
SELECT 
    'Entrées subscription_status créées:' as info,
    COUNT(*) as count
FROM public.subscription_status;

-- 3. Afficher les entrées
SELECT 
    user_id,
    email,
    is_active,
    subscription_type
FROM public.subscription_status
ORDER BY created_at DESC;

SELECT '✅ CORRECTION SIMPLE TERMINÉE' as status;
