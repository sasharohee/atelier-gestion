-- 🔍 DIAGNOSTIC ET CORRECTION FINALE
-- À exécuter dans Supabase SQL Editor

-- 1. DIAGNOSTIC : Vérifier l'état actuel
SELECT '=== DIAGNOSTIC ===' as info;

-- Vérifier les utilisateurs existants
SELECT 
    'Utilisateurs dans la table users:' as info,
    COUNT(*) as count
FROM public.users;

-- Vérifier les entrées subscription_status existantes
SELECT 
    'Entrées subscription_status existantes:' as info,
    COUNT(*) as count
FROM public.subscription_status;

-- Vérifier les utilisateurs SANS subscription_status
SELECT 
    'Utilisateurs SANS subscription_status:' as info,
    COUNT(*) as count
FROM public.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss 
    WHERE ss.user_id = u.id
);

-- Afficher les utilisateurs sans subscription_status
SELECT 
    'Utilisateurs sans subscription_status:' as info,
    u.id,
    u.email,
    u.first_name,
    u.last_name
FROM public.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss 
    WHERE ss.user_id = u.id
);

-- 2. CORRECTION : Créer les entrées manquantes
SELECT '=== CORRECTION ===' as info;

-- Créer les entrées manquantes avec gestion d'erreur
DO $$
DECLARE
    user_record RECORD;
    total_created INTEGER := 0;
BEGIN
    FOR user_record IN (
        SELECT u.id, u.first_name, u.last_name, u.email
        FROM public.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = u.id)
    ) LOOP
        BEGIN
            INSERT INTO public.subscription_status (
                user_id, 
                first_name, 
                last_name, 
                email, 
                is_active, 
                subscription_type, 
                created_at, 
                updated_at
            ) VALUES (
                user_record.id,
                COALESCE(user_record.first_name, 'Utilisateur'),
                COALESCE(user_record.last_name, 'Anonyme'),
                user_record.email,
                true,
                'FREE',
                NOW(),
                NOW()
            );
            total_created := total_created + 1;
            RAISE NOTICE '✅ Subscription créée pour %', user_record.email;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur pour %: %', user_record.email, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '🎉 Total des entrées créées: %', total_created;
END $$;

-- 3. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as info;

-- Vérifier le résultat
SELECT 
    'Entrées subscription_status après correction:' as info,
    COUNT(*) as count
FROM public.subscription_status;

-- Afficher les entrées créées
SELECT 
    'Entrées subscription_status:' as info,
    user_id,
    email,
    is_active,
    subscription_type,
    created_at
FROM public.subscription_status
ORDER BY created_at DESC;

-- Message de confirmation
SELECT '🎉 CORRECTION FINALE TERMINÉE' as status;
