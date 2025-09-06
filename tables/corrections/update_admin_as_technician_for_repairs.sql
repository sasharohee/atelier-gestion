-- =====================================================
-- MISE A JOUR POUR CONSIDERER LES ADMINISTRATEURS COMME TECHNICIENS
-- Ce script met a jour les politiques RLS et fonctions pour que
-- les administrateurs apparaissent comme techniciens pour les reparations
-- =====================================================

-- 1. Fonction pour verifier si un utilisateur peut etre assigne a des reparations
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

-- 2. Fonction pour obtenir tous les utilisateurs eligibles pour les reparations
CREATE OR REPLACE FUNCTION get_repair_eligible_users()
RETURNS TABLE (
  id UUID,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  role TEXT,
  display_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    (au.raw_user_meta_data->>'role')::TEXT as role,
    CASE 
      WHEN (au.raw_user_meta_data->>'role')::TEXT = 'technician' THEN
        u.first_name || ' ' || u.last_name
      ELSE
        u.first_name || ' ' || u.last_name || ' (' || (au.raw_user_meta_data->>'role')::TEXT || ')'
    END as display_name
  FROM users u
  JOIN auth.users au ON u.id = au.id
  WHERE (au.raw_user_meta_data->>'role')::TEXT IN ('technician', 'admin', 'manager')
  ORDER BY u.first_name, u.last_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Mettre a jour les politiques RLS pour les reparations
-- Politique pour permettre aux techniciens, admins et managers de voir les reparations
DROP POLICY IF EXISTS "repairs_select_policy" ON repairs;
CREATE POLICY "repairs_select_policy" ON repairs
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    );

-- Politique pour permettre aux techniciens, admins et managers de creer des reparations
DROP POLICY IF EXISTS "repairs_insert_policy" ON repairs;
CREATE POLICY "repairs_insert_policy" ON repairs
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

-- Politique pour permettre aux techniciens, admins et managers de modifier les reparations
DROP POLICY IF EXISTS "repairs_update_policy" ON repairs;
CREATE POLICY "repairs_update_policy" ON repairs
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

-- 4. Mettre a jour les politiques RLS pour les clients
-- Politique pour permettre aux techniciens, admins et managers de gerer les clients
DROP POLICY IF EXISTS "clients_insert_policy" ON clients;
CREATE POLICY "clients_insert_policy" ON clients
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

DROP POLICY IF EXISTS "clients_update_policy" ON clients;
CREATE POLICY "clients_update_policy" ON clients
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

-- 5. Mettre a jour les politiques RLS pour les appareils
-- Politique pour permettre aux techniciens, admins et managers de gerer les appareils
DROP POLICY IF EXISTS "devices_insert_policy" ON devices;
CREATE POLICY "devices_insert_policy" ON devices
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

DROP POLICY IF EXISTS "devices_update_policy" ON devices;
CREATE POLICY "devices_update_policy" ON devices
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        ) AND
        can_be_assigned_to_repairs(auth.uid())
    );

-- 6. Fonction RPC pour obtenir les utilisateurs eligibles pour les reparations
CREATE OR REPLACE FUNCTION get_repair_technicians()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', id,
      'firstName', first_name,
      'lastName', last_name,
      'email', email,
      'role', role,
      'displayName', display_name
    )
  ) INTO v_result
  FROM get_repair_eligible_users();
  
  RETURN json_build_object(
    'success', true,
    'data', COALESCE(v_result, '[]'::json)
  );
END;
$$;

-- 7. Mettre a jour la fonction de calcul des performances des techniciens
CREATE OR REPLACE FUNCTION calculate_technician_performance(
    p_technician_id UUID,
    p_period_start DATE,
    p_period_end DATE
) RETURNS void AS $$
DECLARE
    v_total_repairs INTEGER;
    v_completed_repairs INTEGER;
    v_avg_repair_time NUMERIC(10,2);
    v_total_revenue NUMERIC(10,2);
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;
    
    -- Verifier que l'utilisateur peut etre assigne a des reparations
    IF NOT can_be_assigned_to_repairs(p_technician_id) THEN
        RAISE EXCEPTION 'Utilisateur non eligible pour les reparations';
    END IF;
    
    -- Calculer les metriques
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'completed' THEN 1 END),
        COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400), 0),
        COALESCE(SUM(total_price), 0)
    INTO v_total_repairs, v_completed_repairs, v_avg_repair_time, v_total_revenue
    FROM repairs 
    WHERE assigned_technician_id = p_technician_id
    AND workshop_id = v_workshop_id
    AND created_at >= p_period_start 
    AND created_at <= p_period_end;
    
    -- Inserer ou mettre a jour les metriques
    INSERT INTO technician_performance (
        technician_id, period_start, period_end, 
        total_repairs, completed_repairs, avg_repair_time, 
        total_revenue, workshop_id
    ) VALUES (
        p_technician_id, p_period_start, p_period_end,
        v_total_repairs, v_completed_repairs, v_avg_repair_time,
        v_total_revenue, v_workshop_id
    )
    ON CONFLICT (technician_id, period_start, period_end)
    DO UPDATE SET
        total_repairs = EXCLUDED.total_repairs,
        completed_repairs = EXCLUDED.completed_repairs,
        avg_repair_time = EXCLUDED.avg_repair_time,
        total_revenue = EXCLUDED.total_revenue,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Verification finale
SELECT 
  'MISE A JOUR TERMINEE AVEC SUCCES' as status,
  'Administrateurs consideres comme techniciens pour les reparations' as message;

-- 9. Tester la fonction get_repair_eligible_users
SELECT 
  'TEST FONCTION get_repair_eligible_users' as info,
  get_repair_eligible_users();

-- 10. Tester la fonction RPC
SELECT 
  'TEST FONCTION RPC get_repair_technicians' as info,
  get_repair_technicians();

-- 11. Afficher les politiques mises a jour
SELECT 
  'POLITIQUES MISES A JOUR' as info,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('repairs', 'clients', 'devices')
  AND policyname LIKE '%policy'
ORDER BY tablename, policyname;
