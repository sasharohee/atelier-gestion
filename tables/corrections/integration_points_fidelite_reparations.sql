-- =====================================================
-- INTÉGRATION SYSTÈME DE POINTS DE FIDÉLITÉ AVEC RÉPARATIONS
-- =====================================================
-- Ce script intègre le système de points de fidélité
-- avec les réparations existantes
-- =====================================================

-- 1. AJOUTER LES COLONNES NÉCESSAIRES À LA TABLE REPAIRS
DO $$ 
BEGIN
    -- Ajouter la colonne loyalty_discount_percentage si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'loyalty_discount_percentage') THEN
        ALTER TABLE repairs ADD COLUMN loyalty_discount_percentage DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_discount_percentage ajoutée à la table repairs';
    ELSE
        RAISE NOTICE 'La colonne loyalty_discount_percentage existe déjà dans la table repairs';
    END IF;
    
    -- Ajouter la colonne loyalty_points_used si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'loyalty_points_used') THEN
        ALTER TABLE repairs ADD COLUMN loyalty_points_used INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_points_used ajoutée à la table repairs';
    ELSE
        RAISE NOTICE 'La colonne loyalty_points_used existe déjà dans la table repairs';
    END IF;
    
    -- Ajouter la colonne final_price si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'final_price') THEN
        ALTER TABLE repairs ADD COLUMN final_price DECIMAL(10,2);
        RAISE NOTICE 'Colonne final_price ajoutée à la table repairs';
    ELSE
        RAISE NOTICE 'La colonne final_price existe déjà dans la table repairs';
    END IF;
END $$;

-- 2. Mettre à jour les réparations existantes
UPDATE repairs 
SET final_price = total_price 
WHERE final_price IS NULL;

-- 3. Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_repairs_loyalty_discount ON repairs(loyalty_discount_percentage);

-- =====================================================
-- FONCTIONS POUR LA GESTION DES RÉDUCTIONS
-- =====================================================

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
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer la réparation
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Réparation non trouvée'
        );
    END IF;
    
    -- Récupérer les informations de fidélité du client
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = v_repair.client_id;
    
    -- Si le client n'a pas de points de fidélité, pas de réduction
    IF v_client_loyalty.id IS NULL THEN
        v_discount_percentage := 0;
    ELSE
        -- Récupérer le niveau de fidélité actuel
        SELECT * INTO v_tier
        FROM loyalty_tiers
        WHERE id = v_client_loyalty.current_tier_id;
        
        IF v_tier.id IS NOT NULL THEN
            v_discount_percentage := v_tier.discount_percentage;
        ELSE
            v_discount_percentage := 0;
        END IF;
    END IF;
    
    -- Calculer le prix final
    v_final_price := v_repair.total_price * (1 - v_discount_percentage / 100);
    
    -- Mettre à jour la réparation
    UPDATE repairs
    SET 
        loyalty_discount_percentage = v_discount_percentage,
        final_price = v_final_price,
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    -- Retourner le résultat
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

-- Fonction pour appliquer une réduction manuelle avec points
CREATE OR REPLACE FUNCTION apply_manual_loyalty_discount(
    p_repair_id UUID,
    p_points_to_use INTEGER,
    p_discount_percentage DECIMAL(5,2) DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_repair repairs%ROWTYPE;
    v_client_loyalty client_loyalty_points%ROWTYPE;
    v_rules loyalty_rules%ROWTYPE;
    v_discount_percentage DECIMAL(5,2);
    v_final_price DECIMAL(10,2);
    v_points_value DECIMAL(10,2);
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer la réparation
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Réparation non trouvée'
        );
    END IF;
    
    -- Récupérer les informations de fidélité du client
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = v_repair.client_id;
    
    IF v_client_loyalty.id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le client n''a pas de points de fidélité'
        );
    END IF;
    
    -- Vérifier que le client a assez de points
    IF (v_client_loyalty.total_points - v_client_loyalty.used_points) < p_points_to_use THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le client n''a pas assez de points disponibles'
        );
    END IF;
    
    -- Récupérer les règles de points
    SELECT * INTO v_rules
    FROM loyalty_rules
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Calculer la valeur des points
    v_points_value := p_points_to_use * v_rules.points_per_euro_spent;
    
    -- Déterminer le pourcentage de réduction
    IF p_discount_percentage IS NOT NULL THEN
        v_discount_percentage := p_discount_percentage;
    ELSE
        -- Calculer automatiquement basé sur la valeur des points
        v_discount_percentage := (v_points_value / v_repair.total_price) * 100;
        -- Limiter à 50% maximum
        v_discount_percentage := LEAST(v_discount_percentage, 50.0);
    END IF;
    
    -- Calculer le prix final
    v_final_price := v_repair.total_price * (1 - v_discount_percentage / 100);
    
    -- Mettre à jour la réparation
    UPDATE repairs
    SET 
        loyalty_discount_percentage = v_discount_percentage,
        loyalty_points_used = p_points_to_use,
        final_price = v_final_price,
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    -- Déduire les points utilisés
    UPDATE client_loyalty_points
    SET 
        used_points = used_points + p_points_to_use,
        updated_at = NOW()
    WHERE client_id = v_repair.client_id;
    
    -- Enregistrer l'utilisation des points
    INSERT INTO loyalty_points_history (
        client_id, points_change, points_type, source_type,
        source_id, description, created_by
    ) VALUES (
        v_repair.client_id, -p_points_to_use, 'used', 'purchase',
        p_repair_id, 'Points utilisés pour réduction sur réparation', auth.uid()
    );
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'repair_id', p_repair_id,
            'original_price', v_repair.total_price,
            'points_used', p_points_to_use,
            'discount_percentage', v_discount_percentage,
            'discount_amount', v_repair.total_price - v_final_price,
            'final_price', v_final_price,
            'remaining_points', (v_client_loyalty.total_points - v_client_loyalty.used_points) - p_points_to_use
        ),
        'message', 'Réduction appliquée avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''application de la réduction: ' || SQLERRM
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
    v_workshop_id UUID;
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;
    
    -- Calculer les statistiques
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
                AND workshop_id = v_workshop_id
            ),
            'total_discount_amount', (
                SELECT COALESCE(SUM(total_price - final_price), 0)
                FROM repairs
                WHERE loyalty_discount_percentage > 0
                AND workshop_id = v_workshop_id
            ),
            'tier_distribution', (
                SELECT json_object_agg(tier_name, client_count)
                FROM (
                    SELECT 
                        COALESCE(lt.name, 'Aucun niveau') as tier_name,
                        COUNT(*) as client_count
                    FROM client_loyalty_points clp
                    LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id
                    GROUP BY lt.name
                    ORDER BY lt.min_points
                ) tier_stats
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
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Vérifier que les clients existent
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
    
    -- Vérifier que ce n'est pas le même client
    IF p_referrer_client_id = p_referred_client_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un client ne peut pas se parrainer lui-même'
        );
    END IF;
    
    -- Vérifier qu'il n'y a pas déjà un parrainage entre ces clients
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
    
    -- Créer le parrainage
    INSERT INTO referrals (
        referrer_client_id, 
        referred_client_id, 
        notes
    ) VALUES (
        p_referrer_client_id,
        p_referred_client_id,
        p_notes
    ) RETURNING id INTO v_referral_id;
    
    -- Retourner le résultat
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

-- =====================================================
-- TRIGGER POUR CALCULER AUTOMATIQUEMENT LES RÉDUCTIONS
-- =====================================================

-- Fonction trigger pour calculer automatiquement les réductions
CREATE OR REPLACE FUNCTION auto_calculate_loyalty_discount()
RETURNS TRIGGER AS $$
BEGIN
    -- Si le client_id change ou si c'est une nouvelle réparation
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.client_id IS DISTINCT FROM NEW.client_id) THEN
        -- Calculer automatiquement la réduction
        PERFORM calculate_loyalty_discount(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
DROP TRIGGER IF EXISTS trigger_auto_calculate_loyalty_discount ON repairs;
CREATE TRIGGER trigger_auto_calculate_loyalty_discount
    AFTER INSERT OR UPDATE OF client_id ON repairs
    FOR EACH ROW EXECUTE FUNCTION auto_calculate_loyalty_discount();

-- =====================================================
-- VÉRIFICATION ET TEST
-- =====================================================

-- Vérifier que les colonnes ont été ajoutées
SELECT 
    'VÉRIFICATION COLONNES' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'repairs' 
AND column_name IN ('loyalty_discount_percentage', 'loyalty_points_used', 'final_price')
ORDER BY column_name;

-- Mettre à jour les réparations existantes avec les prix finaux
UPDATE repairs 
SET final_price = total_price 
WHERE final_price IS NULL;

-- Afficher un résumé des nouvelles fonctionnalités
SELECT 
    'FONCTIONS AJOUTÉES' as info,
    'calculate_loyalty_discount, apply_manual_loyalty_discount, get_loyalty_statistics, create_referral' as functions;

-- Tester la fonction de statistiques
SELECT 
    'TEST STATISTIQUES' as info,
    get_loyalty_statistics() as result;
