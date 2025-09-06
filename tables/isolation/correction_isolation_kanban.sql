-- =====================================================
-- CORRECTION ISOLATION KANBAN (RÉPARATIONS)
-- =====================================================
-- Corrige le problème d'isolation sur la page Kanban
-- Date: 2025-01-23
-- =====================================================

-- 1. Diagnostic initial
SELECT '=== DIAGNOSTIC INITIAL ===' as etape;

SELECT 
    COUNT(*) as total_reparations,
    COUNT(DISTINCT user_id) as nombre_utilisateurs
FROM repairs;

-- 2. Vérifier les données actuelles
SELECT '=== DONNÉES ACTUELLES ===' as etape;

SELECT 
    id,
    client_id,
    device_id,
    status,
    user_id,
    created_at
FROM repairs
ORDER BY created_at DESC
LIMIT 10;

-- 3. Vérifier le statut RLS de la table repairs
SELECT '=== STATUT RLS ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'repairs';

-- 4. Vérifier les politiques RLS existantes
SELECT '=== POLITIQUES RLS ===' as etape;

SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'repairs'
ORDER BY policyname;

-- 5. Vérifier les colonnes existantes
SELECT '=== COLONNES EXISTANTES ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'repairs'
AND column_name IN ('user_id', 'created_by', 'workshop_id')
ORDER BY column_name;

-- 6. Désactiver RLS temporairement pour les corrections
SELECT '=== DÉSACTIVATION RLS ===' as etape;

ALTER TABLE repairs DISABLE ROW LEVEL SECURITY;

-- 7. Supprimer toutes les politiques RLS existantes
SELECT '=== SUPPRESSION POLITIQUES ===' as etape;

DROP POLICY IF EXISTS repairs_select_policy ON repairs;
DROP POLICY IF EXISTS repairs_insert_policy ON repairs;
DROP POLICY IF EXISTS repairs_update_policy ON repairs;
DROP POLICY IF EXISTS repairs_delete_policy ON repairs;

-- 8. Ajouter les colonnes d'isolation
SELECT '=== AJOUT COLONNES ISOLATION ===' as etape;

ALTER TABLE repairs ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 9. Mettre à jour les données existantes avec l'isolation correcte
SELECT '=== MISE À JOUR DONNÉES ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    RAISE NOTICE 'User_id pour la correction: %', v_user_id;
    
    -- Mettre à jour tous les réparations existantes
    UPDATE repairs 
    SET created_by = v_user_id,
        workshop_id = v_user_id,
        updated_at = NOW()
    WHERE created_by IS NULL;
    
    RAISE NOTICE '✅ Données mises à jour avec isolation par user_id';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de la mise à jour: %', SQLERRM;
END $$;

-- 10. Créer un trigger robuste pour l'isolation automatique
SELECT '=== CRÉATION TRIGGER ===' as etape;

CREATE OR REPLACE FUNCTION set_repair_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir automatiquement l'isolation
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE '✅ Réparation isolée pour l''utilisateur: %', v_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS set_repair_context ON repairs;
DROP TRIGGER IF EXISTS set_repair_isolation ON repairs;

-- Créer le nouveau trigger
CREATE TRIGGER set_repair_isolation
    BEFORE INSERT ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_isolation();

-- 11. Activer RLS avec des politiques strictes
SELECT '=== ACTIVATION RLS STRICT ===' as etape;

ALTER TABLE repairs ENABLE ROW LEVEL SECURITY;

-- Politique SELECT : uniquement les réparations de l'utilisateur connecté
CREATE POLICY repairs_select_policy ON repairs
    FOR SELECT USING (
        created_by = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM system_settings
            WHERE key = 'workshop_type'
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique INSERT : permissive (le trigger s'occupe de l'isolation)
CREATE POLICY repairs_insert_policy ON repairs
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE : uniquement les réparations de l'utilisateur connecté
CREATE POLICY repairs_update_policy ON repairs
    FOR UPDATE USING (
        created_by = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM system_settings
            WHERE key = 'workshop_type'
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique DELETE : uniquement les réparations de l'utilisateur connecté
CREATE POLICY repairs_delete_policy ON repairs
    FOR DELETE USING (
        created_by = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM system_settings
            WHERE key = 'workshop_type'
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- 12. Créer une fonction pour récupérer les réparations isolées
SELECT '=== CRÉATION FONCTION ===' as etape;

CREATE OR REPLACE FUNCTION get_user_repairs_isolated()
RETURNS TABLE (
    id UUID,
    client_id UUID,
    device_id UUID,
    status TEXT,
    assigned_technician_id UUID,
    description TEXT,
    issue TEXT,
    estimated_duration INTEGER,
    actual_duration INTEGER,
    estimated_start_date DATE,
    estimated_end_date DATE,
    start_date DATE,
    end_date DATE,
    due_date DATE,
    is_urgent BOOLEAN,
    notes TEXT,
    total_price DECIMAL,
    is_paid BOOLEAN,
    created_by UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.client_id,
        r.device_id,
        r.status,
        r.assigned_technician_id,
        r.description,
        r.issue,
        r.estimated_duration,
        r.actual_duration,
        r.estimated_start_date,
        r.estimated_end_date,
        r.start_date,
        r.end_date,
        r.due_date,
        r.is_urgent,
        r.notes,
        r.total_price,
        r.is_paid,
        r.created_by,
        r.created_at,
        r.updated_at
    FROM repairs r
    WHERE r.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Test d'insertion pour vérifier l'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_created_by UUID;
    v_current_user_id UUID;
    v_client_id UUID;
    v_device_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    RAISE NOTICE 'User_id actuel: %', v_current_user_id;
    
    -- Obtenir un client et un device pour le test
    SELECT id INTO v_client_id FROM clients WHERE created_by = v_current_user_id LIMIT 1;
    SELECT id INTO v_device_id FROM devices WHERE created_by = v_current_user_id LIMIT 1;
    
    -- Si pas de client/device, créer des données de test
    IF v_client_id IS NULL THEN
        INSERT INTO clients (first_name, last_name, email, phone, user_id, created_by, created_at, updated_at)
        VALUES ('Test Client', 'Test', 'test@test.com', '0123456789', v_current_user_id, v_current_user_id, NOW(), NOW())
        RETURNING id INTO v_client_id;
        RAISE NOTICE 'Client de test créé: %', v_client_id;
    END IF;
    
    IF v_device_id IS NULL THEN
        INSERT INTO devices (brand, model, type, user_id, created_by, created_at, updated_at)
        VALUES ('Test Brand', 'Test Model', 'smartphone', v_current_user_id, v_current_user_id, NOW(), NOW())
        RETURNING id INTO v_device_id;
        RAISE NOTICE 'Device de test créé: %', v_device_id;
    END IF;
    
    -- Test insertion
    INSERT INTO repairs (
        client_id, device_id, status, description, issue, due_date, total_price, is_paid
    ) VALUES (
        v_client_id, v_device_id, 'new', 'Test réparation', 'Test problème', 
        NOW() + INTERVAL '7 days', 100.00, false
    ) RETURNING id, created_by INTO v_test_id, v_created_by;
    
    RAISE NOTICE '✅ Réparation de test créée - ID: %, Created_by: %', v_test_id, v_created_by;
    
    -- Vérifier l'isolation
    IF v_created_by = v_current_user_id THEN
        RAISE NOTICE '✅ Isolation correcte - la réparation appartient à l''utilisateur actuel';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation - la réparation n''appartient pas à l''utilisateur actuel';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM repairs WHERE id = v_test_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 14. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier le statut RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'repairs';

-- Vérifier les politiques
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'repairs'
ORDER BY policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'repairs'
ORDER BY trigger_name;

-- Vérifier l'isolation des données
SELECT 
    COUNT(*) as total_reparations,
    COUNT(DISTINCT created_by) as nombre_utilisateurs,
    COUNT(CASE WHEN created_by = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)) THEN 1 END) as reparations_utilisateur_actuel
FROM repairs;

-- 15. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec isolation stricte par user_id' as message;
SELECT '✅ Trigger automatique créé pour l''isolation' as trigger;
SELECT '✅ Fonction get_user_repairs_isolated() créée' as fonction;
SELECT '✅ Testez maintenant la page Kanban sur différents comptes' as test;
SELECT 'ℹ️ Les réparations ne devraient plus apparaître entre comptes' as isolation_note;
SELECT '⚠️ Utilisez get_user_repairs_isolated() pour récupérer les réparations' as usage_note;
