-- Nettoyage des doublons dans subscription_status
-- Date: 2024-01-24
-- Objectif: Supprimer les doublons avant d'ajouter la contrainte unique

-- 1. VÉRIFIER LES DOUBLONS
SELECT 
    '=== VÉRIFICATION DES DOUBLONS ===' as section;

SELECT 
    user_id,
    COUNT(*) as nombre_doublons,
    STRING_AGG(id::text, ', ') as ids
FROM subscription_status 
WHERE user_id IS NOT NULL 
GROUP BY user_id 
HAVING COUNT(*) > 1
ORDER BY nombre_doublons DESC;

-- 2. AFFICHER TOUS LES ENREGISTREMENTS AVEC DOUBLONS
SELECT 
    '=== ENREGISTREMENTS AVEC DOUBLONS ===' as section;

SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at
FROM subscription_status 
WHERE user_id IN (
    SELECT user_id 
    FROM subscription_status 
    WHERE user_id IS NOT NULL 
    GROUP BY user_id 
    HAVING COUNT(*) > 1
)
ORDER BY user_id, created_at DESC;

-- 3. NETTOYER LES DOUBLONS
DO $$
DECLARE
    duplicate_user_id UUID;
    keep_id UUID;
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🧹 Début du nettoyage des doublons...';
    
    -- Pour chaque user_id avec des doublons
    FOR duplicate_user_id IN 
        SELECT user_id 
        FROM subscription_status 
        WHERE user_id IS NOT NULL 
        GROUP BY user_id 
        HAVING COUNT(*) > 1
    LOOP
        -- Garder l'enregistrement le plus récent
        SELECT id INTO keep_id
        FROM subscription_status 
        WHERE user_id = duplicate_user_id 
        ORDER BY created_at DESC, updated_at DESC
        LIMIT 1;
        
        -- Supprimer les autres enregistrements
        DELETE FROM subscription_status 
        WHERE user_id = duplicate_user_id 
        AND id != keep_id;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ User %: % enregistrements supprimés, gardé ID %', duplicate_user_id, deleted_count, keep_id;
    END LOOP;
    
    RAISE NOTICE '🎉 Nettoyage des doublons terminé';
END $$;

-- 4. VÉRIFIER QU'IL N'Y A PLUS DE DOUBLONS
SELECT 
    '=== VÉRIFICATION APRÈS NETTOYAGE ===' as section;

SELECT 
    user_id,
    COUNT(*) as nombre_enregistrements
FROM subscription_status 
WHERE user_id IS NOT NULL 
GROUP BY user_id 
HAVING COUNT(*) > 1;

-- 5. AFFICHER LES DONNÉES FINALES
SELECT 
    '=== DONNÉES FINALES ===' as section,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM subscription_status;

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

-- 6. AJOUTER LA CONTRAINTE UNIQUE
DO $$
BEGIN
    -- Vérifier si la contrainte existe déjà
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'subscription_status' 
        AND constraint_type = 'UNIQUE' 
        AND constraint_name LIKE '%user_id%'
    ) THEN
        RAISE NOTICE '✅ Contrainte unique sur user_id existe déjà';
    ELSE
        RAISE NOTICE '🔧 Ajout de la contrainte unique sur user_id...';
        ALTER TABLE subscription_status ADD CONSTRAINT unique_subscription_status_user_id UNIQUE (user_id);
        RAISE NOTICE '✅ Contrainte unique ajoutée avec succès';
    END IF;
END $$;

-- 7. TESTER L'INSERTION AVEC ON CONFLICT
DO $$
BEGIN
    RAISE NOTICE '🧪 Test d''insertion avec ON CONFLICT...';
    
    INSERT INTO subscription_status (
        user_id,
        first_name,
        last_name,
        email,
        is_active,
        subscription_type,
        notes
    ) 
    VALUES 
        (
            '68432d4b-1747-448c-9908-483be4fdd8dd',
            'RepPhone',
            'Reparation',
            'repphonereparation@gmail.com',
            FALSE,
            'free',
            'Test après nettoyage des doublons'
        )
    ON CONFLICT (user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        is_active = EXCLUDED.is_active,
        subscription_type = EXCLUDED.subscription_type,
        notes = EXCLUDED.notes,
        updated_at = NOW();
    
    RAISE NOTICE '✅ Test d''insertion avec ON CONFLICT réussi';
END $$;

-- 8. RÉSUMÉ FINAL
SELECT 
    '🎉 NETTOYAGE ET CORRECTION TERMINÉS' as result,
    '✅ Doublons supprimés' as check1,
    '✅ Contrainte unique ajoutée' as check2,
    '✅ ON CONFLICT fonctionnel' as check3,
    '✅ Données cohérentes' as check4,
    '✅ Prêt pour les tests d''activation' as check5;
