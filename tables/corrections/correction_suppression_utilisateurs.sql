-- Correction du problème de suppression d'utilisateurs
-- Date: 2024-01-24
-- Ce script corrige les contraintes et politiques qui empêchent la suppression d'utilisateurs

-- ========================================
-- 1. SUPPRIMER LES TRIGGERS PROBLÉMATIQUES
-- ========================================

-- Supprimer tous les triggers sur auth.users qui pourraient interférer
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS create_user_default_data_trigger ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON auth.users;

-- Supprimer les fonctions associées
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data() CASCADE;
DROP FUNCTION IF EXISTS on_auth_user_created() CASCADE;
DROP FUNCTION IF EXISTS on_auth_user_created_simple() CASCADE;

-- ========================================
-- 2. CORRIGER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- ========================================

-- Fonction pour modifier les contraintes de clés étrangères
CREATE OR REPLACE FUNCTION fix_foreign_key_constraints()
RETURNS TEXT AS $$
DECLARE
    constraint_record RECORD;
    sql_command TEXT;
    result TEXT := '';
BEGIN
    -- Parcourir toutes les contraintes de clés étrangères qui référencent auth.users
    FOR constraint_record IN
        SELECT 
            tc.table_name,
            tc.constraint_name,
            kcu.column_name,
            rc.delete_rule
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        JOIN information_schema.referential_constraints AS rc
            ON tc.constraint_name = rc.constraint_name
            AND tc.table_schema = rc.constraint_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_name = 'users'
            AND ccu.table_schema = 'auth'
            AND rc.delete_rule IN ('RESTRICT', 'NO ACTION')
    LOOP
        -- Supprimer la contrainte existante
        sql_command := 'ALTER TABLE ' || constraint_record.table_name || 
                      ' DROP CONSTRAINT ' || constraint_record.constraint_name;
        EXECUTE sql_command;
        result := result || 'Supprimé: ' || constraint_record.constraint_name || E'\n';
        
        -- Recréer la contrainte avec CASCADE
        sql_command := 'ALTER TABLE ' || constraint_record.table_name || 
                      ' ADD CONSTRAINT ' || constraint_record.constraint_name || 
                      ' FOREIGN KEY (' || constraint_record.column_name || 
                      ') REFERENCES auth.users(id) ON DELETE CASCADE';
        EXECUTE sql_command;
        result := result || 'Recréé avec CASCADE: ' || constraint_record.constraint_name || E'\n';
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Exécuter la correction des contraintes
SELECT fix_foreign_key_constraints();

-- ========================================
-- 3. CORRIGER LES POLITIQUES RLS
-- ========================================

-- Supprimer les anciennes politiques DELETE problématiques
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
DROP POLICY IF EXISTS "Only admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Users can delete own" ON public.users;
DROP POLICY IF EXISTS "Enable delete" ON public.users;

-- Créer une politique DELETE sécurisée pour les admins
CREATE POLICY "Admins can delete users" ON public.users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ========================================
-- 4. CRÉER UNE FONCTION RPC POUR LA SUPPRESSION SÉCURISÉE
-- ========================================

-- Fonction pour supprimer un utilisateur de manière sécurisée
CREATE OR REPLACE FUNCTION delete_user_safely(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    user_email TEXT;
    user_role TEXT;
    current_user_role TEXT;
    result JSON;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT role INTO current_user_role 
    FROM public.users 
    WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Seuls les administrateurs peuvent supprimer des utilisateurs'
        );
    END IF;
    
    -- Vérifier que l'utilisateur à supprimer existe
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé'
        );
    END IF;
    
    -- Récupérer les informations de l'utilisateur
    SELECT email, role INTO user_email, user_role
    FROM public.users 
    WHERE id = p_user_id;
    
    -- Empêcher la suppression de l'utilisateur actuel
    IF p_user_id = auth.uid() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Vous ne pouvez pas supprimer votre propre compte'
        );
    END IF;
    
    -- Empêcher la suppression des comptes admin principaux
    IF user_email IN ('srohee32@gmail.com', 'repphonereparation@gmail.com') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Impossible de supprimer les comptes administrateurs principaux'
        );
    END IF;
    
    BEGIN
        -- Supprimer l'utilisateur de la table public.users (cascade supprimera les données liées)
        DELETE FROM public.users WHERE id = p_user_id;
        
        -- Supprimer l'utilisateur de auth.users
        DELETE FROM auth.users WHERE id = p_user_id;
        
        RETURN json_build_object(
            'success', true,
            'message', 'Utilisateur supprimé avec succès',
            'deleted_user_id', p_user_id,
            'deleted_user_email', user_email
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la suppression: ' || SQLERRM,
            'detail', SQLSTATE
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction de suppression
GRANT EXECUTE ON FUNCTION delete_user_safely(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_user_safely(UUID) TO service_role;

-- ========================================
-- 5. CRÉER UNE FONCTION POUR LA SUPPRESSION EN MASSE
-- ========================================

-- Fonction pour supprimer plusieurs utilisateurs
CREATE OR REPLACE FUNCTION delete_multiple_users_safely(p_user_ids UUID[])
RETURNS JSON AS $$
DECLARE
    user_id UUID;
    results JSON[] := '{}';
    success_count INTEGER := 0;
    error_count INTEGER := 0;
    result JSON;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Seuls les administrateurs peuvent supprimer des utilisateurs'
        );
    END IF;
    
    -- Parcourir chaque utilisateur à supprimer
    FOREACH user_id IN ARRAY p_user_ids
    LOOP
        result := delete_user_safely(user_id);
        results := array_append(results, result);
        
        IF (result->>'success')::boolean THEN
            success_count := success_count + 1;
        ELSE
            error_count := error_count + 1;
        END IF;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Suppression en masse terminée',
        'success_count', success_count,
        'error_count', error_count,
        'results', results
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction de suppression en masse
GRANT EXECUTE ON FUNCTION delete_multiple_users_safely(UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_multiple_users_safely(UUID[]) TO service_role;

-- ========================================
-- 6. CRÉER UNE FONCTION DE NETTOYAGE DES DONNÉES ORPHELINES
-- ========================================

-- Fonction pour nettoyer les données orphelines
CREATE OR REPLACE FUNCTION cleanup_orphaned_data()
RETURNS JSON AS $$
DECLARE
    cleanup_count INTEGER := 0;
    result JSON;
BEGIN
    -- Nettoyer les données orphelines dans subscription_status
    DELETE FROM public.subscription_status 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    
    -- Nettoyer les données orphelines dans system_settings
    DELETE FROM public.system_settings 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans clients
    DELETE FROM public.clients 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans repairs
    DELETE FROM public.repairs 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans products
    DELETE FROM public.products 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans sales
    DELETE FROM public.sales 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans appointments
    DELETE FROM public.appointments 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans devices
    DELETE FROM public.devices 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Nettoyage des données orphelines terminé',
        'cleaned_records', cleanup_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction de nettoyage
GRANT EXECUTE ON FUNCTION cleanup_orphaned_data() TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_orphaned_data() TO service_role;

-- ========================================
-- 7. VÉRIFICATION DE LA CONFIGURATION
-- ========================================

-- Vérifier que les contraintes sont correctement configurées
SELECT 
    'VÉRIFICATION CONTRAINTES' as check_type,
    tc.table_name,
    tc.constraint_name,
    rc.delete_rule,
    CASE 
        WHEN rc.delete_rule = 'CASCADE' THEN '✅ OK'
        WHEN rc.delete_rule = 'SET NULL' THEN '⚠️ SET NULL'
        ELSE '❌ ' || rc.delete_rule
    END as status
FROM information_schema.table_constraints AS tc 
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'users'
    AND ccu.table_schema = 'auth'
ORDER BY tc.table_name;

-- Vérifier que les fonctions RPC existent
SELECT 
    'VÉRIFICATION FONCTIONS' as check_type,
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name IN ('delete_user_safely', 'delete_multiple_users_safely', 'cleanup_orphaned_data') 
        THEN '✅ OK'
        ELSE '❌ MANQUANTE'
    END as status
FROM information_schema.routines 
WHERE routine_name IN ('delete_user_safely', 'delete_multiple_users_safely', 'cleanup_orphaned_data')
    AND routine_schema = 'public';

-- ========================================
-- 8. MESSAGE DE CONFIRMATION
-- ========================================

SELECT 'Correction terminée - La suppression d''utilisateurs devrait maintenant fonctionner' as status;
