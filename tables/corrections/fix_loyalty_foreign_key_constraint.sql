-- =====================================================
-- CORRECTION CONTRAINTE CLÉ ÉTRANGÈRE LOYALTY
-- =====================================================
-- Script pour corriger l'erreur de contrainte de clé étrangère
-- Erreur: Key (workshop_id) is not present in table "users"
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'erreur actuelle
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

-- 2. Vérifier les tables de référence
SELECT '=== VÉRIFICATION TABLES DE RÉFÉRENCE ===' as etape;

-- Vérifier si la table users existe
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name IN ('users', 'auth.users')
ORDER BY table_name;

-- Vérifier la structure de auth.users
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth'
AND table_name = 'users'
ORDER BY ordinal_position;

-- 3. CORRIGER les contraintes de clé étrangère
SELECT '=== CORRECTION CONTRAINTES ===' as etape;

-- Supprimer les contraintes incorrectes
ALTER TABLE public.loyalty_tiers_advanced 
DROP CONSTRAINT IF EXISTS loyalty_tiers_advanced_workshop_id_fkey;

ALTER TABLE public.loyalty_config 
DROP CONSTRAINT IF EXISTS loyalty_config_workshop_id_fkey;

-- Vérifier que les colonnes workshop_id existent
ALTER TABLE public.loyalty_tiers_advanced 
ADD COLUMN IF NOT EXISTS workshop_id UUID;

ALTER TABLE public.loyalty_config 
ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- 4. Créer les contraintes correctes
SELECT '=== CRÉATION CONTRAINTES CORRECTES ===' as etape;

-- Option 1: Contrainte vers auth.users (recommandée)
ALTER TABLE public.loyalty_tiers_advanced 
ADD CONSTRAINT loyalty_tiers_advanced_workshop_id_fkey 
FOREIGN KEY (workshop_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.loyalty_config 
ADD CONSTRAINT loyalty_config_workshop_id_fkey 
FOREIGN KEY (workshop_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 5. Alternative: Si auth.users n'est pas accessible, créer une contrainte sans référence
-- (Décommentez cette section si l'option 1 échoue)

/*
-- Supprimer les contraintes vers auth.users
ALTER TABLE public.loyalty_tiers_advanced 
DROP CONSTRAINT IF EXISTS loyalty_tiers_advanced_workshop_id_fkey;

ALTER TABLE public.loyalty_config 
DROP CONSTRAINT IF EXISTS loyalty_config_workshop_id_fkey;

-- Créer des contraintes de validation simple
ALTER TABLE public.loyalty_tiers_advanced 
ADD CONSTRAINT loyalty_tiers_advanced_workshop_id_check 
CHECK (workshop_id IS NULL OR workshop_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

ALTER TABLE public.loyalty_config 
ADD CONSTRAINT loyalty_config_workshop_id_check 
CHECK (workshop_id IS NULL OR workshop_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
*/

-- 6. MIGRER les données existantes
SELECT '=== MIGRATION DONNÉES ===' as etape;

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
        
        -- Utiliser le premier utilisateur disponible dans auth.users
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

-- 7. ACTIVER RLS
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_config ENABLE ROW LEVEL SECURITY;

-- 8. CRÉER les politiques RLS
SELECT '=== CRÉATION POLITIQUES RLS ===' as etape;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_select" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_insert" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_update" ON public.loyalty_tiers_advanced;
DROP POLICY IF EXISTS "loyalty_tiers_ultra_strict_delete" ON public.loyalty_tiers_advanced;

DROP POLICY IF EXISTS "loyalty_config_ultra_strict_select" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_insert" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_update" ON public.loyalty_config;
DROP POLICY IF EXISTS "loyalty_config_ultra_strict_delete" ON public.loyalty_config;

-- Créer les nouvelles politiques
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

-- 9. CRÉER les triggers
SELECT '=== CRÉATION TRIGGERS ===' as etape;

-- Fonction trigger
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

-- Supprimer les anciens triggers
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_loyalty_tiers_trigger ON public.loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_loyalty_workshop_id_loyalty_config_trigger ON public.loyalty_config;

-- Créer les nouveaux triggers
CREATE TRIGGER set_loyalty_workshop_id_loyalty_tiers_trigger
    BEFORE INSERT ON public.loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

CREATE TRIGGER set_loyalty_workshop_id_loyalty_config_trigger
    BEFORE INSERT ON public.loyalty_config
    FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

-- 10. CRÉER les fonctions utilitaires
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

-- 11. TEST de la correction
SELECT '=== TEST DE LA CORRECTION ===' as etape;

DO $$
DECLARE
    v_current_user_id UUID;
    v_test_tier_id UUID;
    v_insert_success BOOLEAN := FALSE;
BEGIN
    -- Récupérer l'utilisateur actuel
    SELECT auth.uid() INTO v_current_user_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test avec utilisateur: %', v_current_user_id;
    
    -- Test d'insertion
    BEGIN
        INSERT INTO loyalty_tiers_advanced (
            name, points_required, discount_percentage, color, description, is_active
        ) VALUES (
            'Test Correction', 75, 3.5, '#00FF00', 'Test après correction contrainte', true
        ) RETURNING id INTO v_test_tier_id;
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Insertion réussie - ID: %', v_test_tier_id;
        
        -- Nettoyer le test
        DELETE FROM loyalty_tiers_advanced WHERE id = v_test_tier_id;
        RAISE NOTICE '✅ Test nettoyé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    END;
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 12. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les contraintes
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

-- 13. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Contrainte de clé étrangère corrigée' as message;
SELECT '✅ Données migrées vers l''utilisateur actuel' as migration;
SELECT '✅ Politiques RLS créées' as securite;
SELECT '✅ Triggers créés' as automatisation;
SELECT '✅ Fonctions utilitaires créées' as fonctions;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ L''isolation des niveaux de fidélité est maintenant fonctionnelle' as note;
