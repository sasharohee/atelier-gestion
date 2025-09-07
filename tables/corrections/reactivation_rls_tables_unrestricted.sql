-- =====================================================
-- RÉACTIVATION RLS SUR TABLES "UNRESTRICTED" (SAUF VUES)
-- =====================================================
-- Ce script réactive le Row Level Security (RLS) sur toutes les tables
-- marquées "Unrestricted" dans Supabase, en excluant les vues

-- =====================================================
-- 1. IDENTIFICATION DES TABLES À SÉCURISER
-- =====================================================

-- Liste des vues à exclure (ne pas activer RLS dessus)
-- Ces vues sont des objets virtuels et n'ont pas besoin de RLS
CREATE TEMP TABLE excluded_views AS
SELECT unnest(ARRAY[
    'loyalty_dashboard',
    'clients_all', 
    'clients_filtered',
    'repairs_filtered',
    'repair_tracking_view',
    'repair_history_view', 
    'clients_isolated',
    'repairs_isolated',
    'device_models_filtered',
    'consolidated_statistics',
    'top_clients',
    'top_devices',
    'sales_by_category',
    'clients_filtrés',
    'loyalty_dashboard_iso',
    'device_models_my_mode',
    'clients_isolated_final',
    'archived_repairs_view',
    'repair_stats_view',
    'client_loyalty_points',
    'device_models_my_models',
    'loyalty_points_isolated',
    'loyalty_history_isolated',
    'loyalty_dashboard_isolated',
    'clients_isolated_simple'
]) AS view_name;

-- =====================================================
-- 2. FONCTION POUR ACTIVER RLS SUR UNE TABLE
-- =====================================================

CREATE OR REPLACE FUNCTION activate_rls_on_table(target_table_name TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    table_exists BOOLEAN;
    is_view BOOLEAN;
BEGIN
    -- Vérifier si la table existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = target_table_name
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RETURN '❌ Table ' || target_table_name || ' n''existe pas';
    END IF;
    
    -- Vérifier si c'est une vue
    SELECT EXISTS (
        SELECT FROM information_schema.views 
        WHERE table_schema = 'public' 
        AND table_name = target_table_name
    ) INTO is_view;
    
    IF is_view THEN
        RETURN '⚠️ ' || target_table_name || ' est une vue (RLS non applicable)';
    END IF;
    
    -- Vérifier si la table est dans la liste d'exclusion
    IF EXISTS (SELECT 1 FROM excluded_views WHERE view_name = target_table_name) THEN
        RETURN '⚠️ ' || target_table_name || ' est dans la liste d''exclusion (vue)';
    END IF;
    
    -- Activer RLS
    BEGIN
        EXECUTE 'ALTER TABLE ' || quote_ident(target_table_name) || ' ENABLE ROW LEVEL SECURITY';
        RETURN '✅ RLS activé sur ' || target_table_name;
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ Erreur sur ' || target_table_name || ': ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. ACTIVATION RLS SUR TOUTES LES TABLES UNRESTRICTED
-- =====================================================

-- Tables principales identifiées comme "Unrestricted" dans Supabase
DO $$
DECLARE
    table_record RECORD;
    result_text TEXT;
BEGIN
    -- Liste des tables à sécuriser (basée sur l'interface Supabase)
    FOR table_record IN 
        SELECT unnest(ARRAY[
            'appointments',
            'clients_all',
            'clients_filtered', 
            'devices',
            'loyalty_dashboard',
            'orders',
            'repair_history',
            'repair_tracking',
            'repairs',
            'repairs_filtered',
            'repairs_isolation',
            'sales',
            'sales_by_category',
            'subscription_status',
            'system_settings',
            'users'
        ]) AS table_name
    LOOP
        result_text := activate_rls_on_table(table_record.table_name);
        RAISE NOTICE '%', result_text;
    END LOOP;
END $$;

-- =====================================================
-- 4. CRÉATION DE POLITIQUES RLS DE BASE
-- =====================================================

-- Politiques pour la table 'users' (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        -- Supprimer les politiques existantes
        DROP POLICY IF EXISTS "users_select_policy" ON users;
        DROP POLICY IF EXISTS "users_update_policy" ON users;
        
        -- Politique de lecture pour les utilisateurs authentifiés
        CREATE POLICY "users_select_policy" ON users
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        -- Politique de mise à jour pour l'utilisateur lui-même
        CREATE POLICY "users_update_policy" ON users
            FOR UPDATE USING (id = auth.uid());
            
        RAISE NOTICE '✅ Politiques RLS créées pour la table users';
    END IF;
END $$;

-- Politiques pour la table 'subscription_status' (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'subscription_status' AND table_schema = 'public') THEN
        -- Supprimer les politiques existantes
        DROP POLICY IF EXISTS "subscription_status_select_policy" ON subscription_status;
        DROP POLICY IF EXISTS "subscription_status_update_policy" ON subscription_status;
        
        -- Politique de lecture pour les utilisateurs authentifiés
        CREATE POLICY "subscription_status_select_policy" ON subscription_status
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        -- Politique de mise à jour pour l'utilisateur lui-même
        CREATE POLICY "subscription_status_update_policy" ON subscription_status
            FOR UPDATE USING (user_id = auth.uid());
            
        RAISE NOTICE '✅ Politiques RLS créées pour la table subscription_status';
    END IF;
END $$;

-- Politiques pour la table 'appointments' (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'appointments' AND table_schema = 'public') THEN
        -- Supprimer les politiques existantes
        DROP POLICY IF EXISTS "appointments_select_policy" ON appointments;
        DROP POLICY IF EXISTS "appointments_insert_policy" ON appointments;
        DROP POLICY IF EXISTS "appointments_update_policy" ON appointments;
        
        -- Politique de lecture
        CREATE POLICY "appointments_select_policy" ON appointments
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        -- Politique d'insertion
        CREATE POLICY "appointments_insert_policy" ON appointments
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
            
        -- Politique de mise à jour
        CREATE POLICY "appointments_update_policy" ON appointments
            FOR UPDATE USING (auth.uid() IS NOT NULL);
            
        RAISE NOTICE '✅ Politiques RLS créées pour la table appointments';
    END IF;
END $$;

-- Politiques pour la table 'orders' (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'orders' AND table_schema = 'public') THEN
        -- Supprimer les politiques existantes
        DROP POLICY IF EXISTS "orders_select_policy" ON orders;
        DROP POLICY IF EXISTS "orders_insert_policy" ON orders;
        DROP POLICY IF EXISTS "orders_update_policy" ON orders;
        
        -- Politique de lecture
        CREATE POLICY "orders_select_policy" ON orders
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        -- Politique d'insertion
        CREATE POLICY "orders_insert_policy" ON orders
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
            
        -- Politique de mise à jour
        CREATE POLICY "orders_update_policy" ON orders
            FOR UPDATE USING (auth.uid() IS NOT NULL);
            
        RAISE NOTICE '✅ Politiques RLS créées pour la table orders';
    END IF;
END $$;

-- Politiques pour la table 'sales' (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sales' AND table_schema = 'public') THEN
        -- Supprimer les politiques existantes
        DROP POLICY IF EXISTS "sales_select_policy" ON sales;
        DROP POLICY IF EXISTS "sales_insert_policy" ON sales;
        DROP POLICY IF EXISTS "sales_update_policy" ON sales;
        
        -- Politique de lecture
        CREATE POLICY "sales_select_policy" ON sales
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        -- Politique d'insertion
        CREATE POLICY "sales_insert_policy" ON sales
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
            
        -- Politique de mise à jour
        CREATE POLICY "sales_update_policy" ON sales
            FOR UPDATE USING (auth.uid() IS NOT NULL);
            
        RAISE NOTICE '✅ Politiques RLS créées pour la table sales';
    END IF;
END $$;

-- Politiques pour la table 'system_settings' (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'system_settings' AND table_schema = 'public') THEN
        -- Supprimer les politiques existantes
        DROP POLICY IF EXISTS "system_settings_select_policy" ON system_settings;
        DROP POLICY IF EXISTS "system_settings_update_policy" ON system_settings;
        
        -- Politique de lecture pour tous les utilisateurs authentifiés
        CREATE POLICY "system_settings_select_policy" ON system_settings
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        -- Politique de mise à jour pour les admins seulement
        CREATE POLICY "system_settings_update_policy" ON system_settings
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM auth.users 
                    WHERE auth.users.id = auth.uid() 
                    AND auth.users.raw_user_meta_data->>'role' = 'admin'
                )
            );
            
        RAISE NOTICE '✅ Politiques RLS créées pour la table system_settings';
    END IF;
END $$;

-- =====================================================
-- 5. VÉRIFICATION DE L'ÉTAT DES TABLES
-- =====================================================

-- Fonction pour vérifier l'état de sécurité de toutes les tables
CREATE OR REPLACE FUNCTION check_all_tables_security()
RETURNS TABLE (
    table_name TEXT,
    table_type TEXT,
    has_rls BOOLEAN,
    policy_count INTEGER,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.views v WHERE v.table_schema = 'public' AND v.table_name = t.tablename) 
            THEN 'VIEW'::TEXT
            ELSE 'BASE TABLE'::TEXT
        END as table_type,
        t.rowsecurity as has_rls,
        COALESCE(p.policy_count, 0)::INTEGER as policy_count,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.views v WHERE v.table_schema = 'public' AND v.table_name = t.tablename) 
            THEN '👁️ Vue (RLS non applicable)'
            WHEN t.rowsecurity = true AND COALESCE(p.policy_count, 0) > 0 THEN '✅ Sécurisé'
            WHEN t.rowsecurity = false THEN '❌ RLS désactivé'
            WHEN t.rowsecurity = true AND COALESCE(p.policy_count, 0) = 0 THEN '⚠️ RLS activé mais pas de politique'
            ELSE '❓ Inconnu'
        END as status
    FROM pg_tables t
    LEFT JOIN (
        SELECT 
            schemaname,
            tablename,
            COUNT(*) as policy_count
        FROM pg_policies 
        WHERE schemaname = 'public'
        GROUP BY schemaname, tablename
    ) p ON t.schemaname = p.schemaname AND t.tablename = p.tablename
    WHERE t.schemaname = 'public' 
    AND t.tablename NOT LIKE 'pg_%'
    AND t.tablename NOT LIKE 'sql_%'
    ORDER BY table_type, t.tablename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. AFFICHAGE DU RÉSULTAT
-- =====================================================

-- Afficher l'état de sécurité de toutes les tables
SELECT * FROM check_all_tables_security();

-- =====================================================
-- 7. COMMENTAIRES ET DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION activate_rls_on_table(TEXT) IS 'Fonction pour activer RLS sur une table spécifique (paramètre: target_table_name)';
COMMENT ON FUNCTION check_all_tables_security() IS 'Fonction pour vérifier l''état de sécurité de toutes les tables';

-- =====================================================
-- 8. NOTES IMPORTANTES
-- =====================================================

/*
NOTES IMPORTANTES :

1. VUES EXCLUES : Les vues ne peuvent pas avoir de RLS activé car elles sont des objets virtuels.
   Les vues suivantes ont été identifiées et exclues :
   - loyalty_dashboard, clients_all, clients_filtered, repairs_filtered
   - repair_tracking_view, repair_history_view, clients_isolated, repairs_isolated
   - device_models_filtered, consolidated_statistics, top_clients, top_devices
   - sales_by_category, et autres vues listées dans excluded_views

2. POLITIQUES RLS : Des politiques de base ont été créées pour les tables principales.
   Ces politiques peuvent être ajustées selon vos besoins spécifiques.

3. VÉRIFICATION : Utilisez la fonction check_all_tables_security() pour vérifier
   l'état de sécurité de toutes vos tables après l'exécution.

4. SÉCURITÉ : Ce script active RLS mais vous devrez peut-être ajuster les politiques
   selon votre logique métier spécifique.

5. TEST : Testez l'application après l'exécution pour vous assurer que tout fonctionne
   correctement avec les nouvelles restrictions RLS.
*/
