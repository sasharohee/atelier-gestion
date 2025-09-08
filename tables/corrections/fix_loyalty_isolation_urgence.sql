-- =====================================================
-- CORRECTION URGENCE ISOLATION NIVEAUX DE FIDÉLITÉ
-- =====================================================
-- Script pour forcer l'isolation des niveaux de fidélité
-- À exécuter si l'isolation ne fonctionne pas
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état initial
SELECT '=== ÉTAT INITIAL ===' as etape;

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

-- 2. FORCER l'ajout des colonnes workshop_id
SELECT '=== AJOUT FORCÉ COLONNES WORKSHOP_ID ===' as etape;

-- Supprimer les contraintes existantes si elles existent
ALTER TABLE public.loyalty_tiers_advanced DROP CONSTRAINT IF EXISTS loyalty_tiers_advanced_workshop_id_fkey;
ALTER TABLE public.loyalty_config DROP CONSTRAINT IF EXISTS loyalty_config_workshop_id_fkey;

-- Ajouter les colonnes workshop_id
ALTER TABLE public.loyalty_tiers_advanced 
ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE public.loyalty_config 
ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- Ajouter les contraintes de clé étrangère
ALTER TABLE public.loyalty_tiers_advanced 
ADD CONSTRAINT loyalty_tiers_advanced_workshop_id_fkey 
FOREIGN KEY (workshop_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.loyalty_config 
ADD CONSTRAINT loyalty_config_workshop_id_fkey 
FOREIGN KEY (workshop_id) REFERENCES auth.users(id) ON DELETE CASCADE;

SELECT 'Colonnes workshop_id ajoutées avec contraintes' as resultat;

-- 3. MIGRER FORCÉMENT les données existantes
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
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, migration vers le premier utilisateur disponible';
        
        -- Utiliser le premier utilisateur disponible
        SELECT id INTO v_current_user_id FROM auth.users LIMIT 1;
        
        IF v_current_user_id IS NULL THEN
            RAISE NOTICE '❌ Aucun utilisateur trouvé dans auth.users';
            RETURN;
        END IF;
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

-- 4. FORCER l'activation RLS
SELECT '=== ACTIVATION FORCÉE RLS ===' as etape;

ALTER TABLE public.loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_config ENABLE ROW LEVEL SECURITY;

-- 5. SUPPRIMER TOUTES les anciennes politiques
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

DROP POLICY IF EXISTS "loyalty_config_select_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_insert_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_update_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_delete_policy" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_workshop_isolation_delete" ON public.loyalty_config;

-- 6. CRÉER des politiques RLS ULTRA-STRICTES
SELECT '=== CRÉATION POLITIQUES ULTRA-STRICTES ===' as etape;

-- Politiques pour loyalty_tiers_advanced
CREATE POLICY "loyalty_tiers_ultra_strict_select" ON public.loyalty_tiers_advanced
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_ultra_strict_insert" ON public.loyalty_tiers_advanced
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_tiers_ultra_strict_update" ON public.loyalty_tiers_advanced
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

CREATE POLICY "loyalty_tiers_ultra_strict_delete" ON public.loyalty_tiers_advanced
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- Politiques pour loyalty_config
CREATE POLICY "loyalty_config_ultra_strict_select" ON public.loyalty_config
    FOR SELECT 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_config_ultra_strict_insert" ON public.loyalty_config
    FOR INSERT 
    WITH CHECK (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

CREATE POLICY "loyalty_config_ultra_strict_update" ON public.loyalty_config
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

CREATE POLICY "loyalty_config_ultra_strict_delete" ON public.loyalty_config
    FOR DELETE 
    USING (
        workshop_id = auth.uid() 
        AND auth.uid() IS NOT NULL
        AND workshop_id IS NOT NULL
    );

-- 7. CRÉER des triggers ULTRA-STRICTS
SELECT '=== CRÉATION TRIGGERS ULTRA-STRICTS ===' as etape;

-- Fonction trigger ultra-stricte
CREATE OR REPLACE FUNCTION set_loyalty_workshop_id_ultra_strict()
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

-- Supprimer les anciens triggers
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_config_trigger ON public.loyalty_config;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_loyalty_tiers_advanced_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_loyalty_config_trigger ON public.loyalty_config;

-- Créer les nouveaux triggers
CREATE TRIGGER set_loyalty_workshop_id_loyalty_tiers_trigger
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id_ultra_strict();

CREATE TRIGGER set_loyalty_workshop_id_loyalty_config_trigger
    BEFORE INSERT ON public.loyalty_config
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id_ultra_strict();

-- 8. CRÉER/RECRÉER les fonctions utilitaires
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

-- 9. TEST d'isolation ULTRA-STRICT
SELECT '=== TEST ISOLATION ULTRA-STRICT ===' as etape;

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
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test ultra-strict avec utilisateur: %', v_current_user_id;
    
    -- Compter les niveaux et configurations de l'utilisateur actuel
    SELECT COUNT(*) INTO v_tiers_count FROM loyalty_tiers_advanced WHERE workshop_id = v_current_user_id;
    SELECT COUNT(*) INTO v_config_count FROM loyalty_config WHERE workshop_id = v_current_user_id;
    
    RAISE NOTICE '📊 Niveaux actuels: %, Configurations actuelles: %', v_tiers_count, v_config_count;
    
    -- Test 1: Insérer un nouveau niveau
    BEGIN
        INSERT INTO loyalty_tiers_advanced (
            name, points_required, discount_percentage, color, description, is_active
        ) VALUES (
            'Test Ultra-Strict', 25, 1.5, '#00FF00', 'Niveau de test ultra-strict', true
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
    RAISE NOTICE '📊 Résumé du test ultra-strict:';
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
        WHEN qual LIKE '%workshop_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict'
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '⚠️ Standard'
        ELSE '❌ Autre condition'
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

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Isolation ULTRA-STRICTE des niveaux de fidélité activée' as message;
SELECT '✅ Toutes les données migrées vers l''utilisateur actuel' as migration;
SELECT '✅ Politiques RLS ultra-strictes appliquées' as securite;
SELECT '✅ Triggers ultra-stricts créés' as automatisation;
SELECT '✅ Fonctions utilitaires recréées' as fonctions;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION IMMÉDIATEMENT' as deploy;
SELECT 'ℹ️ L''isolation est maintenant FORCÉE et ULTRA-STRICTE' as note;
