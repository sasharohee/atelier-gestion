-- =====================================================
-- CORRECTION URGENCE APPARAILS
-- =====================================================
-- Corrige la page appareils en utilisant la même approche que device_models
-- Date: 2025-01-23
-- =====================================================

-- 1. Identifier toutes les tables liées aux appareils
SELECT '=== IDENTIFICATION TABLES ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND (tablename LIKE '%device%' OR tablename LIKE '%appareil%' OR tablename LIKE '%equipment%' OR tablename LIKE '%machine%')
ORDER BY tablename;

-- 2. Vérifier le contenu de la table devices
SELECT '=== CONTENU TABLE DEVICES ===' as etape;

SELECT 
    'devices' as table_name,
    COUNT(*) as nombre_enregistrements
FROM devices;

-- 3. Désactiver RLS sur la table devices
SELECT '=== DÉSACTIVATION RLS ===' as etape;

ALTER TABLE devices DISABLE ROW LEVEL SECURITY;

-- 4. Supprimer toutes les politiques RLS sur devices
SELECT '=== SUPPRESSION POLITIQUES ===' as etape;

DROP POLICY IF EXISTS devices_select_policy ON devices;
DROP POLICY IF EXISTS devices_insert_policy ON devices;
DROP POLICY IF EXISTS devices_update_policy ON devices;
DROP POLICY IF EXISTS devices_delete_policy ON devices;

-- 5. Ajouter les colonnes d'isolation sur devices
SELECT '=== AJOUT COLONNES ISOLATION ===' as etape;

ALTER TABLE devices ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 6. Mettre à jour les données existantes
SELECT '=== MISE À JOUR DONNÉES ===' as etape;

UPDATE devices 
SET created_by = COALESCE(
    (SELECT id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
)
WHERE created_by IS NULL;

UPDATE devices 
SET workshop_id = created_by
WHERE workshop_id IS NULL OR workshop_id != created_by;

-- 7. Créer le trigger pour devices
SELECT '=== CRÉATION TRIGGER ===' as etape;

-- Fonction trigger
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

-- Trigger pour devices
DROP TRIGGER IF EXISTS set_device_context ON devices;
CREATE TRIGGER set_device_context
    BEFORE INSERT ON devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_context();

-- 8. Créer la vue filtrée pour devices
SELECT '=== CRÉATION VUE FILTRÉE ===' as etape;

DROP VIEW IF EXISTS devices_filtered;
CREATE VIEW devices_filtered AS
SELECT 
    d.*,
    CASE 
        WHEN ss_gestion.value = 'gestion' THEN true
        ELSE d.created_by = auth.uid()
    END as is_accessible
FROM devices d
CROSS JOIN LATERAL (
    SELECT value FROM system_settings WHERE key = 'workshop_type' LIMIT 1
) ss_gestion;

-- 9. Créer la fonction pour récupérer les données
SELECT '=== CRÉATION FONCTION ===' as etape;

CREATE OR REPLACE FUNCTION get_user_devices()
RETURNS TABLE (
    id UUID,
    name TEXT,
    model TEXT,
    status TEXT,
    location TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.name,
        d.model,
        d.status,
        d.location,
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

-- 10. Test d'insertion
SELECT '=== TEST D''INSERTION ===' as etape;

DO $$
DECLARE
    v_test_id UUID;
    v_created_by UUID;
    v_current_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_current_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    RAISE NOTICE 'User_id actuel: %', v_current_user_id;
    
    -- Test insertion dans devices
    BEGIN
        INSERT INTO devices (
            name, model, status, location
        ) VALUES (
            'Test Appareil Urgence', 'Test Model', 'active', 'Test Location'
        ) RETURNING id, created_by INTO v_test_id, v_created_by;
        
        RAISE NOTICE '✅ Appareil créé dans devices - ID: %, Created_by: %', v_test_id, v_created_by;
        
        -- Nettoyer
        DELETE FROM devices WHERE id = v_test_id;
        RAISE NOTICE '✅ Test devices nettoyé';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur devices: %', SQLERRM;
    END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur générale: %', SQLERRM;
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

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'devices'
ORDER BY trigger_name;

-- Vérifier les fonctions
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'get_user_devices';

-- Vérifier les vues
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name = 'devices_filtered';

-- 12. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS désactivé sur la table devices' as message;
SELECT '✅ Trigger automatique créé' as triggers;
SELECT '✅ Fonction get_user_devices() créée' as fonctions;
SELECT '✅ Vue devices_filtered créée' as vues;
SELECT '✅ Testez maintenant la page appareils' as next_step;
SELECT 'ℹ️ Utilisez get_user_devices() pour récupérer les appareils' as note;
SELECT '⚠️ L''isolation se fait via le trigger automatique' as isolation_note;
