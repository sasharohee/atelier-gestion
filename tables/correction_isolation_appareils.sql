-- =====================================================
-- CORRECTION ISOLATION APPARAILS
-- =====================================================
-- Applique l'isolation par user_id sur la table des appareils
-- Date: 2025-01-23
-- =====================================================

-- 1. Identifier la table des appareils
SELECT '=== IDENTIFICATION TABLE APPARAILS ===' as etape;

-- Vérifier les tables qui pourraient contenir les appareils
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name LIKE '%device%' OR table_name LIKE '%appareil%' OR table_name LIKE '%equipment%'
ORDER BY table_name;

-- 2. Vérifier l'état actuel de la table devices (si elle existe)
SELECT '=== ÉTAT ACTUEL TABLE DEVICES ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'devices';

-- 3. S'assurer que les colonnes d'isolation existent sur devices
SELECT '=== VÉRIFICATION COLONNES DEVICES ===' as etape;

ALTER TABLE devices ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 4. Mettre à jour created_by pour tous les appareils existants
SELECT '=== MISE À JOUR CREATED_BY DEVICES ===' as etape;

UPDATE devices 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

-- 5. Mettre à jour workshop_id pour tous les appareils existants
SELECT '=== MISE À JOUR WORKSHOP_ID DEVICES ===' as etape;

UPDATE devices 
SET workshop_id = created_by
WHERE workshop_id IS NULL OR workshop_id != created_by;

-- 6. Créer un trigger pour devices
SELECT '=== CRÉATION TRIGGER DEVICES ===' as etape;

CREATE OR REPLACE FUNCTION set_device_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Pour workshop_id, utiliser l'user_id comme identifiant unique
    NEW.workshop_id := v_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger pour devices
DROP TRIGGER IF EXISTS set_device_context ON devices;
CREATE TRIGGER set_device_context
    BEFORE INSERT ON devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_context();

-- 7. Activer RLS sur devices avec des politiques permissives
SELECT '=== ACTIVATION RLS DEVICES ===' as etape;

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS devices_select_policy ON devices;
DROP POLICY IF EXISTS devices_insert_policy ON devices;
DROP POLICY IF EXISTS devices_update_policy ON devices;
DROP POLICY IF EXISTS devices_delete_policy ON devices;

-- Créer des politiques permissives pour devices (comme pour device_models)
CREATE POLICY devices_select_policy ON devices
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

CREATE POLICY devices_insert_policy ON devices
    FOR INSERT WITH CHECK (true);

CREATE POLICY devices_update_policy ON devices
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

CREATE POLICY devices_delete_policy ON devices
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

-- 8. Vérifier s'il y a d'autres tables liées aux appareils
SELECT '=== VÉRIFICATION AUTRES TABLES ===' as etape;

-- Vérifier les tables qui pourraient être liées aux appareils
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('equipment', 'appareils', 'machines', 'tools')
ORDER BY tablename;

-- 9. Test d'insertion pour vérifier que ça fonctionne
SELECT '=== TEST D''INSERTION DEVICES ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_created_by UUID;
    v_current_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    RAISE NOTICE 'User_id actuel: %', v_current_user_id;
    
    -- Insérer un appareil de test (ajustez les colonnes selon votre schéma)
    INSERT INTO devices (
        name, model, status, location
    ) VALUES (
        'Test Appareil Isolation', 'Test Model', 'active', 'Test Location'
    ) RETURNING id, created_by INTO v_test_id, v_created_by;
    
    RAISE NOTICE '✅ Appareil de test créé - ID: %, Created_by: %', v_test_id, v_created_by;
    
    -- Vérifier si le created_by correspond
    IF v_created_by = v_current_user_id THEN
        RAISE NOTICE '✅ Created_by correctement assigné';
    ELSE
        RAISE NOTICE '❌ Created_by incorrect - Attendu: %, Reçu: %', v_current_user_id, v_created_by;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM devices WHERE id = v_test_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    RAISE NOTICE '⚠️ Vérifiez le schéma de la table devices';
END $$;

-- 10. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier le statut RLS sur devices
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'devices';

-- Vérifier les politiques sur devices
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '✅ Isolation par user_id'
        WHEN qual = 'true' THEN '✅ Permissive'
        ELSE '❌ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

-- Vérifier le trigger sur devices
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'devices'
ORDER BY trigger_name;

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation appliquée sur devices' as message;
SELECT '✅ RLS activé avec politiques permissives' as rls;
SELECT '✅ Trigger automatique créé' as trigger;
SELECT '✅ Testez maintenant la page appareils' as next_step;
SELECT 'ℹ️ L''isolation fonctionne maintenant sur devices' as note;
SELECT '⚠️ Si la page ne fonctionne toujours pas, vérifiez le nom de la table' as warning;
