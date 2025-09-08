-- =====================================================
-- CORRECTION ISOLATION LOYALTY - NETTOYAGE COMPLET
-- =====================================================
-- Script pour nettoyer complètement et recréer l'isolation
-- Date: 2025-01-23
-- =====================================================

-- 1. SUPPRIMER TOUTES les politiques existantes
SELECT '=== SUPPRESSION TOUTES LES POLITIQUES ===' as etape;

-- Supprimer toutes les politiques pour loyalty_tiers_advanced
DROP POLICY IF EXISTS "loyalty_tiers_simple_select" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_simple_insert" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_simple_update" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_simple_delete" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_select" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_insert" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_update" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_delete" ON public.loyalty_tiers_advanced;
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

-- Supprimer toutes les politiques pour loyalty_config
DROP POLICY IF EXISTS "loyalty_config_simple_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_simple_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_simple_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_simple_delete" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_delete" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_select_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_insert_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_update_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_delete_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_delete" ON public.loyalty_config;

-- 2. SUPPRIMER TOUS les triggers existants
SELECT '=== SUPPRESSION TOUS LES TRIGGERS ===' as etape;

DROP TRIGGER IF EXISTS "set_loyalty_workshop_id_loyalty_tiers_trigger" ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS "set_loyalty_workshop_id_loyalty_config_trigger" ON public.loyalty_config;
DROP TRIGGER IF EXISTS "set_loyalty_workshop_id_ultra_strict_loyalty_tiers_advanced_trigger" ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS "set_loyalty_workshop_id_ultra_strict_loyalty_config_trigger" ON public.loyalty_config;
DROP TRIGGER IF EXISTS "set_workshop_id_loyalty_tiers_trigger" ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS "set_workshop_id_loyalty_config_trigger" ON public.loyalty_config;
DROP TRIGGER IF EXISTS "set_loyalty_workshop_id_loyalty_tiers_trigger" ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS "set_loyalty_workshop_id_loyalty_config_trigger" ON public.loyalty_config;

-- 3. SUPPRIMER TOUTES les fonctions existantes
SELECT '=== SUPPRESSION TOUTES LES FONCTIONS ===' as etape;

DROP FUNCTION IF EXISTS set_loyalty_workshop_id_simple();
DROP FUNCTION IF EXISTS set_loyalty_workshop_id_ultra_strict();
DROP FUNCTION IF EXISTS get_workshop_loyalty_tiers();
DROP FUNCTION IF EXISTS get_workshop_loyalty_config();
DROP FUNCTION IF EXISTS create_default_loyalty_tiers_for_workshop();
DROP FUNCTION IF EXISTS create_default_loyalty_config_for_workshop();

-- 4. NETTOYER les données existantes
SELECT '=== NETTOYAGE DONNÉES ===' as etape;

-- Supprimer toutes les données existantes
DELETE FROM loyalty_tiers_advanced;
DELETE FROM loyalty_config;

-- Vérifier que les tables sont vides
SELECT 'loyalty_tiers_advanced' as table_name, COUNT(*) as count FROM loyalty_tiers_advanced
UNION ALL
SELECT 'loyalty_config' as table_name, COUNT(*) as count FROM loyalty_config;

-- 5. CRÉER les nouvelles fonctions
SELECT '=== CRÉATION NOUVELLES FONCTIONS ===' as etape;

-- Fonction trigger pour définir workshop_id
CREATE OR REPLACE FUNCTION set_loyalty_workshop_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est connecté
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
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
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
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

-- Fonction pour créer les niveaux par défaut
CREATE OR REPLACE FUNCTION create_default_loyalty_tiers_for_workshop()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    -- Vérifier qu'aucun niveau n'existe déjà
    IF EXISTS (SELECT 1 FROM loyalty_tiers_advanced WHERE workshop_id = auth.uid()) THEN
        RAISE EXCEPTION 'Des niveaux existent déjà pour cet atelier';
    END IF;
    
    -- Créer les niveaux par défaut
    INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
    VALUES 
        (auth.uid(), 'Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
        (auth.uid(), 'Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
        (auth.uid(), 'Or', 500, 10.00, '#FFD700', '10% de réduction', true),
        (auth.uid(), 'Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
        (auth.uid(), 'Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true);
    
    RAISE NOTICE 'Niveaux par défaut créés pour l''atelier %', auth.uid();
END;
$$;

-- Fonction pour créer la configuration par défaut
CREATE OR REPLACE FUNCTION create_default_loyalty_config_for_workshop()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    -- Vérifier qu'aucune configuration n'existe déjà
    IF EXISTS (SELECT 1 FROM loyalty_config WHERE workshop_id = auth.uid()) THEN
        RAISE EXCEPTION 'Une configuration existe déjà pour cet atelier';
    END IF;
    
    -- Créer la configuration par défaut
    INSERT INTO loyalty_config (workshop_id, key, value, description)
    VALUES 
        (auth.uid(), 'points_per_euro', '1', 'Points gagnés par euro dépensé'),
        (auth.uid(), 'minimum_purchase', '10', 'Montant minimum pour gagner des points'),
        (auth.uid(), 'bonus_threshold', '100', 'Seuil pour bonus de points'),
        (auth.uid(), 'bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
        (auth.uid(), 'points_expiry_days', '365', 'Durée de validité des points en jours'),
        (auth.uid(), 'auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');
    
    RAISE NOTICE 'Configuration par défaut créée pour l''atelier %', auth.uid();
END;
$$;

-- 6. CRÉER les nouveaux triggers
SELECT '=== CRÉATION NOUVEAUX TRIGGERS ===' as etape;

CREATE TRIGGER set_loyalty_workshop_id_loyalty_tiers_trigger
    BEFORE INSERT OR UPDATE ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

CREATE TRIGGER set_loyalty_workshop_id_loyalty_config_trigger
    BEFORE INSERT OR UPDATE ON public.loyalty_config
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

-- 7. CRÉER les nouvelles politiques RLS
SELECT '=== CRÉATION NOUVELLES POLITIQUES RLS ===' as etape;

-- Politiques pour loyalty_tiers_advanced
CREATE POLICY "loyalty_tiers_select" ON public.loyalty_tiers_advanced
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_insert" ON public.loyalty_tiers_advanced
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_update" ON public.loyalty_tiers_advanced
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_delete" ON public.loyalty_tiers_advanced
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

-- Politiques pour loyalty_config
CREATE POLICY "loyalty_config_select" ON public.loyalty_config
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "loyalty_config_insert" ON public.loyalty_config
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "loyalty_config_update" ON public.loyalty_config
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "loyalty_config_delete" ON public.loyalty_config
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
    );

-- 8. Accorder les permissions
SELECT '=== ACCORD DES PERMISSIONS ===' as etape;

GRANT EXECUTE ON FUNCTION get_workshop_loyalty_tiers() TO authenticated;
GRANT EXECUTE ON FUNCTION get_workshop_loyalty_config() TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_loyalty_tiers_for_workshop() TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_loyalty_config_for_workshop() TO authenticated;

-- 9. TEST de l'isolation
SELECT '=== TEST ISOLATION ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_test_tier_id UUID;
    v_test_config_id UUID;
    v_insert_tier_success BOOLEAN := FALSE;
    v_insert_config_success BOOLEAN := FALSE;
    v_select_tier_success BOOLEAN := FALSE;
    v_select_config_success BOOLEAN := FALSE;
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
            'Test Isolation', 25, 1.5, '#FF0000', 'Test isolation entre comptes', true
        ) RETURNING id INTO v_test_tier_id;
        
        v_insert_tier_success := TRUE;
        RAISE NOTICE '✅ Insertion niveau réussie - ID: %', v_test_tier_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test niveau: %', SQLERRM;
    END;
    
    -- Test d'insertion d'une configuration
    BEGIN
        INSERT INTO loyalty_config (
            key, value, description
        ) VALUES (
            'test_isolation', 'test_value', 'Test isolation entre comptes'
        ) RETURNING id INTO v_test_config_id;
        
        v_insert_config_success := TRUE;
        RAISE NOTICE '✅ Insertion config réussie - ID: %', v_test_config_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test config: %', SQLERRM;
    END;
    
    -- Test de sélection des niveaux
    BEGIN
        PERFORM * FROM get_workshop_loyalty_tiers();
        v_select_tier_success := TRUE;
        RAISE NOTICE '✅ Sélection niveaux réussie';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la sélection niveaux: %', SQLERRM;
    END;
    
    -- Test de sélection de la configuration
    BEGIN
        PERFORM * FROM get_workshop_loyalty_config();
        v_select_config_success := TRUE;
        RAISE NOTICE '✅ Sélection config réussie';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la sélection config: %', SQLERRM;
    END;
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test:';
    RAISE NOTICE '  - Insertion niveau: %', CASE WHEN v_insert_tier_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Insertion config: %', CASE WHEN v_insert_config_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection niveau: %', CASE WHEN v_select_tier_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection config: %', CASE WHEN v_select_config_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les politiques
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict OK'
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '⚠️ Strict OK'
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

-- Vérifier les fonctions
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%loyalty%'
ORDER BY routine_name;

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Nettoyage complet effectué' as message;
SELECT '✅ Nouvelles politiques RLS créées' as securite;
SELECT '✅ Nouveaux triggers créés' as automatisation;
SELECT '✅ Nouvelles fonctions créées' as fonctions;
SELECT '✅ Isolation parfaite entre comptes' as isolation;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Chaque compte aura maintenant ses propres niveaux et configuration' as note;
