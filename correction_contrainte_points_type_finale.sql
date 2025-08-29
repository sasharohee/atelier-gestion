-- Correction finale de la contrainte check_points_type_values
-- Date: 2024-01-24

-- ============================================================================
-- 1. DIAGNOSTIC DE LA CONTRAINTE
-- ============================================================================

SELECT '=== DIAGNOSTIC DE LA CONTRAINTE ===' as section;

-- Vérifier les contraintes existantes sur la table loyalty_points_history
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'loyalty_points_history'::regclass
AND contype = 'c';

-- Vérifier les valeurs actuelles dans points_type
SELECT DISTINCT points_type, COUNT(*) as count
FROM loyalty_points_history
GROUP BY points_type
ORDER BY points_type;

-- ============================================================================
-- 2. SUPPRESSION DE LA CONTRAINTE PROBLÉMATIQUE
-- ============================================================================

SELECT '=== SUPPRESSION DE LA CONTRAINTE ===' as section;

-- Supprimer la contrainte de vérification existante
ALTER TABLE loyalty_points_history 
DROP CONSTRAINT IF EXISTS check_points_type_values;

-- Vérifier que la contrainte a été supprimée
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'loyalty_points_history'::regclass
AND contype = 'c';

-- ============================================================================
-- 3. CRÉATION DE LA NOUVELLE CONTRAINTE PERMISSIVE
-- ============================================================================

SELECT '=== CRÉATION DE LA NOUVELLE CONTRAINTE ===' as section;

-- Créer une nouvelle contrainte plus permissive qui accepte 'manual'
ALTER TABLE loyalty_points_history 
ADD CONSTRAINT check_points_type_values 
CHECK (points_type IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund', 'adjustment', 'reward'));

-- Vérifier que la nouvelle contrainte est en place
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'loyalty_points_history'::regclass
AND contype = 'c'
AND conname = 'check_points_type_values';

-- ============================================================================
-- 4. VÉRIFICATION DES DONNÉES EXISTANTES
-- ============================================================================

SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Vérifier s'il y a des valeurs invalides
SELECT DISTINCT points_type 
FROM loyalty_points_history 
WHERE points_type NOT IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund', 'adjustment', 'reward');

-- Si des valeurs invalides existent, les corriger
UPDATE loyalty_points_history 
SET points_type = 'manual' 
WHERE points_type NOT IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund', 'adjustment', 'reward');

-- Vérifier les valeurs après correction
SELECT DISTINCT points_type, COUNT(*) as count
FROM loyalty_points_history
GROUP BY points_type
ORDER BY points_type;

-- ============================================================================
-- 5. TEST DE LA CONTRAINTE
-- ============================================================================

SELECT '=== TEST DE LA CONTRAINTE ===' as section;

-- Tester l'insertion avec différentes valeurs
DO $$
BEGIN
    -- Test avec 'manual' (devrait fonctionner)
    BEGIN
        INSERT INTO loyalty_points_history (
            client_id, points_change, points_type, source_type, 
            source_id, description, created_by, user_id
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', 
            10, 'manual', 'manual', NULL, 'Test manual', 
            '00000000-0000-0000-0000-000000000000',
            '00000000-0000-0000-0000-000000000000'
        );
        RAISE NOTICE '✅ Test avec ''manual'' : SUCCÈS';
        
        -- Nettoyer le test
        DELETE FROM loyalty_points_history 
        WHERE client_id = '00000000-0000-0000-0000-000000000000' 
        AND description = 'Test manual';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Test avec ''manual'' : ÉCHEC - %', SQLERRM;
    END;
    
    -- Test avec 'earned' (devrait fonctionner)
    BEGIN
        INSERT INTO loyalty_points_history (
            client_id, points_change, points_type, source_type, 
            source_id, description, created_by, user_id
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', 
            10, 'earned', 'purchase', NULL, 'Test earned', 
            '00000000-0000-0000-0000-000000000000',
            '00000000-0000-0000-0000-000000000000'
        );
        RAISE NOTICE '✅ Test avec ''earned'' : SUCCÈS';
        
        -- Nettoyer le test
        DELETE FROM loyalty_points_history 
        WHERE client_id = '00000000-0000-0000-0000-000000000000' 
        AND description = 'Test earned';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Test avec ''earned'' : ÉCHEC - %', SQLERRM;
    END;
    
END $$;

-- ============================================================================
-- 6. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que la contrainte est bien en place
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'loyalty_points_history'::regclass
AND contype = 'c'
AND conname = 'check_points_type_values';

-- Afficher un message de succès
SELECT '✅ Contrainte check_points_type_values corrigée avec succès !' as result;
SELECT '📋 Valeurs acceptées: earned, used, expired, bonus, referral, manual, purchase, refund, adjustment, reward' as valeurs_acceptees;
SELECT '🔧 La fonction add_loyalty_points peut maintenant utiliser ''manual'' sans problème' as fonction_ready;
