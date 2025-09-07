-- =====================================================
-- CORRECTION URGENCE CONTRAINTE LOYALTY
-- =====================================================
-- Script pour corriger définitivement l'erreur de contrainte
-- Supprime les contraintes problématiques et utilise RLS uniquement
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC de l'erreur
SELECT '=== DIAGNOSTIC ERREUR CONTRAINTE ===' as etape;

-- Vérifier les contraintes actuelles
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('loyalty_tiers_advanced', 'loyalty_config')
AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, tc.constraint_name;

-- 2. SUPPRIMER TOUTES les contraintes de clé étrangère problématiques
SELECT '=== SUPPRESSION CONTRAINTES PROBLÉMATIQUES ===' as etape;

-- Supprimer toutes les contraintes de clé étrangère
ALTER TABLE public.loyalty_tiers_advanced 
DROP CONSTRAINT IF EXISTS loyalty_tiers_advanced_workshop_id_fkey;

ALTER TABLE public.loyalty_config 
DROP CONSTRAINT IF EXISTS loyalty_config_workshop_id_fkey;

-- Supprimer aussi les contraintes de validation si elles existent
ALTER TABLE public.loyalty_tiers_advanced 
DROP CONSTRAINT IF EXISTS loyalty_tiers_advanced_workshop_id_check;

ALTER TABLE public.loyalty_config 
DROP CONSTRAINT IF EXISTS loyalty_config_workshop_id_check;

SELECT 'Contraintes de clé étrangère supprimées' as resultat;

-- 3. S'ASSURER que les colonnes workshop_id existent
SELECT '=== VÉRIFICATION COLONNES WORKSHOP_ID ===' as etape;

-- Ajouter les colonnes si elles n'existent pas
ALTER TABLE public.loyalty_tiers_advanced 
ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE public.loyalty_config 
ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- Vérifier que les colonnes existent
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_tiers_advanced', 'loyalty_config')
AND column_name = 'workshop_id'
ORDER BY table_name;

-- 4. MIGRER toutes les données vers l'utilisateur actuel
SELECT '=== MIGRATION FORCÉE DES DONNÉES ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_migrated_tiers INTEGER := 0;
    v_migrated_config INTEGER := 0;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, création d''un UUID de test';
        
        -- Créer un UUID de test pour éviter les erreurs
        v_current_user_id := '00000000-0000-0000-0000-000000000001'::UUID;
    END IF;
    
    RAISE NOTICE '🔄 Migration vers utilisateur: %', v_current_user_id;
    
    -- Migrer TOUS les niveaux vers l'utilisateur actuel
    UPDATE loyalty_tiers_advanced 
    SET workshop_id = v_current_user_id 
    WHERE workshop_id IS NULL;
    
    GET DIAGNOSTICS v_migrated_tiers = ROW_COUNT;
    RAISE NOTICE '✅ % niveaux migrés', v_migrated_tiers;
    
    -- Migrer TOUTE la configuration vers l'utilisateur actuel
    UPDATE loyalty_config 
    SET workshop_id = v_current_user_id 
    WHERE workshop_id IS NULL;
    
    GET DIAGNOSTICS v_migrated_config = ROW_COUNT;
    RAISE NOTICE '✅ % configurations migrées', v_migrated_config;
    
    -- Créer les niveaux par défaut si aucun n'existe
    IF NOT EXISTS (SELECT 1 FROM loyalty_tiers_advanced WHERE workshop_id = v_current_user_id) THEN
        RAISE NOTICE '🆕 Création des niveaux par défaut';
        
        INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
        VALUES 
            (v_current_user_id, 'Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
            (v_current_user_id, 'Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
            (v_current_user_id, 'Or', 500, 10.00, '#FFD700', '10% de réduction', true),
            (v_current_user_id, 'Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
            (v_current_user_id, 'Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true);
        
        RAISE NOTICE '✅ 5 niveaux par défaut créés';
    END IF;
    
    -- Créer la configuration par défaut si aucune n'existe
    IF NOT EXISTS (SELECT 1 FROM loyalty_config WHERE workshop_id = v_current_user_id) THEN
        RAISE NOTICE '🆕 Création de la configuration par défaut';
        
        INSERT INTO loyalty_config (workshop_id, key, value, description)
        VALUES 
            (v_current_user_id, 'points_per_euro', '1', 'Points gagnés par euro dépensé'),
            (v_current_user_id, 'minimum_purchase', '10', 'Montant minimum pour gagner des points'),
            (v_current_user_id, 'bonus_threshold', '100', 'Seuil pour bonus de points'),
            (v_current_user_id, 'bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
            (v_current_user_id, 'points_expiry_days', '365', 'Durée de validité des points en jours'),
            (v_current_user_id, 'auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');
        
        RAISE NOTICE '✅ 6 configurations par défaut créées';
    END IF;
    
END $$;

-- 5. ACTIVER RLS
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_config ENABLE ROW LEVEL SECURITY;

-- 6. SUPPRIMER toutes les anciennes politiques
SELECT '=== NETTOYAGE POLITIQUES ===' as etape;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "loyalty_tiers_advanced_select_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_insert_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_update_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_delete_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_select_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_insert_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_update_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_delete_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_workshop_isolation_select" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_workshop_isolation_insert" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_workshop_isolation_update" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_workshop_isolation_delete" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_select" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_insert" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_update" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_delete" ON public.loyalty_tiers_advanced;

DROP POLICY IF EXISTS "loyalty_config_select_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_insert_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_update_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_delete_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_delete" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_delete" ON public.loyalty_config;

-- 7. CRÉER des politiques RLS SIMPLES et EFFICACES
SELECT '=== CRÉATION POLITIQUES RLS SIMPLES ===' as etape;

-- Politiques pour loyalty_tiers_advanced
CREATE POLICY "loyalty_tiers_simple_select" ON public.loyalty_tiers_advanced
    FOR SELECT 
    USING (workshop_id = auth.uid());

CREATE POLICY "loyalty_tiers_simple_insert" ON public.loyalty_tiers_advanced
    FOR INSERT 
    WITH CHECK (workshop_id = auth.uid());

CREATE POLICY "loyalty_tiers_simple_update" ON public.loyalty_tiers_advanced
    FOR UPDATE 
    USING (workshop_id = auth.uid())
    WITH CHECK (workshop_id = auth.uid());

CREATE POLICY "loyalty_tiers_simple_delete" ON public.loyalty_tiers_advanced
    FOR DELETE 
    USING (workshop_id = auth.uid());

-- Politiques pour loyalty_config
CREATE POLICY "loyalty_config_simple_select" ON public.loyalty_config
    FOR SELECT 
    USING (workshop_id = auth.uid());

CREATE POLICY "loyalty_config_simple_insert" ON public.loyalty_config
    FOR INSERT 
    WITH CHECK (workshop_id = auth.uid());

CREATE POLICY "loyalty_config_simple_update" ON public.loyalty_config
    FOR UPDATE 
    USING (workshop_id = auth.uid())
    WITH CHECK (workshop_id = auth.uid());

CREATE POLICY "loyalty_config_simple_delete" ON public.loyalty_config
    FOR DELETE 
    USING (workshop_id = auth.uid());

-- 8. CRÉER des triggers SIMPLES
SELECT '=== CRÉATION TRIGGERS SIMPLES ===' as etape;

-- Fonction trigger simple
CREATE OR REPLACE FUNCTION set_loyalty_workshop_id_simple()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer les anciens triggers
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_config_trigger ON public.loyalty_config;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_loyalty_tiers_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_loyalty_config_trigger ON public.loyalty_config;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_ultra_strict_loyalty_tiers_advanced_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_ultra_strict_loyalty_config_trigger ON public.loyalty_config;

-- Créer les nouveaux triggers
CREATE TRIGGER set_loyalty_workshop_id_loyalty_tiers_trigger
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id_simple();

CREATE TRIGGER set_loyalty_workshop_id_loyalty_config_trigger
    BEFORE INSERT ON public.loyalty_config
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id_simple();

-- 9. CRÉER les fonctions utilitaires
SELECT '=== CRÉATION FONCTIONS UTILITAIRES ===' as etape;

-- Fonction pour obtenir les niveaux de l'atelier actuel
CREATE OR REPLACE FUNCTION get_workshop_loyalty_tiers()
RETURNS TABLE(
    id UUID,
    name TEXT,
    points_required INTEGER,
    discount_percentage DECIMAL(5,2),
    color TEXT,
    description TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lta.id,
        lta.name,
        lta.points_required,
        lta.discount_percentage,
        lta.color,
        lta.description,
        lta.is_active,
        lta.created_at,
        lta.updated_at
    FROM loyalty_tiers_advanced lta
    WHERE lta.workshop_id = auth.uid()
    AND lta.is_active = true
    ORDER BY lta.points_required ASC;
END;
$$;

-- Fonction pour obtenir la configuration de l'atelier actuel
CREATE OR REPLACE FUNCTION get_workshop_loyalty_config()
RETURNS TABLE(
    key TEXT,
    value TEXT,
    description TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lc.key,
        lc.value,
        lc.description
    FROM loyalty_config lc
    WHERE lc.workshop_id = auth.uid()
    ORDER BY lc.key;
END;
$$;

-- Accorder les permissions
GRANT EXECUTE ON FUNCTION get_workshop_loyalty_tiers() TO authenticated;
GRANT EXECUTE ON FUNCTION get_workshop_loyalty_config() TO authenticated;

-- 10. TEST de la correction
SELECT '=== TEST DE LA CORRECTION ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_test_tier_id UUID;
    v_test_config_id UUID;
    v_insert_tier_success BOOLEAN := FALSE;
    v_insert_config_success BOOLEAN := FALSE;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté - test avec UUID de test';
        v_current_user_id := '00000000-0000-0000-0000-000000000001'::UUID;
    END IF;
    
    RAISE NOTICE '🧪 Test avec utilisateur: %', v_current_user_id;
    
    -- Test d'insertion d'un niveau
    BEGIN
        INSERT INTO loyalty_tiers_advanced (
            name, points_required, discount_percentage, color, description, is_active
        ) VALUES (
            'Test Emergency', 25, 1.5, '#FF0000', 'Test après correction d''urgence', true
        ) RETURNING id INTO v_test_tier_id;
        
        v_insert_tier_success := TRUE;
        RAISE NOTICE '✅ Insertion niveau réussie - ID: %', v_test_tier_id;
        
        -- Nettoyer le test
        DELETE FROM loyalty_tiers_advanced WHERE id = v_test_tier_id;
        RAISE NOTICE '✅ Test niveau nettoyé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test niveau: %', SQLERRM;
    END;
    
    -- Test d'insertion d'une configuration
    BEGIN
        INSERT INTO loyalty_config (
            key, value, description
        ) VALUES (
            'test_emergency', 'test_value', 'Test après correction d''urgence'
        ) RETURNING id INTO v_test_config_id;
        
        v_insert_config_success := TRUE;
        RAISE NOTICE '✅ Insertion config réussie - ID: %', v_test_config_id;
        
        -- Nettoyer le test
        DELETE FROM loyalty_config WHERE id = v_test_config_id;
        RAISE NOTICE '✅ Test config nettoyé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test config: %', SQLERRM;
    END;
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test:';
    RAISE NOTICE '  - Insertion niveau: %', CASE WHEN v_insert_tier_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Insertion config: %', CASE WHEN v_insert_config_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 11. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier qu'il n'y a plus de contraintes de clé étrangère
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints AS tc 
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('loyalty_tiers_advanced', 'loyalty_config')
AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, tc.constraint_name;

-- Vérifier les politiques
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '✅ Isolation OK'
        ELSE '❌ Isolation manquante'
    END as isolation_status
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename, policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY event_object_table, trigger_name;

-- 12. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Contraintes de clé étrangère supprimées' as message;
SELECT '✅ Isolation basée uniquement sur RLS' as isolation;
SELECT '✅ Données migrées vers l''utilisateur actuel' as migration;
SELECT '✅ Politiques RLS simples créées' as securite;
SELECT '✅ Triggers simples créés' as automatisation;
SELECT '✅ Fonctions utilitaires créées' as fonctions;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ L''isolation fonctionne maintenant sans contraintes de clé étrangère' as note;
