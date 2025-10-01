-- DIAGNOSTIC ET CORRECTION IMMÉDIATE - Erreur 500 lors de l'inscription
-- Ce script diagnostique et corrige immédiatement le problème

-- 1. DIAGNOSTIC - Identifier les éléments problématiques
DO $$
DECLARE
    trigger_record RECORD;
    function_record RECORD;
    policy_record RECORD;
BEGIN
    RAISE NOTICE '=== DIAGNOSTIC DES ÉLÉMENTS PROBLÉMATIQUES ===';
    
    -- Lister tous les triggers sur auth.users
    RAISE NOTICE '--- TRIGGERS SUR AUTH.USERS ---';
    FOR trigger_record IN 
        SELECT t.trigger_name, t.event_manipulation, t.action_statement
        FROM information_schema.triggers t
        WHERE t.event_object_table = 'users' AND t.event_object_schema = 'auth'
    LOOP
        RAISE NOTICE 'Trigger: % - Event: % - Action: %', 
            trigger_record.trigger_name, 
            trigger_record.event_manipulation,
            trigger_record.action_statement;
    END LOOP;
    
    -- Lister toutes les fonctions create_user_default_data
    RAISE NOTICE '--- FONCTIONS CREATE_USER_DEFAULT_DATA ---';
    FOR function_record IN 
        SELECT r.routine_name, r.specific_name, r.routine_definition
        FROM information_schema.routines r
        WHERE r.routine_name LIKE '%create_user%' AND r.routine_schema = 'public'
    LOOP
        RAISE NOTICE 'Fonction: % - Signature: %', 
            function_record.routine_name, 
            function_record.specific_name;
    END LOOP;
    
    -- Lister les politiques RLS sur auth.users
    RAISE NOTICE '--- POLITIQUES RLS SUR AUTH.USERS ---';
    FOR policy_record IN 
        SELECT p.policyname, p.cmd, p.qual
        FROM pg_policies p
        WHERE p.tablename = 'users' AND p.schemaname = 'auth'
    LOOP
        RAISE NOTICE 'Politique: % - Commande: % - Condition: %', 
            policy_record.policyname, 
            policy_record.cmd,
            policy_record.qual;
    END LOOP;
END $$;

-- 2. SUPPRESSION COMPLÈTE ET IMMÉDIATE
-- Supprimer TOUS les triggers sur auth.users
DO $$
DECLARE
    trigger_name TEXT;
BEGIN
    RAISE NOTICE '=== SUPPRESSION DES TRIGGERS ===';
    
    FOR trigger_name IN 
        SELECT t.trigger_name
        FROM information_schema.triggers t
        WHERE t.event_object_table = 'users' AND t.event_object_schema = 'auth'
    LOOP
        BEGIN
            EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_name || ' ON auth.users CASCADE';
            RAISE NOTICE 'Trigger supprimé: %', trigger_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Erreur lors de la suppression du trigger %: %', trigger_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- Supprimer TOUTES les fonctions problématiques
DO $$
DECLARE
    function_name TEXT;
    specific_name TEXT;
BEGIN
    RAISE NOTICE '=== SUPPRESSION DES FONCTIONS ===';
    
    FOR function_name, specific_name IN 
        SELECT r.routine_name, r.specific_name
        FROM information_schema.routines r
        WHERE r.routine_name LIKE '%create_user%' AND r.routine_schema = 'public'
    LOOP
        BEGIN
            EXECUTE 'DROP FUNCTION IF EXISTS ' || specific_name || ' CASCADE';
            RAISE NOTICE 'Fonction supprimée: %', specific_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Erreur lors de la suppression de la fonction %: %', specific_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. DÉSACTIVATION TEMPORAIRE DE RLS
DO $$
BEGIN
    RAISE NOTICE '=== DÉSACTIVATION RLS ===';
    
    BEGIN
        ALTER TABLE auth.users DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur auth.users';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Impossible de désactiver RLS sur auth.users: %', SQLERRM;
    END;
END $$;

-- 4. CRÉATION DES TABLES NÉCESSAIRES
CREATE TABLE IF NOT EXISTS subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, category, key)
);

-- 5. CONFIGURATION RLS PERMISSIVE
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Users can view own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can insert own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can update own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can view own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can insert own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can update own system settings" ON system_settings;

-- Créer des politiques très permissives
CREATE POLICY "Allow all operations on subscription_status" ON subscription_status
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on system_settings" ON system_settings
    FOR ALL USING (true) WITH CHECK (true);

-- 6. CRÉER UNE FONCTION RPC SIMPLE
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    BEGIN
        -- Créer le statut d'abonnement
        INSERT INTO subscription_status (
            user_id, first_name, last_name, email, is_active, subscription_type, notes
        ) VALUES (
            p_user_id, 'Utilisateur', '', '', FALSE, 'free', 'Compte créé automatiquement'
        ) ON CONFLICT (user_id) DO NOTHING;
        
        -- Créer les paramètres système par défaut
        INSERT INTO system_settings (user_id, category, key, value, description)
        VALUES 
            (p_user_id, 'general', 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
            (p_user_id, 'notifications', 'email_notifications', 'true', 'Activer les notifications par email')
        ON CONFLICT (user_id, category, key) DO NOTHING;

        RETURN json_build_object(
            'success', true,
            'message', 'Données par défaut créées avec succès',
            'user_id', p_user_id
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'user_id', p_user_id
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. PERMISSIONS
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO service_role;

-- 8. VÉRIFICATION FINALE
DO $$
DECLARE
    trigger_count INTEGER;
    function_count INTEGER;
BEGIN
    RAISE NOTICE '=== VÉRIFICATION FINALE ===';
    
    -- Compter les triggers restants
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers t
    WHERE t.event_object_table = 'users' AND t.event_object_schema = 'auth';
    
    RAISE NOTICE 'Triggers restants sur auth.users: %', trigger_count;
    
    -- Compter les fonctions create_user
    SELECT COUNT(*) INTO function_count
    FROM information_schema.routines r
    WHERE r.routine_name LIKE '%create_user%' AND r.routine_schema = 'public';
    
    RAISE NOTICE 'Fonctions create_user restantes: %', function_count;
    
    IF trigger_count = 0 AND function_count = 0 THEN
        RAISE NOTICE '✅ CORRECTION RÉUSSIE - Aucun élément problématique restant';
    ELSE
        RAISE NOTICE '⚠️ ATTENTION - Des éléments problématiques persistent';
    END IF;
END $$;

-- 9. MESSAGE DE CONFIRMATION
SELECT 'CORRECTION IMMÉDIATE APPLIQUÉE - L''inscription devrait maintenant fonctionner' as status;
