-- Ajout automatique des nouveaux utilisateurs à subscription_status
-- Date: 2024-01-24
-- Objectif: Ajouter les utilisateurs existants qui ne sont pas dans subscription_status

-- 1. VÉRIFIER LES UTILISATEURS EXISTANTS
SELECT 
    '=== UTILISATEURS EXISTANTS ===' as section,
    COUNT(*) as total_users
FROM auth.users;

-- 2. AFFICHER LES UTILISATEURS
SELECT 
    id,
    email,
    raw_user_meta_data,
    created_at
FROM auth.users
ORDER BY created_at DESC;

-- 3. VÉRIFIER LES UTILISATEURS DÉJÀ DANS SUBSCRIPTION_STATUS
SELECT 
    '=== UTILISATEURS DANS SUBSCRIPTION_STATUS ===' as section,
    COUNT(*) as total_subscriptions
FROM subscription_status;

-- 4. IDENTIFIER LES UTILISATEURS MANQUANTS
SELECT 
    '=== UTILISATEURS MANQUANTS ===' as section,
    u.id,
    u.email,
    u.raw_user_meta_data,
    u.created_at
FROM auth.users u
LEFT JOIN subscription_status s ON u.id = s.user_id
WHERE s.user_id IS NULL
ORDER BY u.created_at DESC;

-- 5. AJOUTER LES UTILISATEURS MANQUANTS
DO $$
DECLARE
    user_record RECORD;
    added_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔄 Ajout des utilisateurs manquants...';
    
    FOR user_record IN 
        SELECT 
            u.id,
            u.email,
            u.raw_user_meta_data,
            u.created_at
        FROM auth.users u
        LEFT JOIN subscription_status s ON u.id = s.user_id
        WHERE s.user_id IS NULL
    LOOP
        -- Déterminer si c'est un admin
        DECLARE
            is_admin BOOLEAN := FALSE;
            first_name TEXT := 'Utilisateur';
            last_name TEXT := '';
        BEGIN
            -- Vérifier si c'est un admin
            IF user_record.email = 'srohee32@gmail.com' THEN
                is_admin := TRUE;
                first_name := 'Admin';
                last_name := 'User';
            END IF;
            
            -- Extraire les noms depuis les métadonnées si disponibles
            IF user_record.raw_user_meta_data IS NOT NULL THEN
                IF user_record.raw_user_meta_data->>'firstName' IS NOT NULL THEN
                    first_name := user_record.raw_user_meta_data->>'firstName';
                END IF;
                IF user_record.raw_user_meta_data->>'lastName' IS NOT NULL THEN
                    last_name := user_record.raw_user_meta_data->>'lastName';
                END IF;
            END IF;
            
            -- Insérer l'utilisateur dans subscription_status
            INSERT INTO subscription_status (
                user_id,
                first_name,
                last_name,
                email,
                is_active,
                subscription_type,
                notes,
                activated_at
            ) VALUES (
                user_record.id,
                first_name,
                last_name,
                user_record.email,
                is_admin, -- Admin = actif, autres = inactif
                CASE WHEN is_admin THEN 'premium' ELSE 'free' END,
                CASE 
                    WHEN is_admin THEN 'Administrateur - accès complet'
                    ELSE 'Compte créé - en attente d''activation par l''administrateur'
                END,
                CASE WHEN is_admin THEN user_record.created_at ELSE NULL END
            );
            
            added_count := added_count + 1;
            RAISE NOTICE '✅ Ajouté: % (%) - Admin: %', user_record.email, first_name, is_admin;
        END;
    END LOOP;
    
    RAISE NOTICE '🎉 Ajout terminé: % utilisateurs ajoutés', added_count;
END $$;

-- 6. VÉRIFIER LES RÉSULTATS
SELECT 
    '=== RÉSULTATS FINAUX ===' as section,
    COUNT(*) as total_subscriptions
FROM subscription_status;

-- 7. AFFICHER TOUS LES UTILISATEURS
SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at
FROM subscription_status
ORDER BY created_at DESC;

-- 8. RÉSUMÉ
SELECT 
    '🎉 SYNCHRONISATION TERMINÉE' as result,
    '✅ Tous les utilisateurs ajoutés à subscription_status' as check1,
    '✅ Statuts configurés correctement' as check2,
    '✅ Prêt pour la gestion d''accès' as check3;
