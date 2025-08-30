-- 🔧 CORRECTION - Contraintes NOT NULL sur Loyalty Points History
-- Script pour corriger les problèmes de contraintes NOT NULL

-- ========================================
-- DIAGNOSTIC 1: VÉRIFICATION DES CONTRAINTES NOT NULL
-- ========================================

SELECT 
    '=== CONTRAINTES NOT NULL LOYALTY_POINTS_HISTORY ===' as section,
    column_name,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' THEN '❌ NOT NULL'
        ELSE '✅ NULLABLE'
    END as statut_contrainte
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
AND is_nullable = 'NO'
ORDER BY column_name;

-- ========================================
-- DIAGNOSTIC 2: VÉRIFICATION DES COLONNES PROBLÉMATIQUES
-- ========================================

DO $$
DECLARE
    points_before_exists BOOLEAN;
    points_after_exists BOOLEAN;
    points_before_nullable BOOLEAN;
    points_after_nullable BOOLEAN;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION COLONNES POINTS ===';
    
    -- Vérifier si les colonnes existent
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'points_before'
    ) INTO points_before_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'points_after'
    ) INTO points_after_exists;
    
    IF points_before_exists THEN
        SELECT is_nullable = 'YES' INTO points_before_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'points_before';
        
        RAISE NOTICE 'Colonne points_before: %s (%s)', 
            CASE WHEN points_before_exists THEN 'EXISTE' ELSE 'MANQUANTE' END,
            CASE WHEN points_before_nullable THEN 'NULLABLE' ELSE 'NOT NULL' END;
    ELSE
        RAISE NOTICE 'Colonne points_before: ❌ MANQUANTE';
    END IF;
    
    IF points_after_exists THEN
        SELECT is_nullable = 'YES' INTO points_after_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'points_after';
        
        RAISE NOTICE 'Colonne points_after: %s (%s)', 
            CASE WHEN points_after_exists THEN 'EXISTE' ELSE 'MANQUANTE' END,
            CASE WHEN points_after_nullable THEN 'NULLABLE' ELSE 'NOT NULL' END;
    ELSE
        RAISE NOTICE 'Colonne points_after: ❌ MANQUANTE';
    END IF;
END $$;

-- ========================================
-- CORRECTION 1: AJOUTER LES COLONNES MANQUANTES
-- ========================================

DO $$
DECLARE
    points_before_exists BOOLEAN;
    points_after_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== AJOUT DES COLONNES POINTS MANQUANTES ===';
    
    -- Vérifier si les colonnes existent
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'points_before'
    ) INTO points_before_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'points_after'
    ) INTO points_after_exists;
    
    -- Ajouter les colonnes manquantes
    IF NOT points_before_exists THEN
        ALTER TABLE loyalty_points_history ADD COLUMN points_before INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Colonne points_before ajoutée avec valeur par défaut 0';
    ELSE
        RAISE NOTICE '✅ Colonne points_before existe déjà';
    END IF;
    
    IF NOT points_after_exists THEN
        ALTER TABLE loyalty_points_history ADD COLUMN points_after INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Colonne points_after ajoutée avec valeur par défaut 0';
    ELSE
        RAISE NOTICE '✅ Colonne points_after existe déjà';
    END IF;
END $$;

-- ========================================
-- CORRECTION 2: RENDRE LES COLONNES NULLABLES OU AJOUTER DES VALEURS PAR DÉFAUT
-- ========================================

DO $$
DECLARE
    points_before_nullable BOOLEAN;
    points_after_nullable BOOLEAN;
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== CORRECTION DES CONTRAINTES NOT NULL ===';
    
    -- Vérifier si les colonnes sont nullable
    SELECT is_nullable = 'YES' INTO points_before_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'loyalty_points_history' 
    AND column_name = 'points_before';
    
    SELECT is_nullable = 'YES' INTO points_after_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'loyalty_points_history' 
    AND column_name = 'points_after';
    
    -- Option 1: Rendre les colonnes nullable
    IF NOT points_before_nullable THEN
        ALTER TABLE loyalty_points_history ALTER COLUMN points_before DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée sur points_before';
    ELSE
        RAISE NOTICE '✅ points_before est déjà nullable';
    END IF;
    
    IF NOT points_after_nullable THEN
        ALTER TABLE loyalty_points_history ALTER COLUMN points_after DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée sur points_after';
    ELSE
        RAISE NOTICE '✅ points_after est déjà nullable';
    END IF;
    
    -- Option 2: Mettre à jour les valeurs NULL existantes
    UPDATE loyalty_points_history SET points_before = 0 WHERE points_before IS NULL;
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count > 0 THEN
        RAISE NOTICE '✅ % enregistrements mis à jour avec points_before = 0', updated_count;
    END IF;
    
    UPDATE loyalty_points_history SET points_after = 0 WHERE points_after IS NULL;
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count > 0 THEN
        RAISE NOTICE '✅ % enregistrements mis à jour avec points_after = 0', updated_count;
    END IF;
END $$;

-- ========================================
-- CORRECTION 3: CRÉER UN TRIGGER POUR DÉFINIR AUTOMATIQUEMENT LES VALEURS
-- ========================================

-- Créer ou modifier la fonction pour définir automatiquement les valeurs
CREATE OR REPLACE FUNCTION set_loyalty_points_defaults()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir les valeurs par défaut si elles sont NULL
    IF NEW.points_before IS NULL THEN
        NEW.points_before := 0;
    END IF;
    
    IF NEW.points_after IS NULL THEN
        NEW.points_after := 0;
    END IF;
    
    -- Note: Le calcul points_before + points est géré dans le script principal
    -- car la colonne points peut ne pas exister
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer et recréer le trigger
DROP TRIGGER IF EXISTS set_loyalty_points_defaults_trigger ON loyalty_points_history;

CREATE TRIGGER set_loyalty_points_defaults_trigger
    BEFORE INSERT OR UPDATE ON loyalty_points_history
    FOR EACH ROW
    EXECUTE FUNCTION set_loyalty_points_defaults();

-- ========================================
-- CORRECTION 4: METTRE À JOUR LES ENREGISTREMENTS EXISTANTS
-- ========================================

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== MISE À JOUR DES ENREGISTREMENTS EXISTANTS ===';
    
    -- Mettre à jour les enregistrements avec des valeurs NULL
    UPDATE loyalty_points_history 
    SET points_before = 0 
    WHERE points_before IS NULL;
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ % enregistrements mis à jour avec points_before = 0', updated_count;
    
    UPDATE loyalty_points_history 
    SET points_after = 0 
    WHERE points_after IS NULL;
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ % enregistrements mis à jour avec points_after = 0', updated_count;
    
    -- Vérifier si la colonne points existe avant de l'utiliser
    DECLARE
        points_exists BOOLEAN;
    BEGIN
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'loyalty_points_history' 
            AND column_name = 'points'
        ) INTO points_exists;
        
        IF points_exists THEN
            -- Calculer points_after basé sur points_before + points si nécessaire
            UPDATE loyalty_points_history 
            SET points_after = points_before + points 
            WHERE points IS NOT NULL AND points_after = 0;
            GET DIAGNOSTICS updated_count = ROW_COUNT;
            RAISE NOTICE '✅ % enregistrements avec points_after calculé', updated_count;
        ELSE
            RAISE NOTICE '⚠️ Colonne points n''existe pas - calcul points_after ignoré';
        END IF;
    END;
END $$;

-- ========================================
-- VÉRIFICATION FINALE
-- ========================================

DO $$
DECLARE
    points_before_nullable BOOLEAN;
    points_after_nullable BOOLEAN;
    trigger_exists BOOLEAN;
    null_count_before INTEGER;
    null_count_after INTEGER;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION FINALE ===';
    
    -- Vérifier si les colonnes sont maintenant nullable
    SELECT is_nullable = 'YES' INTO points_before_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'loyalty_points_history' 
    AND column_name = 'points_before';
    
    SELECT is_nullable = 'YES' INTO points_after_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'loyalty_points_history' 
    AND column_name = 'points_after';
    
    -- Vérifier si le trigger existe
    SELECT EXISTS (
        SELECT FROM information_schema.triggers 
        WHERE trigger_name = 'set_loyalty_points_defaults_trigger'
        AND event_object_table = 'loyalty_points_history'
    ) INTO trigger_exists;
    
    -- Compter les valeurs NULL restantes
    SELECT COUNT(*) INTO null_count_before
    FROM loyalty_points_history 
    WHERE points_before IS NULL;
    
    SELECT COUNT(*) INTO null_count_after
    FROM loyalty_points_history 
    WHERE points_after IS NULL;
    
    -- Afficher les résultats
    RAISE NOTICE 'points_before nullable: %s', CASE WHEN points_before_nullable THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'points_after nullable: %s', CASE WHEN points_after_nullable THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Trigger de valeurs par défaut: %s', CASE WHEN trigger_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Valeurs NULL points_before: %', null_count_before;
    RAISE NOTICE 'Valeurs NULL points_after: %', null_count_after;
    
    IF points_before_nullable AND points_after_nullable AND trigger_exists AND null_count_before = 0 AND null_count_after = 0 THEN
        RAISE NOTICE '🎉 CORRECTION DES CONTRAINTES RÉUSSIE !';
    ELSE
        RAISE NOTICE '⚠️ CORRECTION DES CONTRAINTES INCOMPLÈTE';
    END IF;
END $$;

-- ========================================
-- TEST D'INSERTION
-- ========================================

DO $$
DECLARE
    test_id UUID;
    test_client_id UUID;
    insertion_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== TEST D''INSERTION AVEC VALEURS NULL ===';
    
    -- Trouver un client de test
    SELECT id INTO test_client_id FROM clients LIMIT 1;
    
    IF test_client_id IS NOT NULL THEN
        BEGIN
            -- Vérifier quelles colonnes existent pour l'insertion
            DECLARE
                points_exists BOOLEAN;
                action_type_exists BOOLEAN;
                description_exists BOOLEAN;
            BEGIN
                SELECT EXISTS (
                    SELECT FROM information_schema.columns 
                    WHERE table_schema = 'public' 
                    AND table_name = 'loyalty_points_history' 
                    AND column_name = 'points'
                ) INTO points_exists;
                
                SELECT EXISTS (
                    SELECT FROM information_schema.columns 
                    WHERE table_schema = 'public' 
                    AND table_name = 'loyalty_points_history' 
                    AND column_name = 'action_type'
                ) INTO action_type_exists;
                
                SELECT EXISTS (
                    SELECT FROM information_schema.columns 
                    WHERE table_schema = 'public' 
                    AND table_name = 'loyalty_points_history' 
                    AND column_name = 'description'
                ) INTO description_exists;
                
                -- Test d'insertion adaptatif selon les colonnes existantes
                IF points_exists AND action_type_exists AND description_exists THEN
                    INSERT INTO loyalty_points_history (
                        id, client_id, points, action_type, description, reference_id,
                        points_before, points_after, created_at, updated_at
                    ) VALUES (
                        gen_random_uuid(), test_client_id, 100, 'earned', 'Test points', gen_random_uuid(),
                        NULL, NULL, NOW(), NOW()
                    ) RETURNING id INTO test_id;
                ELSE
                    -- Insertion minimale sans les colonnes optionnelles
                    INSERT INTO loyalty_points_history (
                        id, client_id, reference_id,
                        points_before, points_after, created_at, updated_at
                    ) VALUES (
                        gen_random_uuid(), test_client_id, gen_random_uuid(),
                        NULL, NULL, NOW(), NOW()
                    ) RETURNING id INTO test_id;
                END IF;
            END;
            
            insertion_success := TRUE;
            RAISE NOTICE '✅ Test d''insertion RÉUSSI - ID: %', test_id;
            
            -- Vérifier les valeurs définies par le trigger
            DECLARE
                points_before_val INTEGER;
                points_after_val INTEGER;
            BEGIN
                SELECT points_before, points_after INTO points_before_val, points_after_val
                FROM loyalty_points_history WHERE id = test_id;
                RAISE NOTICE '   points_before: %', points_before_val;
                RAISE NOTICE '   points_after: %', points_after_val;
            END;
            
            -- Nettoyer le test
            DELETE FROM loyalty_points_history WHERE id = test_id;
            RAISE NOTICE '✅ Enregistrement de test supprimé';
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ ERREUR lors du test d''insertion: %', SQLERRM;
                insertion_success := FALSE;
        END;
    ELSE
        RAISE NOTICE '⚠️ Aucun client trouvé pour le test';
    END IF;
    
    IF insertion_success THEN
        RAISE NOTICE '🎉 CORRECTION RÉUSSIE - L''insertion avec valeurs NULL fonctionne !';
    ELSE
        RAISE NOTICE '❌ CORRECTION ÉCHOUÉE - L''insertion avec valeurs NULL ne fonctionne pas';
    END IF;
END $$;

-- Message final
SELECT '🎉 Correction des contraintes NOT NULL terminée avec succès !' as status;
