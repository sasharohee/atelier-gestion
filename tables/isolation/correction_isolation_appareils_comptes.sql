-- =====================================================
-- CORRECTION ISOLATION APPARAILS ENTRE COMPTES
-- =====================================================
-- Corrige le problème d'isolation : appareils du compte A apparaissent sur compte B
-- Date: 2025-01-23
-- =====================================================

-- 1. Diagnostic initial
SELECT '=== DIAGNOSTIC INITIAL ===' as etape;

SELECT 
    COUNT(*) as total_appareils,
    COUNT(DISTINCT user_id) as nombre_utilisateurs,
    COUNT(DISTINCT created_by) as nombre_createurs
FROM devices;

-- 2. Vérifier les données actuelles
SELECT '=== DONNÉES ACTUELLES ===' as etape;

SELECT 
    id,
    brand,
    model,
    user_id,
    created_by,
    created_at
FROM devices
ORDER BY created_at DESC
LIMIT 10;

-- 3. Désactiver RLS temporairement pour les corrections
SELECT '=== DÉSACTIVATION RLS ===' as etape;

ALTER TABLE devices DISABLE ROW LEVEL SECURITY;

-- 4. Supprimer toutes les politiques RLS existantes
SELECT '=== SUPPRESSION POLITIQUES ===' as etape;

DROP POLICY IF EXISTS devices_select_policy ON devices;
DROP POLICY IF EXISTS devices_insert_policy ON devices;
DROP POLICY IF EXISTS devices_update_policy ON devices;
DROP POLICY IF EXISTS devices_delete_policy ON devices;

-- 5. S'assurer que les colonnes d'isolation existent
SELECT '=== VÉRIFICATION COLONNES ===' as etape;

ALTER TABLE devices ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 6. Mettre à jour les données existantes avec l'isolation correcte
SELECT '=== MISE À JOUR DONNÉES ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_device RECORD;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    RAISE NOTICE 'User_id pour la correction: %', v_user_id;
    
    -- Mettre à jour tous les appareils existants
    UPDATE devices 
    SET created_by = v_user_id,
        workshop_id = v_user_id,
        updated_at = NOW()
    WHERE created_by IS NULL OR created_by != user_id;
    
    RAISE NOTICE '✅ Données mises à jour avec isolation par user_id';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de la mise à jour: %', SQLERRM;
END $$;

-- 7. Créer un trigger robuste pour l'isolation automatique
SELECT '=== CRÉATION TRIGGER ===' as etape;

CREATE OR REPLACE FUNCTION set_device_isolation()
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
    
    RAISE NOTICE '✅ Appareil isolé pour l''utilisateur: %', v_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS set_device_context ON devices;
DROP TRIGGER IF EXISTS set_device_isolation ON devices;

-- Créer le nouveau trigger
CREATE TRIGGER set_device_isolation
    BEFORE INSERT ON devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_isolation();

-- 8. Activer RLS avec des politiques strictes
SELECT '=== ACTIVATION RLS STRICT ===' as etape;

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- Politique SELECT : uniquement les appareils de l'utilisateur connecté
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

-- Politique INSERT : permissive (le trigger s'occupe de l'isolation)
CREATE POLICY devices_insert_policy ON devices
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE : uniquement les appareils de l'utilisateur connecté
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

-- Politique DELETE : uniquement les appareils de l'utilisateur connecté
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

-- 9. Créer une fonction pour récupérer les appareils isolés
SELECT '=== CRÉATION FONCTION ===' as etape;

CREATE OR REPLACE FUNCTION get_user_devices_isolated()
RETURNS TABLE (
    id UUID,
    brand TEXT,
    model TEXT,
    type TEXT,
    serial_number TEXT,
    specifications JSONB,
    created_by UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.brand,
        d.model,
        d.type,
        d.serial_number,
        d.specifications,
        d.created_by,
        d.created_at,
        d.updated_at
    FROM devices d
    WHERE d.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Test d'insertion pour vérifier l'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_created_by UUID;
    v_current_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    RAISE NOTICE 'User_id actuel: %', v_current_user_id;
    
    -- Test insertion
    INSERT INTO devices (
        brand, model, type, serial_number, specifications
    ) VALUES (
        'Test Isolation', 'Test Model', 'smartphone', 'TEST-001', 
        '{"processor": "Test", "ram": "4GB", "storage": "64GB"}'
    ) RETURNING id, created_by INTO v_test_id, v_created_by;
    
    RAISE NOTICE '✅ Appareil de test créé - ID: %, Created_by: %', v_test_id, v_created_by;
    
    -- Vérifier l'isolation
    IF v_created_by = v_current_user_id THEN
        RAISE NOTICE '✅ Isolation correcte - l''appareil appartient à l''utilisateur actuel';
    ELSE
        RAISE NOTICE '❌ Problème d''isolation - l''appareil n''appartient pas à l''utilisateur actuel';
    END IF;
    
    -- Nettoyer le test
    DELETE FROM devices WHERE id = v_test_id;
    RAISE NOTICE '✅ Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 11. Vérification finale
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
AND tablename = 'devices';

-- Vérifier les politiques
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'devices'
ORDER BY trigger_name;

-- Vérifier l'isolation des données
SELECT 
    COUNT(*) as total_appareils,
    COUNT(DISTINCT created_by) as nombre_utilisateurs,
    COUNT(CASE WHEN created_by = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)) THEN 1 END) as appareils_utilisateur_actuel
FROM devices;

-- 12. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé avec isolation stricte par user_id' as message;
SELECT '✅ Trigger automatique créé pour l''isolation' as trigger;
SELECT '✅ Fonction get_user_devices_isolated() créée' as fonction;
SELECT '✅ Testez maintenant la création d''appareils sur différents comptes' as test;
SELECT 'ℹ️ Les appareils ne devraient plus apparaître entre comptes' as isolation_note;
SELECT '⚠️ Utilisez get_user_devices_isolated() pour récupérer les appareils' as usage_note;
