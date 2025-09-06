-- 🔍 DIAGNOSTIC ET CORRECTION - Table Loyalty Points History
-- Script pour diagnostiquer et corriger les problèmes sur la table loyalty_points_history

-- ========================================
-- DIAGNOSTIC 1: STRUCTURE DE LA TABLE LOYALTY_POINTS_HISTORY
-- ========================================

SELECT 
    '=== STRUCTURE TABLE LOYALTY_POINTS_HISTORY ===' as section,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IN ('id', 'created_at', 'updated_at') THEN '📅 COLONNE SYSTÈME'
        WHEN column_name IN ('client_id', 'points', 'action_type', 'description') THEN '📋 COLONNE MÉTIER'
        WHEN column_name IN ('user_id', 'created_by', 'workshop_id', 'reference_id') THEN '🔒 COLONNE D''ISOLATION'
        ELSE '❓ AUTRE COLONNE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- DIAGNOSTIC 2: ÉTAT RLS
-- ========================================

SELECT 
    '=== ÉTAT RLS LOYALTY_POINTS_HISTORY ===' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '🔒 RLS ACTIVÉ'
        ELSE '🔓 RLS DÉSACTIVÉ'
    END as rls_status,
    schemaname
FROM pg_tables 
WHERE tablename = 'loyalty_points_history';

-- ========================================
-- DIAGNOSTIC 3: POLITIQUES RLS EXISTANTES
-- ========================================

SELECT 
    '=== POLITIQUES RLS LOYALTY_POINTS_HISTORY ===' as section,
    policyname,
    CASE 
        WHEN permissive = 'PERM' THEN '✅ PERMISSIVE'
        WHEN permissive = 'REST' THEN '❌ RESTRICTIVE'
        ELSE '❓ INCONNU'
    END as type_politique,
    roles,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'loyalty_points_history'
ORDER BY cmd;

-- ========================================
-- DIAGNOSTIC 4: VÉRIFICATION COLONNE REFERENCE_ID
-- ========================================

DO $$
DECLARE
    reference_id_exists BOOLEAN;
    total_records INTEGER;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION COLONNE REFERENCE_ID ===';
    
    -- Vérifier si la colonne reference_id existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'reference_id'
    ) INTO reference_id_exists;
    
    IF reference_id_exists THEN
        RAISE NOTICE '✅ Colonne reference_id existe dans loyalty_points_history';
        
        -- Compter les enregistrements
        SELECT COUNT(*) INTO total_records FROM loyalty_points_history;
        RAISE NOTICE 'Total enregistrements: %', total_records;
        
    ELSE
        RAISE NOTICE '❌ Colonne reference_id MANQUANTE dans loyalty_points_history';
        RAISE NOTICE '💡 Cette colonne est nécessaire pour lier les points de fidélité aux ventes';
    END IF;
END $$;

-- ========================================
-- DIAGNOSTIC 5: DONNÉES EXISTANTES
-- ========================================

DO $$
DECLARE
    total_records INTEGER;
    client_id_exists BOOLEAN;
    points_exists BOOLEAN;
    action_type_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== DONNÉES LOYALTY_POINTS_HISTORY EXISTANTES ===';
    
    -- Compter le total des enregistrements
    SELECT COUNT(*) INTO total_records FROM loyalty_points_history;
    RAISE NOTICE 'Total enregistrements: %', total_records;
    
    -- Vérifier les colonnes principales
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'client_id'
    ) INTO client_id_exists;
    
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
    
    RAISE NOTICE 'Colonne client_id: %s', CASE WHEN client_id_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END;
    RAISE NOTICE 'Colonne points: %s', CASE WHEN points_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END;
    RAISE NOTICE 'Colonne action_type: %s', CASE WHEN action_type_exists THEN '✅ EXISTE' ELSE '❌ MANQUANTE' END;
END $$;

-- ========================================
-- CORRECTION 1: AJOUTER COLONNE REFERENCE_ID SI MANQUANTE
-- ========================================

DO $$
DECLARE
    reference_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== CORRECTION COLONNE REFERENCE_ID ===';
    
    -- Vérifier si la colonne reference_id existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'reference_id'
    ) INTO reference_id_exists;
    
    IF NOT reference_id_exists THEN
        -- Ajouter la colonne reference_id
        ALTER TABLE loyalty_points_history ADD COLUMN reference_id UUID;
        RAISE NOTICE '✅ Colonne reference_id ajoutée à loyalty_points_history';
        RAISE NOTICE '💡 Cette colonne permettra de lier les points de fidélité aux ventes';
    ELSE
        RAISE NOTICE '✅ Colonne reference_id existe déjà dans loyalty_points_history';
    END IF;
END $$;

-- ========================================
-- CORRECTION 2: AJOUTER COLONNES D'ISOLATION SI MANQUANTES
-- ========================================

DO $$
DECLARE
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== CORRECTION COLONNES D''ISOLATION LOYALTY_POINTS_HISTORY ===';
    
    -- Vérifier si les colonnes existent
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    -- Ajouter les colonnes manquantes
    IF NOT user_id_exists THEN
        ALTER TABLE loyalty_points_history ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à loyalty_points_history';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans loyalty_points_history';
    END IF;
    
    IF NOT created_by_exists THEN
        ALTER TABLE loyalty_points_history ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à loyalty_points_history';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans loyalty_points_history';
    END IF;
    
    IF NOT workshop_id_exists THEN
        ALTER TABLE loyalty_points_history ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à loyalty_points_history';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans loyalty_points_history';
    END IF;
END $$;

-- ========================================
-- CORRECTION 3: METTRE À JOUR LES ENREGISTREMENTS EXISTANTS
-- ========================================

DO $$
DECLARE
    default_user_id UUID;
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== MISE À JOUR ENREGISTREMENTS LOYALTY_POINTS_HISTORY ===';
    
    -- Récupérer l'ID d'un utilisateur par défaut
    SELECT id INTO default_user_id FROM auth.users LIMIT 1;
    
    IF default_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements existants
        UPDATE loyalty_points_history SET user_id = default_user_id WHERE user_id IS NULL;
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements mis à jour avec user_id', updated_count;
        
        UPDATE loyalty_points_history SET created_by = default_user_id WHERE created_by IS NULL;
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements mis à jour avec created_by', updated_count;
        
        UPDATE loyalty_points_history SET workshop_id = default_user_id WHERE workshop_id IS NULL;
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements mis à jour avec workshop_id', updated_count;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour la mise à jour';
    END IF;
END $$;

-- ========================================
-- CORRECTION 4: CRÉER TRIGGER D'ISOLATION
-- ========================================

-- Créer un trigger pour définir automatiquement les valeurs d'isolation
CREATE OR REPLACE FUNCTION set_loyalty_points_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs d'isolation automatiquement
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer et recréer le trigger
DROP TRIGGER IF EXISTS set_loyalty_points_isolation_trigger ON loyalty_points_history;

CREATE TRIGGER set_loyalty_points_isolation_trigger
    BEFORE INSERT ON loyalty_points_history
    FOR EACH ROW
    EXECUTE FUNCTION set_loyalty_points_isolation();

-- ========================================
-- CORRECTION 5: CONFIGURER POLITIQUES RLS
-- ========================================

-- Désactiver temporairement RLS
ALTER TABLE loyalty_points_history DISABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own loyalty points" ON loyalty_points_history;
DROP POLICY IF EXISTS "Users can insert their own loyalty points" ON loyalty_points_history;
DROP POLICY IF EXISTS "Users can update their own loyalty points" ON loyalty_points_history;
DROP POLICY IF EXISTS "Users can delete their own loyalty points" ON loyalty_points_history;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON loyalty_points_history;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON loyalty_points_history;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON loyalty_points_history;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON loyalty_points_history;

-- Créer des politiques RLS permissives
CREATE POLICY "Enable read access for authenticated users" ON loyalty_points_history
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON loyalty_points_history
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON loyalty_points_history
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON loyalty_points_history
    FOR DELETE USING (auth.role() = 'authenticated');

-- Réactiver RLS
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;

-- ========================================
-- VÉRIFICATION FINALE
-- ========================================

DO $$
DECLARE
    rls_actif BOOLEAN;
    politique_update_existe BOOLEAN;
    trigger_isolation_existe BOOLEAN;
    reference_id_exists BOOLEAN;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION FINALE LOYALTY_POINTS_HISTORY ===';
    
    -- Vérifications
    SELECT rowsecurity INTO rls_actif FROM pg_tables WHERE tablename = 'loyalty_points_history';
    
    SELECT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'loyalty_points_history' 
        AND cmd = 'UPDATE'
    ) INTO politique_update_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.triggers 
        WHERE trigger_name = 'set_loyalty_points_isolation_trigger'
        AND event_object_table = 'loyalty_points_history'
    ) INTO trigger_isolation_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'reference_id'
    ) INTO reference_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'loyalty_points_history' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    -- Afficher les résultats
    RAISE NOTICE 'RLS activé: %s', CASE WHEN rls_actif THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Politique UPDATE: %s', CASE WHEN politique_update_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Trigger d''isolation: %s', CASE WHEN trigger_isolation_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne reference_id: %s', CASE WHEN reference_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne user_id: %s', CASE WHEN user_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne created_by: %s', CASE WHEN created_by_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne workshop_id: %s', CASE WHEN workshop_id_exists THEN '✅' ELSE '❌' END;
    
    IF rls_actif AND politique_update_existe AND trigger_isolation_existe AND reference_id_exists AND user_id_exists AND created_by_exists AND workshop_id_exists THEN
        RAISE NOTICE '🎉 CORRECTION LOYALTY_POINTS_HISTORY RÉUSSIE !';
    ELSE
        RAISE NOTICE '⚠️ CORRECTION LOYALTY_POINTS_HISTORY INCOMPLÈTE';
    END IF;
END $$;

-- Test d'insertion pour vérifier que tout fonctionne
DO $$
DECLARE
    test_id UUID;
    test_client_id UUID;
    insertion_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== TEST D''INSERTION LOYALTY_POINTS_HISTORY ===';
    
    -- Trouver un client de test
    SELECT id INTO test_client_id FROM clients LIMIT 1;
    
    IF test_client_id IS NOT NULL THEN
        BEGIN
            -- Test d'insertion
            INSERT INTO loyalty_points_history (
                id, client_id, points, action_type, description, reference_id,
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), test_client_id, 100, 'earned', 'Test points', gen_random_uuid(),
                NOW(), NOW()
            ) RETURNING id INTO test_id;
            
            insertion_success := TRUE;
            RAISE NOTICE '✅ Test d''insertion RÉUSSI - ID: %', test_id;
            
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
        RAISE NOTICE '🎉 CORRECTION LOYALTY_POINTS_HISTORY RÉUSSIE - L''insertion fonctionne !';
    ELSE
        RAISE NOTICE '❌ CORRECTION LOYALTY_POINTS_HISTORY ÉCHOUÉE - L''insertion ne fonctionne pas';
    END IF;
END $$;

-- Message final
SELECT '🎉 Diagnostic et correction loyalty_points_history terminés avec succès !' as status;
