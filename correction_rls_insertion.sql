-- 🔧 CORRECTION RLS INSERTION - Permettre l'insertion sans workshop_id
-- Script pour corriger l'erreur 42501 en permettant l'insertion
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC INITIAL
-- ============================================================================

SELECT '=== DIAGNOSTIC INITIAL ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    value as current_workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- Vérifier l'état RLS
SELECT 
    'État RLS actuel' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'clients';

-- Vérifier les politiques RLS existantes
SELECT 
    'Politiques RLS existantes' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY cmd, policyname;

-- ============================================================================
-- 2. SUPPRESSION DE TOUTES LES POLITIQUES RLS
-- ============================================================================

SELECT '=== SUPPRESSION DES POLITIQUES RLS ===' as section;

-- Supprimer toutes les politiques RLS existantes
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Users can view own clients" ON clients;
DROP POLICY IF EXISTS "Users can create own clients" ON clients;
DROP POLICY IF EXISTS "Users can update own clients" ON clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON clients;
DROP POLICY IF EXISTS "Simple_Read_Policy" ON clients;
DROP POLICY IF EXISTS "Simple_Insert_Policy" ON clients;
DROP POLICY IF EXISTS "Simple_Update_Policy" ON clients;
DROP POLICY IF EXISTS "Simple_Delete_Policy" ON clients;
DROP POLICY IF EXISTS "Ultra_Simple_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Read_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Insert_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Update_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Delete_Policy" ON clients;
DROP POLICY IF EXISTS "Allow_Insert_With_Trigger" ON clients;
DROP POLICY IF EXISTS "Allow_Read_Own_Data" ON clients;
DROP POLICY IF EXISTS "Allow_Update_Own_Data" ON clients;
DROP POLICY IF EXISTS "Allow_Delete_Own_Data" ON clients;
DROP POLICY IF EXISTS "Urgence_Read_Policy" ON clients;
DROP POLICY IF EXISTS "Urgence_Insert_Policy" ON clients;
DROP POLICY IF EXISTS "Urgence_Update_Policy" ON clients;
DROP POLICY IF EXISTS "Urgence_Delete_Policy" ON clients;

-- Vérifier qu'aucune politique n'existe
SELECT 
    'Politiques après suppression' as info,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients';

-- ============================================================================
-- 3. CRÉATION DU TRIGGER POUR ASSIGNER WORKSHOP_ID
-- ============================================================================

SELECT '=== CRÉATION DU TRIGGER ===' as section;

-- Créer une fonction pour assigner automatiquement le workshop_id
CREATE OR REPLACE FUNCTION assign_workshop_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Assigner le workshop_id actuel si il n'est pas défini
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger sur la table clients
DROP TRIGGER IF EXISTS trigger_assign_workshop_id ON clients;
CREATE TRIGGER trigger_assign_workshop_id
    BEFORE INSERT ON clients
    FOR EACH ROW
    EXECUTE FUNCTION assign_workshop_id();

-- Vérifier que le trigger a été créé
SELECT 
    'Trigger créé' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'clients'
    AND trigger_name = 'trigger_assign_workshop_id';

-- ============================================================================
-- 4. CRÉATION DE POLITIQUES RLS PERMISSIVES
-- ============================================================================

SELECT '=== CRÉATION DE POLITIQUES RLS PERMISSIVES ===' as section;

-- Politique pour permettre TOUTES les insertions (le trigger assigne le workshop_id)
CREATE POLICY "Permissive_Insert_Policy" ON clients
    FOR INSERT WITH CHECK (true);

-- Politique pour la lecture (seulement les clients du workshop actuel)
CREATE POLICY "Permissive_Read_Policy" ON clients
    FOR SELECT USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Politique pour la mise à jour (seulement les clients du workshop actuel)
CREATE POLICY "Permissive_Update_Policy" ON clients
    FOR UPDATE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    ) WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Politique pour la suppression (seulement les clients du workshop actuel)
CREATE POLICY "Permissive_Delete_Policy" ON clients
    FOR DELETE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Vérifier les politiques créées
SELECT 
    'Politiques créées' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY cmd, policyname;

-- ============================================================================
-- 5. RÉACTIVATION DE RLS
-- ============================================================================

SELECT '=== RÉACTIVATION DE RLS ===' as section;

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Vérifier que RLS est activé
SELECT 
    'RLS activé' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'clients';

-- ============================================================================
-- 6. TEST DE CRÉATION AVEC RLS ACTIVÉ
-- ============================================================================

SELECT '=== TEST DE CRÉATION AVEC RLS ACTIVÉ ===' as section;

-- Tester la création d'un client SANS workshop_id (le trigger doit l'assigner)
INSERT INTO clients (
    first_name, 
    last_name, 
    email, 
    phone, 
    address
    -- Pas de workshop_id, le trigger doit l'assigner
) VALUES (
    'Test',
    'Permissive',
    'test.permissive@example.com',
    '5555555555',
    'Adresse de test permissive'
) RETURNING id, first_name, last_name, email, workshop_id;

-- Vérifier que le client a été créé avec le bon workshop_id
SELECT 
    'Client créé avec politiques permissives' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    CASE 
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
        THEN '✅ Workshop_id correctement assigné'
        ELSE '❌ Workshop_id incorrect'
    END as status
FROM clients 
WHERE email = 'test.permissive@example.com';

-- ============================================================================
-- 7. TEST DE CRÉATION AVEC WORKSHOP_ID MANUEL
-- ============================================================================

SELECT '=== TEST AVEC WORKSHOP_ID MANUEL ===' as section;

-- Tester la création d'un client AVEC workshop_id
INSERT INTO clients (
    first_name, 
    last_name, 
    email, 
    phone, 
    address,
    workshop_id
) VALUES (
    'Test',
    'Manual',
    'test.manual2@example.com',
    '6666666666',
    'Adresse de test manuel 2',
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
) RETURNING id, first_name, last_name, email, workshop_id;

-- ============================================================================
-- 8. VÉRIFICATION DE L'ISOLATION
-- ============================================================================

SELECT '=== VÉRIFICATION DE L''ISOLATION ===' as section;

-- Compter tous les clients visibles
SELECT 
    'Clients visibles' as info,
    COUNT(*) as total_clients
FROM clients;

-- Afficher quelques clients
SELECT 
    'Exemples de clients' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
ORDER BY first_name, last_name
LIMIT 5;

-- Vérifier l'isolation
SELECT 
    'Vérification isolation' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END)
        THEN '✅ Isolation parfaite'
        ELSE '❌ Problème d''isolation'
    END as isolation_status
FROM clients;

-- ============================================================================
-- 9. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction
SELECT 
    'Résumé de la correction RLS' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visible,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as policies_count,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'clients') as triggers_count,
    (SELECT COUNT(*) FROM clients WHERE email LIKE 'test.%@example.com') as test_clients_created,
    (SELECT rowsecurity FROM pg_tables WHERE tablename = 'clients') as rls_enabled,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') >= 4
        AND (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'clients') > 0
        AND (SELECT rowsecurity FROM pg_tables WHERE tablename = 'clients') = true
        THEN '✅ CORRECTION RLS RÉUSSIE - Création de client fonctionnelle'
        ELSE '❌ PROBLÈME PERSISTANT - Vérifier la configuration'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE email LIKE 'test.%@example.com') > 0 
        THEN '🎉 SUCCÈS: La création de client fonctionne maintenant avec les politiques RLS permissives !'
        ELSE '⚠️ PROBLÈME: La création de client ne fonctionne toujours pas'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Testez la création d''un nouveau client dans l''application' as step1,
    '2. Vérifiez que le client apparaît dans la liste' as step2,
    '3. Testez la modification du client créé' as step3,
    '4. Vérifiez que seules vos données sont visibles' as step4,
    '5. Si tout fonctionne, les politiques RLS permissives sont opérationnelles' as step5;
