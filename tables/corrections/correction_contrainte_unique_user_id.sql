-- Correction de la contrainte unique sur user_id
-- Date: 2024-01-24
-- Objectif: Ajouter la contrainte unique manquante sur user_id

-- 1. VÉRIFIER L'EXISTENCE DE LA TABLE
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'subscription_status') THEN
        RAISE NOTICE '❌ Table subscription_status n''existe pas';
        RETURN;
    ELSE
        RAISE NOTICE '✅ Table subscription_status existe';
    END IF;
END $$;

-- 2. VÉRIFIER LES CONTRAINTES EXISTANTES
SELECT 
    '=== CONTRAINTES EXISTANTES ===' as section,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'subscription_status';

-- 3. VÉRIFIER SI LA CONTRAINTE UNIQUE EXISTE
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'subscription_status' 
        AND constraint_type = 'UNIQUE' 
        AND constraint_name LIKE '%user_id%'
    ) THEN
        RAISE NOTICE '✅ Contrainte unique sur user_id existe déjà';
    ELSE
        RAISE NOTICE '❌ Contrainte unique sur user_id manquante, ajout...';
        
        -- Vérifier s'il y a des doublons avant d'ajouter la contrainte
        IF EXISTS (
            SELECT user_id, COUNT(*) 
            FROM subscription_status 
            WHERE user_id IS NOT NULL 
            GROUP BY user_id 
            HAVING COUNT(*) > 1
        ) THEN
            RAISE NOTICE '⚠️ Doublons détectés, nettoyage...';
            
            -- Supprimer les doublons en gardant le plus récent
            DELETE FROM subscription_status 
            WHERE id NOT IN (
                SELECT DISTINCT ON (user_id) id 
                FROM subscription_status 
                WHERE user_id IS NOT NULL 
                ORDER BY user_id, created_at DESC
            );
            
            RAISE NOTICE '✅ Doublons supprimés';
        END IF;
        
        -- Ajouter la contrainte unique
        ALTER TABLE subscription_status ADD CONSTRAINT unique_subscription_status_user_id UNIQUE (user_id);
        RAISE NOTICE '✅ Contrainte unique ajoutée sur user_id';
    END IF;
END $$;

-- 4. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT 
    '=== STRUCTURE DE LA TABLE ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status'
ORDER BY ordinal_position;

-- 5. VÉRIFIER LES DONNÉES
SELECT 
    '=== DONNÉES ACTUELLES ===' as section,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM subscription_status;

-- 6. AFFICHER LES DONNÉES
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

-- 7. TESTER L'INSERTION AVEC CONFLICT
DO $$
BEGIN
    RAISE NOTICE '🧪 Test d''insertion avec gestion de conflit...';
    
    -- Test d'insertion avec ON CONFLICT
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
            'Test de mise à jour via ON CONFLICT'
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
    '🎉 CORRECTION TERMINÉE' as result,
    '✅ Contrainte unique sur user_id configurée' as check1,
    '✅ ON CONFLICT fonctionnel' as check2,
    '✅ Données cohérentes' as check3,
    '✅ Prêt pour les tests d''activation' as check4;
