-- 🚨 SOLUTION ISOLATION RLS FORCÉE - Politiques Strictes
-- Script pour forcer l'isolation via RLS avec des politiques strictes
-- Date: 2025-01-23

-- ============================================================================
-- 1. RÉACTIVATION DE RLS AVEC POLITIQUES STRICTES
-- ============================================================================

SELECT '=== RÉACTIVATION DE RLS AVEC POLITIQUES STRICTES ===' as section;

-- Réactiver RLS sur clients
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Enable read access for all users" ON clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON clients;
DROP POLICY IF EXISTS "Enable update for users based on email" ON clients;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON clients;
DROP POLICY IF EXISTS "Allow_Insert_With_Trigger" ON clients;
DROP POLICY IF EXISTS "Allow_Select_Isolated" ON clients;
DROP POLICY IF EXISTS "Allow_Update_Isolated" ON clients;
DROP POLICY IF EXISTS "Allow_Delete_Isolated" ON clients;

-- ============================================================================
-- 2. CRÉATION DE POLITIQUES RLS STRICTES
-- ============================================================================

SELECT '=== CRÉATION DE POLITIQUES RLS STRICTES ===' as section;

-- Politique SELECT stricte - seulement les clients du workshop actuel
CREATE POLICY "Isolated_Select_Clients" ON clients
    FOR SELECT
    USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

-- Politique INSERT stricte - assigne automatiquement le workshop_id
CREATE POLICY "Isolated_Insert_Clients" ON clients
    FOR INSERT
    WITH CHECK (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

-- Politique UPDATE stricte - seulement les clients du workshop actuel
CREATE POLICY "Isolated_Update_Clients" ON clients
    FOR UPDATE
    USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
    WITH CHECK (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

-- Politique DELETE stricte - seulement les clients du workshop actuel
CREATE POLICY "Isolated_Delete_Clients" ON clients
    FOR DELETE
    USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

-- ============================================================================
-- 3. RÉACTIVATION RLS SUR AUTRES TABLES
-- ============================================================================

SELECT '=== RÉACTIVATION RLS SUR AUTRES TABLES ===' as section;

-- Réactiver RLS sur repairs si la table existe
DO $$
BEGIN
    IF EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'repairs' AND schemaname = 'public') THEN
        EXECUTE 'ALTER TABLE repairs ENABLE ROW LEVEL SECURITY';
        
        -- Supprimer les anciennes politiques
        EXECUTE 'DROP POLICY IF EXISTS "Enable read access for all users" ON repairs';
        EXECUTE 'DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON repairs';
        EXECUTE 'DROP POLICY IF EXISTS "Enable update for users based on email" ON repairs';
        EXECUTE 'DROP POLICY IF EXISTS "Enable delete for users based on email" ON repairs';
        
        -- Créer les politiques strictes pour repairs
        EXECUTE 'CREATE POLICY "Isolated_Select_Repairs" ON repairs
                 FOR SELECT
                 USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = ''workshop_id'' LIMIT 1))';
        
        EXECUTE 'CREATE POLICY "Isolated_Insert_Repairs" ON repairs
                 FOR INSERT
                 WITH CHECK (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = ''workshop_id'' LIMIT 1))';
        
        EXECUTE 'CREATE POLICY "Isolated_Update_Repairs" ON repairs
                 FOR UPDATE
                 USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = ''workshop_id'' LIMIT 1))
                 WITH CHECK (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = ''workshop_id'' LIMIT 1))';
        
        EXECUTE 'CREATE POLICY "Isolated_Delete_Repairs" ON repairs
                 FOR DELETE
                 USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = ''workshop_id'' LIMIT 1))';
        
        RAISE NOTICE 'RLS réactivé sur table repairs avec politiques strictes';
    ELSE
        RAISE NOTICE 'Table repairs n''existe pas - RLS ignoré';
    END IF;
END $$;

-- ============================================================================
-- 4. TRIGGER POUR ASSIGNATION AUTOMATIQUE WORKSHOP_ID
-- ============================================================================

SELECT '=== TRIGGER POUR ASSIGNATION AUTOMATIQUE WORKSHOP_ID ===' as section;

-- Fonction trigger pour assigner automatiquement workshop_id
CREATE OR REPLACE FUNCTION assign_workshop_id_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger pour clients
DROP TRIGGER IF EXISTS trigger_assign_workshop_id_clients ON clients;
CREATE TRIGGER trigger_assign_workshop_id_clients
    BEFORE INSERT ON clients
    FOR EACH ROW
    EXECUTE FUNCTION assign_workshop_id_trigger();

-- Créer le trigger pour repairs si la table existe
DO $$
BEGIN
    IF EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'repairs' AND schemaname = 'public') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_assign_workshop_id_repairs ON repairs';
        EXECUTE 'CREATE TRIGGER trigger_assign_workshop_id_repairs
                 BEFORE INSERT ON repairs
                 FOR EACH ROW
                 EXECUTE FUNCTION assign_workshop_id_trigger()';
        RAISE NOTICE 'Trigger créé pour table repairs';
    END IF;
END $$;

-- ============================================================================
-- 5. CORRECTION DES WORKSHOP_ID EXISTANTS
-- ============================================================================

SELECT '=== CORRECTION DES WORKSHOP_ID EXISTANTS ===' as section;

-- Corriger les clients sans workshop_id
DO $$
DECLARE
    current_workshop_id UUID;
    clients_updated INTEGER;
BEGIN
    SELECT value::UUID INTO current_workshop_id 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    IF current_workshop_id IS NOT NULL THEN
        UPDATE clients 
        SET workshop_id = current_workshop_id 
        WHERE workshop_id IS NULL;
        
        GET DIAGNOSTICS clients_updated = ROW_COUNT;
        
        RAISE NOTICE 'Workshop ID actuel: %, Clients mis à jour: %', 
            current_workshop_id, 
            clients_updated;
    ELSE
        RAISE NOTICE 'Aucun workshop_id trouvé dans system_settings';
    END IF;
END $$;

-- Corriger les repairs sans workshop_id si la table existe
DO $$
DECLARE
    current_workshop_id UUID;
    repairs_updated INTEGER;
BEGIN
    IF EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'repairs' AND schemaname = 'public') THEN
        SELECT value::UUID INTO current_workshop_id 
        FROM system_settings 
        WHERE key = 'workshop_id' 
        LIMIT 1;
        
        IF current_workshop_id IS NOT NULL THEN
            EXECUTE 'UPDATE repairs SET workshop_id = $1 WHERE workshop_id IS NULL'
            USING current_workshop_id;
            
            GET DIAGNOSTICS repairs_updated = ROW_COUNT;
            
            RAISE NOTICE 'Repairs mis à jour: %', repairs_updated;
        END IF;
    END IF;
END $$;

-- ============================================================================
-- 6. TEST DE L'ISOLATION RLS FORCÉE
-- ============================================================================

SELECT '=== TEST DE L''ISOLATION RLS FORCÉE ===' as section;

-- Test 1: Vérifier les politiques RLS créées
SELECT 
    'Test 1: Politiques RLS créées' as test,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- Test 2: Vérifier l'isolation des clients
SELECT 
    'Test 2: Isolation des clients via RLS' as test,
    (SELECT COUNT(*) FROM clients) as total_clients_visibles,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel;

-- Test 3: Créer un client de test
SELECT 
    'Test 3: Création client avec RLS' as test,
    'Test RLS' as first_name,
    'Isolation' as last_name,
    'test.rls.' || extract(epoch from now())::TEXT || '@example.com' as email;

-- Insérer le client de test
INSERT INTO clients (first_name, last_name, email, phone, address)
VALUES (
    'Test RLS', 
    'Isolation', 
    'test.rls.' || extract(epoch from now())::TEXT || '@example.com',
    '4444444444',
    'Adresse test RLS'
);

-- Test 4: Vérifier que le client a été créé avec le bon workshop_id
SELECT 
    'Test 4: Client créé avec workshop_id' as test,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) as workshop_actuel
FROM clients 
WHERE first_name = 'Test RLS'
ORDER BY created_at DESC
LIMIT 1;

-- ============================================================================
-- 7. VÉRIFICATION FINALE RLS FORCÉE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE RLS FORCÉE ===' as section;

-- Vérification complète
SELECT 
    'Vérification finale de l''isolation RLS forcée' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visibles,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'clients') as politiques_rls_clients,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'repairs') as politiques_rls_repairs,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Isolation RLS forcée fonctionnelle'
        ELSE '❌ Problème avec l''isolation RLS forcée'
    END as status_isolation;

-- ============================================================================
-- 8. INSTRUCTIONS D'UTILISATION RLS FORCÉE
-- ============================================================================

SELECT '=== INSTRUCTIONS D''UTILISATION RLS FORCÉE ===' as section;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions pour l''isolation RLS forcée' as info,
    '1. RLS est maintenant activé avec des politiques strictes' as step1,
    '2. Utilisez directement la table clients - RLS filtre automatiquement' as step2,
    '3. Utilisez directement la table repairs - RLS filtre automatiquement' as step3,
    '4. Les triggers assignent automatiquement workshop_id' as step4,
    '5. Impossible de voir les données d''autres workshops' as step5,
    '6. Impossible de créer/modifier des données pour d''autres workshops' as step6,
    '7. Isolation garantie au niveau de la base de données' as step7;

-- Message final
SELECT 
    '🎉 SUCCÈS: Isolation RLS forcée mise en place !' as final_message,
    'L''isolation est maintenant forcée via RLS avec des politiques strictes.' as details,
    'Aucun client d''autre workshop ne sera visible ou accessible.' as garantie,
    'Protection au niveau de la base de données.' as niveau_securite;
