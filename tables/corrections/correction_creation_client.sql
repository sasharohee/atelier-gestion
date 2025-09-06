-- 🔧 CORRECTION - Création de Client
-- Script pour corriger l'erreur PGRST116 lors de la création de client
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

-- Vérifier les politiques RLS existantes
SELECT 
    'Politiques RLS existantes' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY cmd, policyname;

-- ============================================================================
-- 2. CORRECTION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== CORRECTION DES POLITIQUES RLS ===' as section;

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

-- Créer des politiques RLS complètes et fonctionnelles
CREATE POLICY "Complete_Read_Policy" ON clients
    FOR SELECT USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Complete_Insert_Policy" ON clients
    FOR INSERT WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Complete_Update_Policy" ON clients
    FOR UPDATE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    ) WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Complete_Delete_Policy" ON clients
    FOR DELETE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. VÉRIFICATION DES POLITIQUES CRÉÉES
-- ============================================================================

SELECT '=== VÉRIFICATION DES POLITIQUES ===' as section;

-- Vérifier les nouvelles politiques
SELECT 
    'Nouvelles politiques RLS' as info,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY cmd, policyname;

-- ============================================================================
-- 4. TEST DE CRÉATION DE CLIENT
-- ============================================================================

SELECT '=== TEST DE CRÉATION ===' as section;

-- Tester la création d'un client avec RLS actif
INSERT INTO clients (
    first_name, 
    last_name, 
    email, 
    phone, 
    address, 
    workshop_id
) VALUES (
    'Test',
    'Creation',
    'test.creation@example.com',
    '0987654321',
    'Adresse de test création',
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
) RETURNING id, first_name, last_name, email, workshop_id;

-- Vérifier que le client a été créé et est visible
SELECT 
    'Client créé et visible' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
WHERE email = 'test.creation@example.com';

-- ============================================================================
-- 5. TEST DE LECTURE
-- ============================================================================

SELECT '=== TEST DE LECTURE ===' as section;

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

-- ============================================================================
-- 6. VÉRIFICATION DE L'ISOLATION
-- ============================================================================

SELECT '=== VÉRIFICATION ISOLATION ===' as section;

-- Vérifier que seuls les clients du bon workshop_id sont visibles
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
-- 7. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction
SELECT 
    'Résumé de la correction' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visible,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as policies_count,
    (SELECT COUNT(*) FROM clients WHERE email = 'test.creation@example.com') as test_client_created,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') >= 4
        AND (SELECT COUNT(*) FROM clients WHERE email = 'test.creation@example.com') > 0
        THEN '✅ CORRECTION RÉUSSIE - Création de client fonctionnelle'
        ELSE '❌ PROBLÈME PERSISTANT - Vérifier la configuration'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE email = 'test.creation@example.com') > 0 
        THEN '🎉 SUCCÈS: La création de client fonctionne maintenant !'
        ELSE '⚠️ PROBLÈME: La création de client ne fonctionne toujours pas'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Testez la création d''un nouveau client dans l''application' as step1,
    '2. Vérifiez que le client apparaît dans la liste' as step2,
    '3. Testez la modification du client créé' as step3,
    '4. Vérifiez que seules vos données sont visibles' as step4;
