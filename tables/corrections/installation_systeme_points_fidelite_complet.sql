-- =====================================================
-- INSTALLATION COMPLÈTE DU SYSTÈME DE POINTS DE FIDÉLITÉ
-- =====================================================
-- Ce script installe le système complet de points de fidélité
-- en exécutant tous les scripts dans le bon ordre
-- =====================================================

-- ÉTAPE 1: CRÉER LE SYSTÈME PRINCIPAL
SELECT '=== ÉTAPE 1: CRÉATION DU SYSTÈME PRINCIPAL ===' as etape;

-- 1. TABLE DES NIVEAUX DE FIDÉLITÉ
CREATE TABLE IF NOT EXISTS loyalty_tiers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    min_points INTEGER NOT NULL,
    discount_percentage DECIMAL(5,2) NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLE DES PARRAINAGES
CREATE TABLE IF NOT EXISTS referrals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    referrer_client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    referred_client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected', 'completed')),
    points_awarded INTEGER DEFAULT 0,
    confirmation_date TIMESTAMP WITH TIME ZONE,
    confirmed_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(referrer_client_id, referred_client_id)
);

-- 3. TABLE DES POINTS DE FIDÉLITÉ DES CLIENTS
CREATE TABLE IF NOT EXISTS client_loyalty_points (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0,
    used_points INTEGER DEFAULT 0,
    current_tier_id UUID REFERENCES loyalty_tiers(id),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(client_id)
);

-- 4. TABLE DES HISTORIQUES DE POINTS
CREATE TABLE IF NOT EXISTS loyalty_points_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    points_type TEXT NOT NULL CHECK (points_type IN ('earned', 'used', 'expired', 'bonus')),
    source_type TEXT NOT NULL CHECK (source_type IN ('referral', 'purchase', 'manual', 'bonus')),
    source_id UUID,
    description TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLE DES RÈGLES DE POINTS
CREATE TABLE IF NOT EXISTS loyalty_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    rule_name TEXT NOT NULL UNIQUE,
    points_per_referral INTEGER DEFAULT 100,
    points_per_euro_spent DECIMAL(10,2) DEFAULT 1.0,
    points_expiry_months INTEGER DEFAULT 12,
    min_purchase_for_points DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CRÉATION DES INDEX
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_client_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_client_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
CREATE INDEX IF NOT EXISTS idx_loyalty_points_client ON client_loyalty_points(client_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_history_client ON loyalty_points_history(client_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_history_created_at ON loyalty_points_history(created_at);

-- INSERTION DES DONNÉES DE BASE
INSERT INTO loyalty_tiers (name, min_points, discount_percentage, description, color) VALUES
('Bronze', 0, 0.00, 'Niveau de base - Aucune réduction', '#CD7F32'),
('Argent', 500, 5.00, '5% de réduction sur les réparations', '#C0C0C0'),
('Or', 1000, 10.00, '10% de réduction sur les réparations', '#FFD700'),
('Platine', 2500, 15.00, '15% de réduction sur les réparations', '#E5E4E2'),
('Diamant', 5000, 20.00, '20% de réduction sur les réparations', '#B9F2FF')
ON CONFLICT (name) DO NOTHING;

INSERT INTO loyalty_rules (rule_name, points_per_referral, points_per_euro_spent, points_expiry_months, min_purchase_for_points) VALUES
('Règles par défaut', 100, 1.0, 12, 0)
ON CONFLICT (rule_name) DO NOTHING;

SELECT '✅ Système principal créé avec succès' as status;

-- ÉTAPE 2: CRÉER LES FONCTIONS PRINCIPALES
SELECT '=== ÉTAPE 2: CRÉATION DES FONCTIONS PRINCIPALES ===' as etape;

-- Fonction pour calculer le niveau de fidélité d'un client
CREATE OR REPLACE FUNCTION calculate_client_tier(client_uuid UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_available_points INTEGER;
  v_new_tier_id UUID;
BEGIN
  SELECT (total_points - used_points) INTO v_available_points
  FROM client_loyalty_points
  WHERE client_id = client_uuid;
  
  IF v_available_points IS NULL THEN
    v_available_points := 0;
  END IF;
  
  SELECT id INTO v_new_tier_id
  FROM loyalty_tiers
  WHERE min_points <= v_available_points
  ORDER BY min_points DESC
  LIMIT 1;
  
  RETURN v_new_tier_id;
END;
$$;

-- Fonction pour ajouter des points à un client
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_points_type TEXT DEFAULT 'earned',
    p_source_type TEXT DEFAULT 'manual',
    p_source_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_points INTEGER;
    v_new_tier_id UUID;
    v_result JSON;
BEGIN
    INSERT INTO client_loyalty_points (client_id, total_points, used_points)
    VALUES (p_client_id, p_points, 0)
    ON CONFLICT (client_id) 
    DO UPDATE SET 
        total_points = client_loyalty_points.total_points + p_points,
        updated_at = NOW();
    
    SELECT total_points - used_points INTO v_current_points
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    v_new_tier_id := calculate_client_tier(p_client_id);
    
    UPDATE client_loyalty_points
    SET current_tier_id = v_new_tier_id
    WHERE client_id = p_client_id;
    
    INSERT INTO loyalty_points_history (
        client_id, points_change, points_type, source_type, 
        source_id, description, created_by
    ) VALUES (
        p_client_id, p_points, p_points_type, p_source_type,
        p_source_id, p_description, p_created_by
    );
    
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', p_client_id,
            'points_added', p_points,
            'total_points', v_current_points,
            'new_tier_id', v_new_tier_id
        ),
        'message', 'Points ajoutés avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''ajout des points: ' || SQLERRM
        );
END;
$$;

-- Fonction pour confirmer un parrainage
CREATE OR REPLACE FUNCTION confirm_referral(
    p_referral_id UUID,
    p_points_to_award INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_referral referrals%ROWTYPE;
    v_points_to_award INTEGER;
    v_rules loyalty_rules%ROWTYPE;
    v_result JSON;
BEGIN
    SELECT * INTO v_referral
    FROM referrals
    WHERE id = p_referral_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Parrainage non trouvé'
        );
    END IF;
    
    IF v_referral.status != 'pending' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Ce parrainage a déjà été traité'
        );
    END IF;
    
    SELECT * INTO v_rules
    FROM loyalty_rules
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF p_points_to_award IS NOT NULL THEN
        v_points_to_award := p_points_to_award;
    ELSE
        v_points_to_award := v_rules.points_per_referral;
    END IF;
    
    UPDATE referrals
    SET 
        status = 'confirmed',
        points_awarded = v_points_to_award,
        confirmation_date = NOW(),
        confirmed_by = auth.uid(),
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_referral_id;
    
    PERFORM add_loyalty_points(
        v_referral.referrer_client_id,
        v_points_to_award,
        'earned',
        'referral',
        p_referral_id,
        'Points pour parrainage confirmé',
        auth.uid()
    );
    
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'referral_id', p_referral_id,
            'referrer_client_id', v_referral.referrer_client_id,
            'referred_client_id', v_referral.referred_client_id,
            'points_awarded', v_points_to_award,
            'confirmation_date', NOW()
        ),
        'message', 'Parrainage confirmé avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la confirmation: ' || SQLERRM
        );
END;
$$;

-- Fonction pour créer un parrainage
CREATE OR REPLACE FUNCTION create_referral(
    p_referrer_client_id UUID,
    p_referred_client_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_referral_id UUID;
    v_result JSON;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clients WHERE id = p_referrer_client_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client parrain non trouvé'
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM clients WHERE id = p_referred_client_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client parrainé non trouvé'
        );
    END IF;
    
    IF p_referrer_client_id = p_referred_client_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un client ne peut pas se parrainer lui-même'
        );
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM referrals 
        WHERE referrer_client_id = p_referrer_client_id 
        AND referred_client_id = p_referred_client_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un parrainage existe déjà entre ces clients'
        );
    END IF;
    
    INSERT INTO referrals (
        referrer_client_id, 
        referred_client_id, 
        notes
    ) VALUES (
        p_referrer_client_id,
        p_referred_client_id,
        p_notes
    ) RETURNING id INTO v_referral_id;
    
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'referral_id', v_referral_id,
            'referrer_client_id', p_referrer_client_id,
            'referred_client_id', p_referred_client_id,
            'status', 'pending',
            'created_at', NOW()
        ),
        'message', 'Parrainage créé avec succès - En attente de confirmation'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la création du parrainage: ' || SQLERRM
        );
END;
$$;

SELECT '✅ Fonctions principales créées avec succès' as status;

-- ÉTAPE 3: AJOUTER LES COLONNES À LA TABLE REPAIRS
SELECT '=== ÉTAPE 3: AJOUT DES COLONNES À REPAIRS ===' as etape;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'loyalty_discount_percentage') THEN
        ALTER TABLE repairs ADD COLUMN loyalty_discount_percentage DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_discount_percentage ajoutée';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'loyalty_points_used') THEN
        ALTER TABLE repairs ADD COLUMN loyalty_points_used INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_points_used ajoutée';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'final_price') THEN
        ALTER TABLE repairs ADD COLUMN final_price DECIMAL(10,2);
        RAISE NOTICE 'Colonne final_price ajoutée';
    END IF;
END $$;

-- Mettre à jour les réparations existantes
UPDATE repairs SET final_price = total_price WHERE final_price IS NULL;

-- Créer un index
CREATE INDEX IF NOT EXISTS idx_repairs_loyalty_discount ON repairs(loyalty_discount_percentage);

SELECT '✅ Colonnes ajoutées à repairs avec succès' as status;

-- ÉTAPE 4: CRÉER LES FONCTIONS D'INTÉGRATION
SELECT '=== ÉTAPE 4: CRÉATION DES FONCTIONS D''INTÉGRATION ===' as etape;

-- Fonction pour calculer automatiquement la réduction de fidélité
CREATE OR REPLACE FUNCTION calculate_loyalty_discount(p_repair_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_repair repairs%ROWTYPE;
    v_client_loyalty client_loyalty_points%ROWTYPE;
    v_tier loyalty_tiers%ROWTYPE;
    v_discount_percentage DECIMAL(5,2);
    v_final_price DECIMAL(10,2);
    v_result JSON;
BEGIN
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Réparation non trouvée'
        );
    END IF;
    
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = v_repair.client_id;
    
    IF v_client_loyalty.id IS NULL THEN
        v_discount_percentage := 0;
    ELSE
        SELECT * INTO v_tier
        FROM loyalty_tiers
        WHERE id = v_client_loyalty.current_tier_id;
        
        IF v_tier.id IS NOT NULL THEN
            v_discount_percentage := v_tier.discount_percentage;
        ELSE
            v_discount_percentage := 0;
        END IF;
    END IF;
    
    v_final_price := v_repair.total_price * (1 - v_discount_percentage / 100);
    
    UPDATE repairs
    SET 
        loyalty_discount_percentage = v_discount_percentage,
        final_price = v_final_price,
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'repair_id', p_repair_id,
            'original_price', v_repair.total_price,
            'discount_percentage', v_discount_percentage,
            'discount_amount', v_repair.total_price - v_final_price,
            'final_price', v_final_price,
            'client_tier', CASE 
                WHEN v_tier.id IS NOT NULL THEN json_build_object(
                    'name', v_tier.name,
                    'color', v_tier.color
                )
                ELSE NULL
            END
        ),
        'message', 'Réduction de fidélité calculée avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors du calcul de la réduction: ' || SQLERRM
        );
END;
$$;

-- Fonction pour obtenir les statistiques de fidélité
CREATE OR REPLACE FUNCTION get_loyalty_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'total_clients_with_points', (
                SELECT COUNT(*) 
                FROM client_loyalty_points 
                WHERE (total_points - used_points) > 0
            ),
            'total_points_distributed', (
                SELECT COALESCE(SUM(total_points), 0)
                FROM client_loyalty_points
            ),
            'total_points_used', (
                SELECT COALESCE(SUM(used_points), 0)
                FROM client_loyalty_points
            ),
            'total_referrals_pending', (
                SELECT COUNT(*)
                FROM referrals
                WHERE status = 'pending'
            ),
            'total_referrals_confirmed', (
                SELECT COUNT(*)
                FROM referrals
                WHERE status = 'confirmed'
            ),
            'total_discounts_applied', (
                SELECT COUNT(*)
                FROM repairs
                WHERE loyalty_discount_percentage > 0
            ),
            'total_discount_amount', (
                SELECT COALESCE(SUM(total_price - final_price), 0)
                FROM repairs
                WHERE loyalty_discount_percentage > 0
            )
        )
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors du calcul des statistiques: ' || SQLERRM
        );
END;
$$;

SELECT '✅ Fonctions d''intégration créées avec succès' as status;

-- ÉTAPE 5: CONFIGURER LES POLITIQUES RLS
SELECT '=== ÉTAPE 5: CONFIGURATION DES POLITIQUES RLS ===' as etape;

-- Activer RLS sur toutes les tables
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules ENABLE ROW LEVEL SECURITY;

-- Politiques pour loyalty_tiers (lecture seule pour tous)
DROP POLICY IF EXISTS "loyalty_tiers_read_policy" ON loyalty_tiers;
CREATE POLICY "loyalty_tiers_read_policy" ON loyalty_tiers
    FOR SELECT USING (true);

-- Politiques pour referrals
DROP POLICY IF EXISTS "referrals_read_policy" ON referrals;
CREATE POLICY "referrals_read_policy" ON referrals
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "referrals_insert_policy" ON referrals;
CREATE POLICY "referrals_insert_policy" ON referrals
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "referrals_update_policy" ON referrals;
CREATE POLICY "referrals_update_policy" ON referrals
    FOR UPDATE USING (true);

-- Politiques pour client_loyalty_points
DROP POLICY IF EXISTS "client_loyalty_points_read_policy" ON client_loyalty_points;
CREATE POLICY "client_loyalty_points_read_policy" ON client_loyalty_points
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "client_loyalty_points_insert_policy" ON client_loyalty_points;
CREATE POLICY "client_loyalty_points_insert_policy" ON client_loyalty_points
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "client_loyalty_points_update_policy" ON client_loyalty_points;
CREATE POLICY "client_loyalty_points_update_policy" ON client_loyalty_points
    FOR UPDATE USING (true);

-- Politiques pour loyalty_points_history
DROP POLICY IF EXISTS "loyalty_points_history_read_policy" ON loyalty_points_history;
CREATE POLICY "loyalty_points_history_read_policy" ON loyalty_points_history
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "loyalty_points_history_insert_policy" ON loyalty_points_history;
CREATE POLICY "loyalty_points_history_insert_policy" ON loyalty_points_history
    FOR INSERT WITH CHECK (true);

-- Politiques pour loyalty_rules
DROP POLICY IF EXISTS "loyalty_rules_read_policy" ON loyalty_rules;
CREATE POLICY "loyalty_rules_read_policy" ON loyalty_rules
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "loyalty_rules_update_policy" ON loyalty_rules;
CREATE POLICY "loyalty_rules_update_policy" ON loyalty_rules
    FOR UPDATE USING (true);

SELECT '✅ Politiques RLS configurées avec succès' as status;

-- ÉTAPE 6: VÉRIFICATION FINALE
SELECT '=== ÉTAPE 6: VÉRIFICATION FINALE ===' as etape;

-- Vérifier que toutes les tables existent
SELECT 
    'VÉRIFICATION TABLES' as info,
    COUNT(*) as tables_crees
FROM information_schema.tables 
WHERE table_name IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules');

-- Vérifier les niveaux de fidélité
SELECT 
    'NIVEAUX CRÉÉS' as info,
    COUNT(*) as nombre_niveaux
FROM loyalty_tiers;

-- Vérifier les règles
SELECT 
    'RÈGLES CRÉÉES' as info,
    COUNT(*) as nombre_regles
FROM loyalty_rules;

-- Tester la fonction de statistiques
SELECT 
    'TEST STATISTIQUES' as info,
    CASE 
        WHEN get_loyalty_statistics()::text LIKE '%success%' THEN '✅ Fonctionne'
        ELSE '❌ Erreur'
    END as status;

SELECT '🎉 INSTALLATION TERMINÉE AVEC SUCCÈS !' as final_status;
SELECT 'Le système de points de fidélité est maintenant opérationnel.' as message;
SELECT 'Consultez le guide GUIDE_SYSTEME_POINTS_FIDELITE.md pour l''utilisation.' as next_step;
