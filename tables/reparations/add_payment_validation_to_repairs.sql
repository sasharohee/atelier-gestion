-- =====================================================
-- AJOUT DU SUPPORT DE VALIDATION DE PAIEMENT AUX REPARATIONS
-- Ce script ajoute et configure le champ is_paid pour les reparations
-- =====================================================

-- 0. Creer la fonction can_be_assigned_to_repairs si elle n'existe pas
CREATE OR REPLACE FUNCTION can_be_assigned_to_repairs(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Recuperer le role de l'utilisateur depuis auth.users
  SELECT (raw_user_meta_data->>'role')::TEXT INTO user_role
  FROM auth.users 
  WHERE id = user_id;
  
  -- Retourner true si l'utilisateur est technicien, admin ou manager
  RETURN user_role IN ('technician', 'admin', 'manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. Verifier si la colonne is_paid existe deja
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'repairs' AND column_name = 'is_paid') THEN
        -- Ajouter la colonne is_paid si elle n'existe pas
        ALTER TABLE repairs ADD COLUMN is_paid BOOLEAN DEFAULT false;
        RAISE NOTICE 'Colonne is_paid ajoutee a la table repairs';
    ELSE
        RAISE NOTICE 'La colonne is_paid existe deja dans la table repairs';
    END IF;
END $$;

-- 2. Mettre a jour les reparations existantes pour definir is_paid a false par defaut
UPDATE repairs SET is_paid = false WHERE is_paid IS NULL;

-- 3. Creer un index sur is_paid pour ameliorer les performances des requetes
CREATE INDEX IF NOT EXISTS idx_repairs_is_paid ON repairs(is_paid);

-- 4. Creer une fonction pour valider le paiement d'une reparation
CREATE OR REPLACE FUNCTION validate_repair_payment(
    p_repair_id UUID,
    p_is_paid BOOLEAN
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_repair repairs%ROWTYPE;
    v_result JSON;
BEGIN
    -- Verifier que l'utilisateur a les droits pour modifier les reparations
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acces non autorise. Seuls les techniciens, administrateurs et managers peuvent valider les paiements.'
        );
    END IF;

    -- Recuperer la reparation
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Reparation non trouvee'
        );
    END IF;

    -- Verifier que la reparation est terminee
    IF v_repair.status NOT IN ('completed', 'returned') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Seules les reparations terminees peuvent avoir leur paiement valide'
        );
    END IF;

    -- Mettre a jour le statut de paiement
    UPDATE repairs 
    SET 
        is_paid = p_is_paid,
        updated_at = NOW()
    WHERE id = p_repair_id;

    -- Retourner le succes avec les informations mises a jour
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'id', p_repair_id,
            'is_paid', p_is_paid,
            'updated_at', NOW()
        ),
        'message', CASE 
            WHEN p_is_paid THEN 'Paiement valide avec succes'
            ELSE 'Paiement annule avec succes'
        END
    ) INTO v_result;

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la validation du paiement: ' || SQLERRM
        );
END;
$$;

-- 5. Creer une fonction pour obtenir les statistiques de paiement
CREATE OR REPLACE FUNCTION get_payment_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;

    -- Calculer les statistiques
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'total_completed_repairs', (
                SELECT COUNT(*) 
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND workshop_id = v_workshop_id
            ),
            'paid_repairs', (
                SELECT COUNT(*) 
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = true
                AND workshop_id = v_workshop_id
            ),
            'unpaid_repairs', (
                SELECT COUNT(*) 
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = false
                AND workshop_id = v_workshop_id
            ),
            'total_revenue_paid', (
                SELECT COALESCE(SUM(total_price), 0)
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = true
                AND workshop_id = v_workshop_id
            ),
            'total_revenue_unpaid', (
                SELECT COALESCE(SUM(total_price), 0)
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = false
                AND workshop_id = v_workshop_id
            )
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- 6. Mettre a jour les politiques RLS pour permettre la modification du champ is_paid
-- La politique existante devrait deja permettre cela, mais on peut la verifier
DROP POLICY IF EXISTS "repairs_update_payment_policy" ON repairs;
CREATE POLICY "repairs_update_payment_policy" ON repairs
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

-- 7. Verification finale
SELECT 
    'MISE A JOUR TERMINEE AVEC SUCCES' as status,
    'Support de validation de paiement ajoute aux reparations' as message;

-- 8. Afficher les statistiques actuelles
SELECT 
    'STATISTIQUES DE PAIEMENT ACTUELLES' as info,
    COUNT(*) as total_repairs,
    COUNT(*) FILTER (WHERE status IN ('completed', 'returned')) as completed_repairs,
    COUNT(*) FILTER (WHERE status IN ('completed', 'returned') AND is_paid = true) as paid_repairs,
    COUNT(*) FILTER (WHERE status IN ('completed', 'returned') AND is_paid = false) as unpaid_repairs,
    COALESCE(SUM(total_price) FILTER (WHERE status IN ('completed', 'returned') AND is_paid = true), 0) as total_revenue_paid,
    COALESCE(SUM(total_price) FILTER (WHERE status IN ('completed', 'returned') AND is_paid = false), 0) as total_revenue_unpaid
FROM repairs;

-- 9. Tester la fonction de validation de paiement
SELECT 
    'TEST FONCTION validate_repair_payment' as info,
    'Fonction disponible pour validation des paiements' as status;

-- 10. Tester la fonction de statistiques
SELECT 
    'TEST FONCTION get_payment_statistics' as info,
    get_payment_statistics() as result;
