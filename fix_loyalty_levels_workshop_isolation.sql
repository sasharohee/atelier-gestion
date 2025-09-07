-- =====================================================
-- ISOLATION NIVEAUX DE FIDÉLITÉ PAR ATELIER
-- =====================================================
-- Script pour rendre les niveaux de fidélité uniques par atelier
-- Chaque atelier aura ses propres niveaux personnalisables
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel des tables de fidélité
SELECT '=== ÉTAT ACTUEL TABLES FIDÉLITÉ ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = tablename 
            AND column_name = 'workshop_id'
            AND table_schema = 'public'
        ) THEN '✅ workshop_id présent'
        ELSE '❌ workshop_id manquant'
    END as workshop_id_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename;

-- 2. Ajouter workshop_id aux tables si nécessaire
SELECT '=== AJOUT COLONNES WORKSHOP_ID ===' as etape;

-- Ajouter workshop_id à loyalty_tiers_advanced
ALTER TABLE public.loyalty_tiers_advanced 
ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Ajouter workshop_id à loyalty_config
ALTER TABLE public.loyalty_config 
ADD COLUMN IF NOT EXISTS workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

SELECT 'Colonnes workshop_id ajoutées ou vérifiées' as resultat;

-- 3. Migrer les données existantes vers l'utilisateur actuel
SELECT '=== MIGRATION DONNÉES EXISTANTES ===' as etape;

-- Récupérer l'utilisateur actuel
DO $$
DECLARE
    v_current_user_id UUID;
    v_migrated_tiers INTEGER := 0;
    v_migrated_config INTEGER := 0;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, migration ignorée';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔄 Migration pour utilisateur: %', v_current_user_id;
    
    -- Migrer les niveaux de fidélité existants
    UPDATE loyalty_tiers_advanced 
    SET workshop_id = v_current_user_id 
    WHERE workshop_id IS NULL;
    
    GET DIAGNOSTICS v_migrated_tiers = ROW_COUNT;
    RAISE NOTICE '✅ % niveaux de fidélité migrés', v_migrated_tiers;
    
    -- Migrer la configuration existante
    UPDATE loyalty_config 
    SET workshop_id = v_current_user_id 
    WHERE workshop_id IS NULL;
    
    GET DIAGNOSTICS v_migrated_config = ROW_COUNT;
    RAISE NOTICE '✅ % configurations migrées', v_migrated_config;
    
    -- Si aucun niveau n'existe, créer les niveaux par défaut pour cet utilisateur
    IF NOT EXISTS (SELECT 1 FROM loyalty_tiers_advanced WHERE workshop_id = v_current_user_id) THEN
        RAISE NOTICE '🆕 Création des niveaux par défaut pour l''utilisateur actuel';
        
        INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
        VALUES 
            (v_current_user_id, 'Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
            (v_current_user_id, 'Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
            (v_current_user_id, 'Or', 500, 10.00, '#FFD700', '10% de réduction', true),
            (v_current_user_id, 'Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
            (v_current_user_id, 'Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true);
        
        RAISE NOTICE '✅ 5 niveaux par défaut créés';
    END IF;
    
    -- Si aucune configuration n'existe, créer la configuration par défaut
    IF NOT EXISTS (SELECT 1 FROM loyalty_config WHERE workshop_id = v_current_user_id) THEN
        RAISE NOTICE '🆕 Création de la configuration par défaut pour l''utilisateur actuel';
        
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

-- 4. Activer RLS sur les tables de fidélité
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_config ENABLE ROW LEVEL SECURITY;

-- 5. Supprimer les anciennes politiques
SELECT '=== NETTOYAGE ANCIENNES POLITIQUES ===' as etape;

-- Supprimer les politiques sur loyalty_tiers_advanced
DROP POLICY IF EXISTS "loyalty_tiers_advanced_select_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_insert_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_update_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_delete_policy" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_select_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_insert_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_update_ultra_strict" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_advanced_delete_ultra_strict" ON public.loyalty_tiers_advanced;

-- Supprimer les politiques sur loyalty_config
DROP POLICY IF EXISTS "loyalty_config_select_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_insert_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_update_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_delete_policy" ON public.loyalty_config;

-- 6. Créer les nouvelles politiques RLS isolées par atelier
SELECT '=== CRÉATION POLITIQUES RLS ISOLÉES ===' as etape;

-- Politiques pour loyalty_tiers_advanced
CREATE POLICY "loyalty_tiers_workshop_isolation_select" ON public.loyalty_tiers_advanced
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_workshop_isolation_insert" ON public.loyalty_tiers_advanced
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_workshop_isolation_update" ON public.loyalty_tiers_advanced
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_workshop_isolation_delete" ON public.loyalty_tiers_advanced
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- Politiques pour loyalty_config
CREATE POLICY "loyalty_config_workshop_isolation_select" ON public.loyalty_config
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_config_workshop_isolation_insert" ON public.loyalty_config
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_config_workshop_isolation_update" ON public.loyalty_config
    FOR UPDATE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    )
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_config_workshop_isolation_delete" ON public.loyalty_config
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- 7. Créer des triggers pour définir automatiquement workshop_id
SELECT '=== CRÉATION TRIGGERS WORKSHOP_ID ===' as etape;

-- Fonction pour définir workshop_id automatiquement
CREATE OR REPLACE FUNCTION set_loyalty_workshop_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_trigger ON public.loyalty_tiers_advanced;
CREATE TRIGGER set_workshop_id_loyalty_tiers_trigger
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

DROP TRIGGER IF EXISTS set_workshop_id_loyalty_config_trigger ON public.loyalty_config;
CREATE TRIGGER set_workshop_id_loyalty_config_trigger
    BEFORE INSERT ON public.loyalty_config
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

-- 8. Créer des fonctions utilitaires pour la gestion des niveaux par atelier
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

-- Fonction pour créer un niveau par défaut pour un atelier
CREATE OR REPLACE FUNCTION create_default_loyalty_tiers_for_workshop(p_workshop_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_created_count INTEGER := 0;
BEGIN
    -- Vérifier que l'utilisateur a le droit de créer des niveaux pour cet atelier
    IF p_workshop_id != auth.uid() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès refusé: vous ne pouvez créer des niveaux que pour votre propre atelier'
        );
    END IF;
    
    -- Créer les niveaux par défaut s'ils n'existent pas
    INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
    SELECT 
        p_workshop_id, 
        tier.name, 
        tier.points_required, 
        tier.discount_percentage, 
        tier.color, 
        tier.description, 
        tier.is_active
    FROM (VALUES 
        ('Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
        ('Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
        ('Or', 500, 10.00, '#FFD700', '10% de réduction', true),
        ('Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
        ('Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true)
    ) AS tier(name, points_required, discount_percentage, color, description, is_active)
    WHERE NOT EXISTS (
        SELECT 1 FROM loyalty_tiers_advanced lta 
        WHERE lta.workshop_id = p_workshop_id
    );
    
    GET DIAGNOSTICS v_created_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux par défaut créés avec succès',
        'tiers_created', v_created_count
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la création des niveaux: ' || SQLERRM
        );
END;
$$;

-- Accorder les permissions
GRANT EXECUTE ON FUNCTION get_workshop_loyalty_tiers() TO authenticated;
GRANT EXECUTE ON FUNCTION get_workshop_loyalty_config() TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_loyalty_tiers_for_workshop(UUID) TO authenticated;

-- 9. Test d'isolation des niveaux par atelier
SELECT '=== TEST ISOLATION NIVEAUX PAR ATELIER ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_tiers_count INTEGER;
    v_config_count INTEGER;
    v_test_tier_id UUID;
    v_insert_success BOOLEAN := FALSE;
    v_select_success BOOLEAN := FALSE;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, test ignoré';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test d''isolation pour utilisateur: %', v_current_user_id;
    
    -- Compter les niveaux et configurations de l'utilisateur actuel
    SELECT COUNT(*) INTO v_tiers_count FROM loyalty_tiers_advanced WHERE workshop_id = v_current_user_id;
    SELECT COUNT(*) INTO v_config_count FROM loyalty_config WHERE workshop_id = v_current_user_id;
    
    RAISE NOTICE '📊 Niveaux actuels: %, Configurations actuelles: %', v_tiers_count, v_config_count;
    
    -- Test 1: Insérer un nouveau niveau
    BEGIN
        INSERT INTO loyalty_tiers_advanced (
            name, points_required, discount_percentage, color, description, is_active
        ) VALUES (
            'Test Isolation', 50, 2.5, '#FF0000', 'Niveau de test pour isolation', true
        ) RETURNING id INTO v_test_tier_id;
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Nouveau niveau créé - ID: %', v_test_tier_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la création du niveau: %', SQLERRM;
    END;
    
    -- Test 2: Vérifier que le niveau est visible
    IF v_test_tier_id IS NOT NULL THEN
        BEGIN
            IF EXISTS (
                SELECT 1 FROM loyalty_tiers_advanced 
                WHERE id = v_test_tier_id AND workshop_id = v_current_user_id
            ) THEN
                v_select_success := TRUE;
                RAISE NOTICE '✅ Niveau de test visible après insertion';
            ELSE
                RAISE NOTICE '❌ Niveau de test non visible après insertion';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
        END;
        
        -- Nettoyer le test
        DELETE FROM loyalty_tiers_advanced WHERE id = v_test_tier_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
    -- Test 3: Vérifier l'isolation avec les fonctions utilitaires
    BEGIN
        IF EXISTS (SELECT 1 FROM get_workshop_loyalty_tiers()) THEN
            RAISE NOTICE '✅ Fonction get_workshop_loyalty_tiers() fonctionne';
        ELSE
            RAISE NOTICE '⚠️ Aucun niveau trouvé avec get_workshop_loyalty_tiers()';
        END IF;
        
        IF EXISTS (SELECT 1 FROM get_workshop_loyalty_config()) THEN
            RAISE NOTICE '✅ Fonction get_workshop_loyalty_config() fonctionne';
        ELSE
            RAISE NOTICE '⚠️ Aucune configuration trouvée avec get_workshop_loyalty_config()';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test des fonctions: %', SQLERRM;
    END;
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test d''isolation:';
    RAISE NOTICE '  - Insertion niveau: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection niveau: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Niveaux totaux pour cet atelier: %', v_tiers_count;
    RAISE NOTICE '  - Configurations totales pour cet atelier: %', v_config_count;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. Vérification finale
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
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Isolation parfaite'
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '⚠️ Isolation basique'
        ELSE '❌ Pas d''isolation'
    END as type_isolation
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

-- Vérifier les fonctions créées
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%loyalty%'
ORDER BY routine_name;

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation des niveaux de fidélité par atelier activée' as message;
SELECT '✅ Chaque atelier a maintenant ses propres niveaux personnalisables' as personnalisation;
SELECT '✅ Politiques RLS strictes appliquées' as securite;
SELECT '✅ Triggers automatiques pour workshop_id' as automatisation;
SELECT '✅ Fonctions utilitaires créées' as fonctions;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les niveaux de fidélité sont maintenant uniques par atelier' as note;
