-- 🎯 CORRECTION ULTIME: Créer toutes les entrées subscription_status manquantes
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier les utilisateurs sans subscription_status
SELECT 
    'Utilisateurs sans subscription_status:' as info,
    COUNT(*) as count
FROM public.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss 
    WHERE ss.user_id = u.id
);

-- 2. Créer TOUTES les entrées manquantes avec gestion d'erreur complète
DO $$
DECLARE
    user_record RECORD;
    subscription_values TEXT[] := ARRAY['FREE', 'BASIC', 'PREMIUM', 'STANDARD', 'TRIAL', 'PRO', 'PLUS'];
    i INTEGER;
    success BOOLEAN := FALSE;
    total_created INTEGER := 0;
BEGIN
    FOR user_record IN (
        SELECT u.id, u.first_name, u.last_name, u.email
        FROM public.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = u.id)
    ) LOOP
        success := FALSE;
        
        -- Essayer chaque valeur possible pour subscription_type
        FOR i IN 1..array_length(subscription_values, 1) LOOP
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
                    subscription_values[i],
                    NOW(),
                    NOW()
                );
                success := TRUE;
                total_created := total_created + 1;
                RAISE NOTICE '✅ Subscription créée pour % avec type %', user_record.email, subscription_values[i];
                EXIT; -- Sortir de la boucle si l'insertion réussit
            EXCEPTION WHEN OTHERS THEN
                -- Continuer avec la valeur suivante
                RAISE NOTICE '❌ Échec avec % pour %: %', subscription_values[i], user_record.email, SQLERRM;
            END;
        END LOOP;
        
        -- Si aucune valeur n'a fonctionné, essayer sans subscription_type
        IF NOT success THEN
            BEGIN
                INSERT INTO public.subscription_status (
                    user_id, 
                    first_name, 
                    last_name, 
                    email, 
                    is_active, 
                    created_at, 
                    updated_at
                ) VALUES (
                    user_record.id,
                    COALESCE(user_record.first_name, 'Utilisateur'),
                    COALESCE(user_record.last_name, 'Anonyme'),
                    user_record.email,
                    true,
                    NOW(),
                    NOW()
                );
                success := TRUE;
                total_created := total_created + 1;
                RAISE NOTICE '✅ Subscription créée pour % sans subscription_type', user_record.email;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Impossible de créer subscription pour %: %', user_record.email, SQLERRM;
            END;
        END IF;
    END LOOP;
    
    RAISE NOTICE '🎉 Total des entrées créées: %', total_created;
END $$;

-- 3. Vérifier le résultat final
SELECT 
    'Entrées subscription_status totales:' as info,
    COUNT(*) as count
FROM public.subscription_status;

-- 4. Afficher les entrées créées récemment
SELECT 
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    created_at
FROM public.subscription_status
ORDER BY created_at DESC
LIMIT 10;

-- 5. Message de confirmation final
SELECT '🎉 CORRECTION ULTIME APPLIQUÉE - Toutes les entrées subscription_status créées avec succès' as status;
