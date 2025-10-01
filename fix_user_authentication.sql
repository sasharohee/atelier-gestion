-- Script pour corriger les problèmes d'authentification d'un utilisateur existant
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'utilisateur actuel
DO $$
DECLARE
    user_record RECORD;
    user_id UUID;
BEGIN
    -- Récupérer l'utilisateur
    SELECT id, email, email_confirmed_at, encrypted_password
    INTO user_record
    FROM auth.users
    WHERE email = 'sasharohee@icloud.com';
    
    IF user_record.id IS NULL THEN
        RAISE NOTICE '❌ Utilisateur non trouvé';
        RETURN;
    END IF;
    
    user_id := user_record.id;
    RAISE NOTICE '✅ Utilisateur trouvé: % (ID: %)', user_record.email, user_id;
    
    -- 2. Vérifier si l'email est confirmé
    IF user_record.email_confirmed_at IS NULL THEN
        RAISE NOTICE '⚠️ Email non confirmé, confirmation...';
        UPDATE auth.users 
        SET email_confirmed_at = NOW()
        WHERE id = user_id;
        RAISE NOTICE '✅ Email confirmé';
    ELSE
        RAISE NOTICE '✅ Email déjà confirmé: %', user_record.email_confirmed_at;
    END IF;
    
    -- 3. Vérifier si l'utilisateur existe dans public.users
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = user_id) THEN
        RAISE NOTICE '⚠️ Utilisateur manquant dans public.users, création...';
        INSERT INTO public.users (id, email, created_at, updated_at)
        VALUES (user_id, user_record.email, NOW(), NOW());
        RAISE NOTICE '✅ Utilisateur créé dans public.users';
    ELSE
        RAISE NOTICE '✅ Utilisateur présent dans public.users';
    END IF;
    
    -- 4. Nettoyer les sessions expirées
    DELETE FROM auth.sessions 
    WHERE user_id = user_id 
    AND (not_after IS NOT NULL AND not_after < NOW());
    
    RAISE NOTICE '✅ Sessions expirées nettoyées';
    
    -- 5. Afficher le résumé
    RAISE NOTICE '🎉 Diagnostic et correction terminés pour l''utilisateur: %', user_record.email;
    
END $$;

-- 6. Vérifier le résultat
SELECT 
    'Résultat final:' as info,
    u.id,
    u.email,
    u.email_confirmed_at,
    u.last_sign_in_at,
    CASE 
        WHEN pu.id IS NOT NULL THEN '✅ Synchronisé'
        ELSE '❌ Non synchronisé'
    END as sync_status
FROM auth.users u
LEFT JOIN public.users pu ON u.id = pu.id
WHERE u.email = 'sasharohee@icloud.com';




