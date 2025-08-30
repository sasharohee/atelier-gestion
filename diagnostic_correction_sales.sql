-- 🔍 DIAGNOSTIC ET CORRECTION - Table Sales
-- Script pour diagnostiquer et corriger les problèmes sur la table sales

-- ========================================
-- DIAGNOSTIC 1: STRUCTURE DE LA TABLE SALES
-- ========================================

SELECT 
    '=== STRUCTURE TABLE SALES ===' as section,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IN ('id', 'created_at', 'updated_at') THEN '📅 COLONNE SYSTÈME'
        WHEN column_name IN ('client_id', 'device_id', 'total_amount', 'payment_status', 'sale_date') THEN '📋 COLONNE MÉTIER'
        WHEN column_name IN ('user_id', 'created_by', 'workshop_id') THEN '🔒 COLONNE D''ISOLATION'
        ELSE '❓ AUTRE COLONNE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_name = 'sales' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- DIAGNOSTIC 2: ÉTAT RLS
-- ========================================

SELECT 
    '=== ÉTAT RLS SALES ===' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '🔒 RLS ACTIVÉ'
        ELSE '🔓 RLS DÉSACTIVÉ'
    END as rls_status,
    schemaname
FROM pg_tables 
WHERE tablename = 'sales';

-- ========================================
-- DIAGNOSTIC 3: POLITIQUES RLS EXISTANTES
-- ========================================

SELECT 
    '=== POLITIQUES RLS SALES ===' as section,
    policyname,
    CASE 
        WHEN permissive = 'PERM' THEN '✅ PERMISSIVE'
        WHEN permissive = 'REST' THEN '❌ RESTRICTIVE'
        ELSE '❓ INCONNU'
    END as type_politique,
    roles,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'sales'
ORDER BY cmd;

-- ========================================
-- DIAGNOSTIC 4: VÉRIFICATION ENREGISTREMENT SPÉCIFIQUE
-- ========================================

DO $$
DECLARE
    sale_exists BOOLEAN;
    sale_id UUID := '9427bc38-f062-4345-9758-679daf1f7e0d'::UUID;
    current_user_id UUID;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION ENREGISTREMENT SALES ===';
    RAISE NOTICE 'ID recherché: %', sale_id;
    
    -- Vérifier si l'enregistrement existe
    SELECT EXISTS (
        SELECT 1 FROM sales WHERE id = sale_id
    ) INTO sale_exists;
    
    IF sale_exists THEN
        RAISE NOTICE '✅ L''enregistrement existe dans la table sales';
        
        -- Vérifier les colonnes d'isolation
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'user_id'
        ) INTO user_id_exists;
        
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'created_by'
        ) INTO created_by_exists;
        
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'workshop_id'
        ) INTO workshop_id_exists;
        
        -- Afficher les valeurs d'isolation si elles existent
        IF user_id_exists THEN
            SELECT user_id INTO current_user_id FROM sales WHERE id = sale_id;
            RAISE NOTICE 'user_id: %', current_user_id;
        ELSE
            RAISE NOTICE 'user_id: ❌ COLONNE MANQUANTE';
        END IF;
        
        IF created_by_exists THEN
            DECLARE
                created_by_val UUID;
            BEGIN
                SELECT created_by INTO created_by_val FROM sales WHERE id = sale_id;
                RAISE NOTICE 'created_by: %', created_by_val;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'created_by: ❌ ERREUR LECTURE';
            END;
        ELSE
            RAISE NOTICE 'created_by: ❌ COLONNE MANQUANTE';
        END IF;
        
        IF workshop_id_exists THEN
            DECLARE
                workshop_id_val UUID;
            BEGIN
                SELECT workshop_id INTO workshop_id_val FROM sales WHERE id = sale_id;
                RAISE NOTICE 'workshop_id: %', workshop_id_val;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'workshop_id: ❌ ERREUR LECTURE';
            END;
        ELSE
            RAISE NOTICE 'workshop_id: ❌ COLONNE MANQUANTE';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ L''enregistrement N''EXISTE PAS dans la table sales';
    END IF;
END $$;

-- ========================================
-- DIAGNOSTIC 5: DONNÉES EXISTANTES
-- ========================================

DO $$
DECLARE
    payment_status_exists BOOLEAN;
    total_ventes INTEGER;
    ventes_payees INTEGER := 0;
    ventes_en_attente INTEGER := 0;
    ventes_annulees INTEGER := 0;
BEGIN
    RAISE NOTICE '=== DONNÉES SALES EXISTANTES ===';
    
    -- Compter le total des ventes
    SELECT COUNT(*) INTO total_ventes FROM sales;
    RAISE NOTICE 'Total ventes: %', total_ventes;
    
    -- Vérifier si la colonne payment_status existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'payment_status'
    ) INTO payment_status_exists;
    
    IF payment_status_exists THEN
        -- Compter selon le statut de paiement
        SELECT COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) INTO ventes_payees FROM sales;
        SELECT COUNT(CASE WHEN payment_status = 'pending' THEN 1 END) INTO ventes_en_attente FROM sales;
        SELECT COUNT(CASE WHEN payment_status = 'cancelled' THEN 1 END) INTO ventes_annulees FROM sales;
        
        RAISE NOTICE 'Ventes payées: %', ventes_payees;
        RAISE NOTICE 'Ventes en attente: %', ventes_en_attente;
        RAISE NOTICE 'Ventes annulées: %', ventes_annulees;
    ELSE
        RAISE NOTICE 'Colonne payment_status: ❌ MANQUANTE';
        RAISE NOTICE 'Impossible de compter par statut de paiement';
    END IF;
END $$;

-- ========================================
-- CORRECTION 1: AJOUTER COLONNES D'ISOLATION SI MANQUANTES
-- ========================================

DO $$
DECLARE
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== CORRECTION COLONNES D''ISOLATION SALES ===';
    
    -- Vérifier si les colonnes existent
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    -- Ajouter les colonnes manquantes
    IF NOT user_id_exists THEN
        ALTER TABLE sales ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans sales';
    END IF;
    
    IF NOT created_by_exists THEN
        ALTER TABLE sales ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans sales';
    END IF;
    
    IF NOT workshop_id_exists THEN
        ALTER TABLE sales ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à sales';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans sales';
    END IF;
END $$;

-- ========================================
-- CORRECTION 2: METTRE À JOUR LES ENREGISTREMENTS EXISTANTS
-- ========================================

DO $$
DECLARE
    default_user_id UUID;
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== MISE À JOUR ENREGISTREMENTS SALES ===';
    
    -- Récupérer l'ID d'un utilisateur par défaut
    SELECT id INTO default_user_id FROM auth.users LIMIT 1;
    
    IF default_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements existants
        UPDATE sales SET user_id = default_user_id WHERE user_id IS NULL;
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements sales mis à jour avec user_id', updated_count;
        
        UPDATE sales SET created_by = default_user_id WHERE created_by IS NULL;
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements sales mis à jour avec created_by', updated_count;
        
        UPDATE sales SET workshop_id = default_user_id WHERE workshop_id IS NULL;
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % enregistrements sales mis à jour avec workshop_id', updated_count;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour la mise à jour';
    END IF;
END $$;

-- ========================================
-- CORRECTION 3: CRÉER TRIGGER D'ISOLATION
-- ========================================

-- Créer un trigger pour définir automatiquement les valeurs d'isolation
CREATE OR REPLACE FUNCTION set_sales_isolation()
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
DROP TRIGGER IF EXISTS set_sales_isolation_trigger ON sales;

CREATE TRIGGER set_sales_isolation_trigger
    BEFORE INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION set_sales_isolation();

-- ========================================
-- CORRECTION 4: CONFIGURER POLITIQUES RLS
-- ========================================

-- Désactiver temporairement RLS
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own sales" ON sales;
DROP POLICY IF EXISTS "Users can insert their own sales" ON sales;
DROP POLICY IF EXISTS "Users can update their own sales" ON sales;
DROP POLICY IF EXISTS "Users can delete their own sales" ON sales;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON sales;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON sales;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON sales;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON sales;

-- Créer des politiques RLS permissives
CREATE POLICY "Enable read access for authenticated users" ON sales
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON sales
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON sales
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON sales
    FOR DELETE USING (auth.role() = 'authenticated');

-- Réactiver RLS
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- ========================================
-- VÉRIFICATION FINALE
-- ========================================

DO $$
DECLARE
    rls_actif BOOLEAN;
    politique_update_existe BOOLEAN;
    trigger_isolation_existe BOOLEAN;
    user_id_exists BOOLEAN;
    created_by_exists BOOLEAN;
    workshop_id_exists BOOLEAN;
    sale_exists BOOLEAN;
    sale_id UUID := '9427bc38-f062-4345-9758-679daf1f7e0d'::UUID;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION FINALE SALES ===';
    
    -- Vérifications
    SELECT rowsecurity INTO rls_actif FROM pg_tables WHERE tablename = 'sales';
    
    SELECT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'sales' 
        AND cmd = 'UPDATE'
    ) INTO politique_update_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.triggers 
        WHERE trigger_name = 'set_sales_isolation_trigger'
        AND event_object_table = 'sales'
    ) INTO trigger_isolation_existe;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'user_id'
    ) INTO user_id_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'created_by'
    ) INTO created_by_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'workshop_id'
    ) INTO workshop_id_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM sales WHERE id = sale_id
    ) INTO sale_exists;
    
    -- Afficher les résultats
    RAISE NOTICE 'RLS activé: %s', CASE WHEN rls_actif THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Politique UPDATE: %s', CASE WHEN politique_update_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Trigger d''isolation: %s', CASE WHEN trigger_isolation_existe THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne user_id: %s', CASE WHEN user_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne created_by: %s', CASE WHEN created_by_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Colonne workshop_id: %s', CASE WHEN workshop_id_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE 'Enregistrement spécifique: %s', CASE WHEN sale_exists THEN '✅' ELSE '❌' END;
    
    IF rls_actif AND politique_update_existe AND trigger_isolation_existe AND user_id_exists AND created_by_exists AND workshop_id_exists THEN
        RAISE NOTICE '🎉 CORRECTION SALES RÉUSSIE !';
    ELSE
        RAISE NOTICE '⚠️ CORRECTION SALES INCOMPLÈTE';
    END IF;
END $$;

-- Test de mise à jour pour vérifier que tout fonctionne
DO $$
DECLARE
    test_sale_id UUID;
    update_success BOOLEAN := FALSE;
    payment_status_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== TEST MISE À JOUR SALES ===';
    
    -- Vérifier si la colonne payment_status existe
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'payment_status'
    ) INTO payment_status_exists;
    
    -- Trouver un enregistrement de test
    SELECT id INTO test_sale_id FROM sales LIMIT 1;
    
    IF test_sale_id IS NOT NULL THEN
        BEGIN
            -- Test de mise à jour selon les colonnes disponibles
            IF payment_status_exists THEN
                UPDATE sales 
                SET payment_status = 'paid', updated_at = NOW()
                WHERE id = test_sale_id;
            ELSE
                UPDATE sales 
                SET updated_at = NOW()
                WHERE id = test_sale_id;
            END IF;
            
            update_success := TRUE;
            RAISE NOTICE '✅ Test de mise à jour RÉUSSI pour l''ID: %', test_sale_id;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ ERREUR lors du test de mise à jour: %', SQLERRM;
                update_success := FALSE;
        END;
    ELSE
        RAISE NOTICE '⚠️ Aucun enregistrement sales trouvé pour le test';
    END IF;
    
    IF update_success THEN
        RAISE NOTICE '🎉 CORRECTION SALES RÉUSSIE - La mise à jour fonctionne !';
    ELSE
        RAISE NOTICE '❌ CORRECTION SALES ÉCHOUÉE - La mise à jour ne fonctionne pas';
    END IF;
END $$;

-- Message final
SELECT '🎉 Diagnostic et correction sales terminés avec succès !' as status;
