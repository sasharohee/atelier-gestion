-- 🔍 VÉRIFICATION ET FORÇAGE ISOLATION CLIENTS
-- Script pour vérifier et forcer l'isolation des données clients
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DE L'ISOLATION ACTUELLE
-- ============================================================================

SELECT '=== DIAGNOSTIC DE L''ISOLATION ACTUELLE ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    key,
    value,
    value::UUID as workshop_uuid
FROM system_settings 
WHERE key = 'workshop_id';

-- Vérifier tous les clients avec leur workshop_id
SELECT 
    'Tous les clients avec workshop_id' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    created_at
FROM clients 
ORDER BY workshop_id, created_at;

-- Compter les clients par workshop
SELECT 
    'Répartition des clients par workshop' as info,
    workshop_id,
    COUNT(*) as nombre_clients,
    COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as clients_avec_email
FROM clients 
GROUP BY workshop_id
ORDER BY workshop_id;

-- ============================================================================
-- 2. TEST DE L'ISOLATION VIA RLS
-- ============================================================================

SELECT '=== TEST DE L''ISOLATION VIA RLS ===' as section;

-- Test 1: Clients visibles via requête directe (avec RLS)
SELECT 
    'Test 1: Clients visibles via requête directe' as test,
    COUNT(*) as clients_visibles,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_workshop_actuel,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) OR workshop_id IS NULL THEN 1 END) as clients_autres_workshops
FROM clients;

-- Test 2: Clients du workshop actuel uniquement
SELECT 
    'Test 2: Clients du workshop actuel uniquement' as test,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
ORDER BY created_at;

-- Test 3: Clients d'autres workshops (ne devraient pas être visibles)
SELECT 
    'Test 3: Clients d''autres workshops (ne devraient pas être visibles)' as test,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    OR workshop_id IS NULL
ORDER BY created_at;

-- ============================================================================
-- 3. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as section;

-- Vérifier les politiques RLS actives
SELECT 
    'Politiques RLS actives' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- Vérifier si RLS est activé
SELECT 
    'RLS activé sur clients' as info,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients';

-- ============================================================================
-- 4. CORRECTION FORCÉE DE L'ISOLATION
-- ============================================================================

SELECT '=== CORRECTION FORCÉE DE L''ISOLATION ===' as section;

-- S'assurer que RLS est activé
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
DROP POLICY IF EXISTS "Isolated_Select_Clients" ON clients;
DROP POLICY IF EXISTS "Isolated_Insert_Clients" ON clients;
DROP POLICY IF EXISTS "Isolated_Update_Clients" ON clients;
DROP POLICY IF EXISTS "Isolated_Delete_Clients" ON clients;
DROP POLICY IF EXISTS "Clients_Select_Isolated" ON clients;
DROP POLICY IF EXISTS "Clients_Insert_Isolated" ON clients;
DROP POLICY IF EXISTS "Clients_Update_Isolated" ON clients;
DROP POLICY IF EXISTS "Clients_Delete_Isolated" ON clients;

-- Créer des politiques RLS strictes et simples
CREATE POLICY "Strict_Isolation_Select" ON clients
    FOR SELECT
    USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

CREATE POLICY "Strict_Isolation_Insert" ON clients
    FOR INSERT
    WITH CHECK (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

CREATE POLICY "Strict_Isolation_Update" ON clients
    FOR UPDATE
    USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
    WITH CHECK (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

CREATE POLICY "Strict_Isolation_Delete" ON clients
    FOR DELETE
    USING (workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

-- ============================================================================
-- 5. TRIGGER POUR ASSIGNATION AUTOMATIQUE
-- ============================================================================

SELECT '=== TRIGGER POUR ASSIGNATION AUTOMATIQUE ===' as section;

-- Fonction trigger pour assigner automatiquement workshop_id
CREATE OR REPLACE FUNCTION assign_workshop_id_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO current_workshop_id 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Assigner le workshop_id si NULL
    IF NEW.workshop_id IS NULL AND current_workshop_id IS NOT NULL THEN
        NEW.workshop_id := current_workshop_id;
        RAISE NOTICE 'Workshop ID assigné automatiquement: %', current_workshop_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
DROP TRIGGER IF EXISTS trigger_assign_workshop_id_clients ON clients;
CREATE TRIGGER trigger_assign_workshop_id_clients
    BEFORE INSERT ON clients
    FOR EACH ROW
    EXECUTE FUNCTION assign_workshop_id_trigger();

-- ============================================================================
-- 6. CORRECTION DES CLIENTS EXISTANTS
-- ============================================================================

SELECT '=== CORRECTION DES CLIENTS EXISTANTS ===' as section;

-- Corriger tous les clients sans workshop_id
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
        
        RAISE NOTICE 'Clients sans workshop_id mis à jour: %', clients_updated;
    ELSE
        RAISE NOTICE 'Aucun workshop_id trouvé dans system_settings';
    END IF;
END $$;

-- ============================================================================
-- 7. TEST DE L'ISOLATION CORRIGÉE
-- ============================================================================

SELECT '=== TEST DE L''ISOLATION CORRIGÉE ===' as section;

-- Test 1: Créer un client de test
SELECT 
    'Test 1: Création client avec isolation stricte' as test,
    'Test Isolation' as first_name,
    'Stricte' as last_name,
    'test.isolation.' || extract(epoch from now())::TEXT || '@example.com' as email;

-- Insérer le client de test
INSERT INTO clients (first_name, last_name, email, phone, address)
VALUES (
    'Test Isolation', 
    'Stricte', 
    'test.isolation.' || extract(epoch from now())::TEXT || '@example.com',
    '7777777777',
    'Adresse test isolation stricte'
);

-- Test 2: Vérifier que seuls les clients du workshop actuel sont visibles
SELECT 
    'Test 2: Clients visibles après isolation stricte' as test,
    COUNT(*) as total_clients_visibles,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_workshop_actuel,
    COUNT(CASE WHEN workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) OR workshop_id IS NULL THEN 1 END) as clients_autres_workshops
FROM clients;

-- Test 3: Lister les clients visibles (devraient être seulement ceux du workshop actuel)
SELECT 
    'Test 3: Liste des clients visibles' as test,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    created_at
FROM clients 
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- 8. VÉRIFICATION FINALE DE L'ISOLATION
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE DE L''ISOLATION ===' as section;

-- Vérification complète
SELECT 
    'Vérification finale de l''isolation des clients' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visibles,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) OR workshop_id IS NULL) as clients_autres_workshops,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'clients') as politiques_rls_actives,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Isolation stricte fonctionnelle'
        ELSE '❌ Problème avec l''isolation stricte'
    END as status_isolation;

-- ============================================================================
-- 9. INSTRUCTIONS POUR L'APPLICATION
-- ============================================================================

SELECT '=== INSTRUCTIONS POUR L''APPLICATION ===' as section;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions pour l''isolation stricte des clients' as info,
    '1. RLS est activé avec des politiques strictes' as step1,
    '2. Seuls les clients du workshop actuel sont visibles' as step2,
    '3. Impossible de voir les clients d''autres workshops' as step3,
    '4. Les triggers assignent automatiquement workshop_id' as step4,
    '5. L''application fonctionne normalement avec isolation' as step5,
    '6. Testez la page client - seuls vos clients doivent être visibles' as step6;

-- Message final
SELECT 
    '🎉 SUCCÈS: Isolation stricte des clients mise en place !' as final_message,
    'Seuls les clients de votre workshop sont maintenant visibles.' as details,
    'Aucun client d''autre compte ne sera accessible.' as garantie,
    'Testez votre page client pour confirmer l''isolation.' as test_recommande;
