-- =====================================================
-- SYSTÈME DE POINTS DE FIDÉLITÉ POUR PARRAINAGES
-- =====================================================
-- Ce script crée un système complet de points de fidélité
-- basé sur les parrainages de clients
-- =====================================================

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

-- =====================================================
-- CRÉATION DES INDEX POUR LES PERFORMANCES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_client_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_client_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
CREATE INDEX IF NOT EXISTS idx_loyalty_points_client ON client_loyalty_points(client_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_history_client ON loyalty_points_history(client_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_history_created_at ON loyalty_points_history(created_at);

-- =====================================================
-- INSERTION DES DONNÉES DE BASE
-- =====================================================

-- Insérer les niveaux de fidélité par défaut
INSERT INTO loyalty_tiers (name, min_points, discount_percentage, description, color) VALUES
('Bronze', 0, 0.00, 'Niveau de base - Aucune réduction', '#CD7F32'),
('Argent', 500, 5.00, '5% de réduction sur les réparations', '#C0C0C0'),
('Or', 1000, 10.00, '10% de réduction sur les réparations', '#FFD700'),
('Platine', 2500, 15.00, '15% de réduction sur les réparations', '#E5E4E2'),
('Diamant', 5000, 20.00, '20% de réduction sur les réparations', '#B9F2FF')
ON CONFLICT (name) DO NOTHING;

-- Insérer les règles de points par défaut
INSERT INTO loyalty_rules (rule_name, points_per_referral, points_per_euro_spent, points_expiry_months, min_purchase_for_points) VALUES
('Règles par défaut', 100, 1.0, 12, 0)
ON CONFLICT (rule_name) DO NOTHING;

-- =====================================================
-- FONCTIONS POUR LA GESTION DES POINTS
-- =====================================================

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
    -- Récupérer les points disponibles du client
    SELECT (total_points - used_points) INTO v_available_points
    FROM client_loyalty_points
    WHERE client_id = client_uuid;
    
    IF v_available_points IS NULL THEN
        v_available_points := 0;
    END IF;
    
    -- Trouver le niveau correspondant
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
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Insérer ou mettre à jour les points du client
    INSERT INTO client_loyalty_points (client_id, total_points, used_points)
    VALUES (p_client_id, p_points, 0)
    ON CONFLICT (client_id) 
    DO UPDATE SET 
        total_points = client_loyalty_points.total_points + p_points,
        updated_at = NOW();
    
    -- Récupérer les points actuels
    SELECT total_points - used_points INTO v_current_points
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    -- Calculer le nouveau niveau
    v_new_tier_id := calculate_client_tier(p_client_id);
    
    -- Mettre à jour le niveau
    UPDATE client_loyalty_points
    SET current_tier_id = v_new_tier_id
    WHERE client_id = p_client_id;
    
    -- Enregistrer l'historique
    INSERT INTO loyalty_points_history (
        client_id, points_change, points_type, source_type, 
        source_id, description, created_by
    ) VALUES (
        p_client_id, p_points, p_points_type, p_source_type,
        p_source_id, p_description, p_created_by
    );
    
    -- Retourner le résultat
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
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer le parrainage
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
    
    -- Récupérer les règles de points
    SELECT * INTO v_rules
    FROM loyalty_rules
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Déterminer les points à attribuer
    IF p_points_to_award IS NOT NULL THEN
        v_points_to_award := p_points_to_award;
    ELSE
        v_points_to_award := v_rules.points_per_referral;
    END IF;
    
    -- Mettre à jour le statut du parrainage
    UPDATE referrals
    SET 
        status = 'confirmed',
        points_awarded = v_points_to_award,
        confirmation_date = NOW(),
        confirmed_by = auth.uid(),
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_referral_id;
    
    -- Ajouter les points au parrain
    PERFORM add_loyalty_points(
        v_referral.referrer_client_id,
        v_points_to_award,
        'earned',
        'referral',
        p_referral_id,
        'Points pour parrainage confirmé',
        auth.uid()
    );
    
    -- Retourner le résultat
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

-- Fonction pour rejeter un parrainage
CREATE OR REPLACE FUNCTION reject_referral(
    p_referral_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_referral referrals%ROWTYPE;
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer le parrainage
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
    
    -- Mettre à jour le statut
    UPDATE referrals
    SET 
        status = 'rejected',
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_referral_id;
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'referral_id', p_referral_id,
            'status', 'rejected'
        ),
        'message', 'Parrainage rejeté'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors du rejet: ' || SQLERRM
        );
END;
$$;

-- Fonction pour obtenir les informations de fidélité d'un client
CREATE OR REPLACE FUNCTION get_client_loyalty_info(p_client_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_loyalty client_loyalty_points%ROWTYPE;
    v_tier loyalty_tiers%ROWTYPE;
    v_next_tier loyalty_tiers%ROWTYPE;
    v_referrals_count INTEGER;
    v_result JSON;
BEGIN
    -- Récupérer les informations de fidélité
    SELECT * INTO v_loyalty
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    -- Récupérer le niveau actuel
    IF v_loyalty.current_tier_id IS NOT NULL THEN
        SELECT * INTO v_tier
        FROM loyalty_tiers
        WHERE id = v_loyalty.current_tier_id;
    END IF;
    
    -- Récupérer le prochain niveau
    SELECT * INTO v_next_tier
    FROM loyalty_tiers
    WHERE min_points > (v_loyalty.total_points - v_loyalty.used_points)
    ORDER BY min_points ASC
    LIMIT 1;
    
    -- Compter les parrainages
    SELECT COUNT(*) INTO v_referrals_count
    FROM referrals
    WHERE referrer_client_id = p_client_id AND status = 'confirmed';
    
    -- Construire le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', p_client_id,
            'total_points', COALESCE(v_loyalty.total_points, 0),
            'used_points', COALESCE(v_loyalty.used_points, 0),
            'available_points', COALESCE(v_loyalty.total_points - v_loyalty.used_points, 0),
            'current_tier', CASE 
                WHEN v_tier.id IS NOT NULL THEN json_build_object(
                    'id', v_tier.id,
                    'name', v_tier.name,
                    'discount_percentage', v_tier.discount_percentage,
                    'color', v_tier.color
                )
                ELSE NULL
            END,
            'next_tier', CASE 
                WHEN v_next_tier.id IS NOT NULL THEN json_build_object(
                    'id', v_next_tier.id,
                    'name', v_next_tier.name,
                    'min_points', v_next_tier.min_points,
                    'discount_percentage', v_next_tier.discount_percentage,
                    'points_needed', v_next_tier.min_points - (v_loyalty.total_points - v_loyalty.used_points)
                )
                ELSE NULL
            END,
            'referrals_count', v_referrals_count
        )
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la récupération: ' || SQLERRM
        );
END;
$$;

-- Fonction pour obtenir l'historique des points d'un client
CREATE OR REPLACE FUNCTION get_client_loyalty_history(
    p_client_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_history JSON;
    v_total_count INTEGER;
    v_result JSON;
BEGIN
    -- Compter le total
    SELECT COUNT(*) INTO v_total_count
    FROM loyalty_points_history
    WHERE client_id = p_client_id;
    
    -- Récupérer l'historique
    SELECT json_agg(
        json_build_object(
            'id', h.id,
            'points_change', h.points_change,
            'points_type', h.points_type,
            'source_type', h.source_type,
            'description', h.description,
            'created_at', h.created_at
        )
    ) INTO v_history
    FROM loyalty_points_history h
    WHERE h.client_id = p_client_id
    ORDER BY h.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    -- Construire le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'history', COALESCE(v_history, '[]'::json),
            'total_count', v_total_count,
            'limit', p_limit,
            'offset', p_offset
        )
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la récupération: ' || SQLERRM
        );
END;
$$;

-- Fonction pour obtenir tous les parrainages en attente
CREATE OR REPLACE FUNCTION get_pending_referrals()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_referrals JSON;
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer les parrainages en attente
    SELECT json_agg(
        json_build_object(
            'id', r.id,
            'referrer_client', json_build_object(
                'id', rc.id,
                'first_name', rc.first_name,
                'last_name', rc.last_name,
                'email', rc.email
            ),
            'referred_client', json_build_object(
                'id', rdc.id,
                'first_name', rdc.first_name,
                'last_name', rdc.last_name,
                'email', rdc.email
            ),
            'status', r.status,
            'created_at', r.created_at,
            'notes', r.notes
        )
    ) INTO v_referrals
    FROM referrals r
    JOIN clients rc ON r.referrer_client_id = rc.id
    JOIN clients rdc ON r.referred_client_id = rdc.id
    WHERE r.status = 'pending'
    ORDER BY r.created_at DESC;
    
    -- Construire le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'referrals', COALESCE(v_referrals, '[]'::json)
        )
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la récupération: ' || SQLERRM
        );
END;
$$;

-- =====================================================
-- POLITIQUES RLS POUR LA SÉCURITÉ
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules ENABLE ROW LEVEL SECURITY;

-- Politiques pour loyalty_tiers (lecture seule pour tous)
CREATE POLICY "loyalty_tiers_read_policy" ON loyalty_tiers
    FOR SELECT USING (true);

-- Politiques pour referrals
CREATE POLICY "referrals_read_policy" ON referrals
    FOR SELECT USING (
        can_be_assigned_to_repairs(auth.uid())
    );

CREATE POLICY "referrals_insert_policy" ON referrals
    FOR INSERT WITH CHECK (
        can_be_assigned_to_repairs(auth.uid())
    );

CREATE POLICY "referrals_update_policy" ON referrals
    FOR UPDATE USING (
        can_be_assigned_to_repairs(auth.uid())
    );

-- Politiques pour client_loyalty_points
CREATE POLICY "client_loyalty_points_read_policy" ON client_loyalty_points
    FOR SELECT USING (
        can_be_assigned_to_repairs(auth.uid())
    );

CREATE POLICY "client_loyalty_points_insert_policy" ON client_loyalty_points
    FOR INSERT WITH CHECK (
        can_be_assigned_to_repairs(auth.uid())
    );

CREATE POLICY "client_loyalty_points_update_policy" ON client_loyalty_points
    FOR UPDATE USING (
        can_be_assigned_to_repairs(auth.uid())
    );

-- Politiques pour loyalty_points_history
CREATE POLICY "loyalty_points_history_read_policy" ON loyalty_points_history
    FOR SELECT USING (
        can_be_assigned_to_repairs(auth.uid())
    );

CREATE POLICY "loyalty_points_history_insert_policy" ON loyalty_points_history
    FOR INSERT WITH CHECK (
        can_be_assigned_to_repairs(auth.uid())
    );

-- Politiques pour loyalty_rules
CREATE POLICY "loyalty_rules_read_policy" ON loyalty_rules
    FOR SELECT USING (
        can_be_assigned_to_repairs(auth.uid())
    );

CREATE POLICY "loyalty_rules_update_policy" ON loyalty_rules
    FOR UPDATE USING (
        can_be_assigned_to_repairs(auth.uid())
    );

-- =====================================================
-- TRIGGERS POUR LA MAINTENANCE AUTOMATIQUE
-- =====================================================

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_loyalty_tiers_updated_at 
    BEFORE UPDATE ON loyalty_tiers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_referrals_updated_at 
    BEFORE UPDATE ON referrals 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_loyalty_points_updated_at 
    BEFORE UPDATE ON client_loyalty_points 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loyalty_rules_updated_at 
    BEFORE UPDATE ON loyalty_rules 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VÉRIFICATION FINALE
-- =====================================================

SELECT 
    'SYSTÈME DE POINTS DE FIDÉLITÉ CRÉÉ AVEC SUCCÈS' as status,
    'Toutes les tables et fonctions ont été créées' as message;

-- Afficher un résumé des tables créées
SELECT 
    'TABLES CRÉÉES' as info,
    'loyalty_tiers' as table_name,
    COUNT(*) as record_count
FROM loyalty_tiers
UNION ALL
SELECT 
    'TABLES CRÉÉES' as info,
    'loyalty_rules' as table_name,
    COUNT(*) as record_count
FROM loyalty_rules;

-- Tester les fonctions
SELECT 
    'FONCTIONS DISPONIBLES' as info,
    'add_loyalty_points, confirm_referral, reject_referral, get_client_loyalty_info, get_client_loyalty_history, get_pending_referrals' as functions;
