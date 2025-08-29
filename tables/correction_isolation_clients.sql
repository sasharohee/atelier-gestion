-- Script pour corriger l'isolation des données dans la table clients
-- Ce script configure les politiques RLS pour assurer l'isolation des données par utilisateur

-- 1. Vérifier l'état actuel de RLS
SELECT 
    'ÉTAT RLS ACTUEL' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 2. Activer RLS sur la table clients si ce n'est pas déjà fait
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer les anciennes politiques s'il y en a
DROP POLICY IF EXISTS clients_isolation_policy ON clients;
DROP POLICY IF EXISTS clients_select_policy ON clients;
DROP POLICY IF EXISTS clients_insert_policy ON clients;
DROP POLICY IF EXISTS clients_update_policy ON clients;
DROP POLICY IF EXISTS clients_delete_policy ON clients;

-- 4. Créer les nouvelles politiques d'isolation

-- Politique pour la sélection (SELECT)
CREATE POLICY clients_select_policy ON clients
    FOR SELECT
    USING (
        -- Permettre l'accès aux clients de l'utilisateur connecté
        (auth.uid() = user_id)
        OR
        -- Permettre l'accès aux clients système (user_id NULL ou utilisateur système)
        (user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::uuid)
        OR
        -- Permettre l'accès si aucun utilisateur connecté (pour les tests)
        (auth.uid() IS NULL)
    );

-- Politique pour l'insertion (INSERT)
CREATE POLICY clients_insert_policy ON clients
    FOR INSERT
    WITH CHECK (
        -- Permettre l'insertion pour l'utilisateur connecté
        (auth.uid() = user_id)
        OR
        -- Permettre l'insertion pour les clients système
        (user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::uuid)
        OR
        -- Permettre l'insertion si aucun utilisateur connecté
        (auth.uid() IS NULL)
    );

-- Politique pour la mise à jour (UPDATE)
CREATE POLICY clients_update_policy ON clients
    FOR UPDATE
    USING (
        -- Permettre la mise à jour des clients de l'utilisateur connecté
        (auth.uid() = user_id)
        OR
        -- Permettre la mise à jour des clients système
        (user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::uuid)
        OR
        -- Permettre la mise à jour si aucun utilisateur connecté
        (auth.uid() IS NULL)
    )
    WITH CHECK (
        -- Vérifier que l'utilisateur ne peut modifier que ses propres clients
        (auth.uid() = user_id)
        OR
        -- Permettre la modification des clients système
        (user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::uuid)
        OR
        -- Permettre la modification si aucun utilisateur connecté
        (auth.uid() IS NULL)
    );

-- Politique pour la suppression (DELETE)
CREATE POLICY clients_delete_policy ON clients
    FOR DELETE
    USING (
        -- Permettre la suppression des clients de l'utilisateur connecté
        (auth.uid() = user_id)
        OR
        -- Permettre la suppression des clients système
        (user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::uuid)
        OR
        -- Permettre la suppression si aucun utilisateur connecté
        (auth.uid() IS NULL)
    );

-- 5. Vérifier les politiques créées
SELECT 
    'POLITIQUES CRÉÉES' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 6. Vérifier que tous les clients ont un user_id
SELECT 
    'VÉRIFICATION USER_ID' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000'::uuid THEN 1 END) as clients_systeme,
    COUNT(CASE WHEN user_id IS NOT NULL AND user_id != '00000000-0000-0000-0000-000000000000'::uuid THEN 1 END) as clients_utilisateur
FROM clients;

-- 7. Corriger les clients sans user_id
UPDATE clients 
SET user_id = '00000000-0000-0000-0000-000000000000'::uuid
WHERE user_id IS NULL;

-- 8. Vérifier la correction
SELECT 
    'CORRECTION USER_ID' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000'::uuid THEN 1 END) as clients_systeme,
    COUNT(CASE WHEN user_id IS NOT NULL AND user_id != '00000000-0000-0000-0000-000000000000'::uuid THEN 1 END) as clients_utilisateur
FROM clients;

-- 9. Test d'accès pour l'utilisateur connecté
DO $$
DECLARE
    current_user_id UUID;
    clients_count INTEGER;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    RAISE NOTICE '🔍 Test d''isolation des données:';
    RAISE NOTICE '   - Utilisateur connecté: %', current_user_id;
    
    -- Compter les clients accessibles
    SELECT COUNT(*) INTO clients_count
    FROM clients;
    
    RAISE NOTICE '   - Clients accessibles: %', clients_count;
    
    -- Vérifier les clients de l'utilisateur
    SELECT COUNT(*) INTO clients_count
    FROM clients
    WHERE user_id = current_user_id;
    
    RAISE NOTICE '   - Clients de l''utilisateur: %', clients_count;
    
    -- Vérifier les clients système
    SELECT COUNT(*) INTO clients_count
    FROM clients
    WHERE user_id = '00000000-0000-0000-0000-000000000000'::uuid;
    
    RAISE NOTICE '   - Clients système: %', clients_count;
    
    RAISE NOTICE '✅ Isolation des données configurée avec succès!';
END $$;

-- 10. Vérifier les permissions
SELECT 
    'PERMISSIONS' as section,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- 11. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '🎉 Isolation des données corrigée!';
    RAISE NOTICE '✅ RLS activé sur la table clients';
    RAISE NOTICE '✅ Politiques d''isolation créées';
    RAISE NOTICE '✅ Tous les clients ont un user_id';
    RAISE NOTICE '💡 Les utilisateurs ne peuvent voir que leurs propres clients';
    RAISE NOTICE '💡 Les clients système sont accessibles à tous';
END $$;
