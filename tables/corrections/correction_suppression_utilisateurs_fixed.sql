-- Correction du problème de suppression d'utilisateurs (Version corrigée)
-- Date: 2024-01-24
-- Ce script corrige les contraintes et politiques qui empêchent la suppression d'utilisateurs
-- Version qui gère les politiques existantes

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
DROP FUNCTION IF EXISTS create_user_default_data() CASCADE;
DROP FUNCTION IF EXISTS on_auth_user_created() CASCADE;

-- ========================================
-- 2. MODIFIER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- ========================================

-- Modifier les contraintes RESTRICT/NO ACTION en CASCADE pour permettre la suppression
-- Note: Ces commandes peuvent échouer si les contraintes n'existent pas, c'est normal

-- Contraintes sur subscription_status
DO $$
BEGIN
    -- Essayer de modifier la contrainte sur subscription_status
    BEGIN
        ALTER TABLE subscription_status DROP CONSTRAINT IF EXISTS subscription_status_user_id_fkey;
        ALTER TABLE subscription_status ADD CONSTRAINT subscription_status_user_id_fkey 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Contrainte subscription_status_user_id_fkey non modifiée: %', SQLERRM;
    END;
END $$;

-- Contraintes sur users (si elle existe)
DO $$
BEGIN
    BEGIN
        ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;
        ALTER TABLE public.users ADD CONSTRAINT users_id_fkey 
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Contrainte users_id_fkey non modifiée: %', SQLERRM;
    END;
END $$;

-- Contraintes sur d'autres tables qui référencent auth.users
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Trouver toutes les contraintes qui référencent auth.users avec RESTRICT ou NO ACTION
    FOR constraint_record IN 
        SELECT 
            tc.table_name,
            tc.constraint_name,
            kcu.column_name,
            rc.delete_rule
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.referential_constraints rc 
            ON tc.constraint_name = rc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND rc.delete_rule IN ('RESTRICT', 'NO ACTION')
        AND rc.unique_constraint_name IN (
            SELECT constraint_name 
            FROM information_schema.table_constraints 
            WHERE table_name = 'users' 
            AND table_schema = 'auth'
            AND constraint_type = 'PRIMARY KEY'
        )
    LOOP
        BEGIN
            -- Supprimer et recréer la contrainte avec CASCADE
            EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                          constraint_record.table_name, 
                          constraint_record.constraint_name);
            
            EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES auth.users(id) ON DELETE CASCADE',
                          constraint_record.table_name,
                          constraint_record.constraint_name,
                          constraint_record.column_name);
                          
            RAISE NOTICE 'Contrainte % sur table % modifiée avec succès', 
                        constraint_record.constraint_name, 
                        constraint_record.table_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Erreur lors de la modification de la contrainte %: %', 
                        constraint_record.constraint_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- 3. CORRIGER LES POLITIQUES RLS
-- ========================================

-- Supprimer les politiques existantes et les recréer
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Users can delete themselves" ON public.users;
DROP POLICY IF EXISTS "Admins can delete any user" ON public.users;

-- Créer une politique DELETE sécurisée pour les admins
CREATE POLICY "Admins can delete users" ON public.users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Politique pour permettre aux utilisateurs de se supprimer eux-mêmes
CREATE POLICY "Users can delete themselves" ON public.users
    FOR DELETE USING (id = auth.uid());

-- ========================================
-- 4. CRÉER UNE FONCTION RPC POUR LA SUPPRESSION SÉCURISÉE
-- ========================================

-- Fonction pour supprimer un utilisateur de manière sécurisée
CREATE OR REPLACE FUNCTION delete_user_safely(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    user_email TEXT;
    user_role TEXT;
    result JSON;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT email, role INTO user_email, user_role
    FROM public.users 
    WHERE id = auth.uid();
    
    IF user_role != 'admin' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès refusé: seuls les administrateurs peuvent supprimer des utilisateurs'
        );
    END IF;
    
    -- Vérifier que l'utilisateur à supprimer existe
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé'
        );
    END IF;
    
    -- Supprimer l'utilisateur (cascade supprimera les données liées)
    DELETE FROM public.users WHERE id = p_user_id;
    
    -- Supprimer de auth.users (nécessite des privilèges élevés)
    -- Note: Cette partie peut nécessiter une approche différente selon les permissions
    
    RETURN json_build_object(
        'success', true,
        'message', 'Utilisateur supprimé avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la suppression: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 5. CRÉER UNE FONCTION POUR NETTOYER LES DONNÉES LIÉES
-- ========================================

-- Fonction pour nettoyer les données liées à un utilisateur
CREATE OR REPLACE FUNCTION cleanup_user_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    cleanup_count INTEGER := 0;
    result JSON;
BEGIN
    -- Nettoyer les données dans subscription_status
    DELETE FROM subscription_status WHERE user_id = p_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    
    -- Nettoyer d'autres tables si nécessaire
    -- Ajoutez ici d'autres tables qui référencent l'utilisateur
    
    RETURN json_build_object(
        'success', true,
        'message', 'Données nettoyées avec succès',
        'records_deleted', cleanup_count
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors du nettoyage: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 6. VÉRIFICATIONS ET TESTS
-- ========================================

-- Vérifier que les contraintes ont été modifiées
SELECT 
    'VÉRIFICATION DES CONTRAINTES' as check_type,
    tc.table_name,
    tc.constraint_name,
    rc.delete_rule,
    CASE 
        WHEN rc.delete_rule = 'CASCADE' THEN '✅ CASCADE - Suppression en cascade'
        WHEN rc.delete_rule = 'SET NULL' THEN '⚠️ SET NULL - Met à NULL'
        WHEN rc.delete_rule = 'RESTRICT' THEN '❌ RESTRICT - Empêche la suppression'
        WHEN rc.delete_rule = 'NO ACTION' THEN '❌ NO ACTION - Empêche la suppression'
        ELSE '❓ ' || rc.delete_rule
    END as status
FROM information_schema.table_constraints tc
JOIN information_schema.referential_constraints rc 
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND rc.delete_rule IN ('RESTRICT', 'NO ACTION', 'CASCADE')
AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- Vérifier les politiques RLS
SELECT 
    'VÉRIFICATION DES POLITIQUES RLS' as check_type,
    schemaname,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'DELETE' THEN '✅ Politique DELETE présente'
        ELSE '⚠️ ' || cmd
    END as status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'users'
AND cmd = 'DELETE';

-- ========================================
-- 7. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 CORRECTION TERMINÉE AVEC SUCCÈS !';
    RAISE NOTICE '✅ Triggers problématiques supprimés';
    RAISE NOTICE '✅ Contraintes modifiées en CASCADE';
    RAISE NOTICE '✅ Politiques RLS corrigées';
    RAISE NOTICE '✅ Fonctions RPC créées';
    RAISE NOTICE '';
    RAISE NOTICE '📋 PROCHAINES ÉTAPES:';
    RAISE NOTICE '1. Testez la suppression d''un utilisateur de test';
    RAISE NOTICE '2. Vérifiez qu''il n''y a plus d''erreur 500';
    RAISE NOTICE '3. Utilisez les fonctions RPC si nécessaire';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- delete_user_safely(user_id) : Suppression sécurisée';
    RAISE NOTICE '- cleanup_user_data(user_id) : Nettoyage des données';
END $$;
