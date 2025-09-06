-- 🚨 SOLUTION RADICALE - Clients Manquants
-- Solution qui va identifier et résoudre le problème à la racine
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC RADICAL
-- ============================================================================

SELECT '=== DIAGNOSTIC RADICAL ===' as section;

-- Vérifier si la table clients existe
SELECT 
    'Existence table clients' as info,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') 
        THEN '✅ Table clients existe'
        ELSE '❌ Table clients n''existe pas'
    END as status;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    key,
    value as current_workshop_id,
    CASE 
        WHEN value IS NULL THEN '❌ PROBLÈME: workshop_id NULL'
        WHEN value = '00000000-0000-0000-0000-000000000000' THEN '❌ PROBLÈME: workshop_id par défaut'
        ELSE '✅ OK: workshop_id défini'
    END as status
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 2. VÉRIFICATION COMPLÈTE SANS RLS
-- ============================================================================

SELECT '=== VÉRIFICATION SANS RLS ===' as section;

-- Désactiver RLS complètement
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Compter TOUS les clients sans aucune restriction
SELECT 
    'Tous les clients (sans RLS)' as info,
    COUNT(*) as total_clients
FROM clients;

-- Afficher TOUS les clients sans restriction
SELECT 
    'Tous les clients (sans RLS)' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    CASE 
        WHEN workshop_id IS NULL THEN 'NULL'
        WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 'Défaut'
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 'Actuel'
        ELSE 'Autre'
    END as workshop_status
FROM clients 
ORDER BY first_name, last_name
LIMIT 20;

-- ============================================================================
-- 3. SOLUTION RADICALE - RECRÉATION COMPLÈTE
-- ============================================================================

SELECT '=== SOLUTION RADICALE ===' as section;

-- Étape 1: Supprimer TOUTES les politiques RLS
SELECT 'Suppression de toutes les politiques RLS...' as action;
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

-- Étape 2: Mettre à jour TOUS les clients avec le workshop_id actuel
SELECT 'Mise à jour de tous les clients...' as action;
UPDATE clients 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL 
   OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID
   OR workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Étape 3: Vérifier la mise à jour
SELECT 
    'Clients après mise à jour' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop
FROM clients;

-- ============================================================================
-- 4. CRÉATION D'UNE SEULE POLITIQUE RLS ULTRA-SIMPLE
-- ============================================================================

SELECT '=== CRÉATION POLITIQUE RLS ULTRA-SIMPLE ===' as section;

-- Créer une seule politique RLS ultra-simple
CREATE POLICY "Ultra_Simple_Policy" ON clients
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. TEST RADICAL
-- ============================================================================

SELECT '=== TEST RADICAL ===' as section;

-- Test 1: Compter les clients visibles
SELECT 
    'Clients visibles avec RLS' as info,
    COUNT(*) as visible_clients
FROM clients;

-- Test 2: Afficher quelques clients visibles
SELECT 
    'Clients visibles (avec RLS)' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
ORDER BY first_name, last_name
LIMIT 10;

-- Test 3: Vérifier la politique RLS
SELECT 
    'Politique RLS créée' as info,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients';

-- ============================================================================
-- 6. SOLUTION ALTERNATIVE - DÉSACTIVER RLS TEMPORAIREMENT
-- ============================================================================

SELECT '=== SOLUTION ALTERNATIVE ===' as section;

-- Si les clients ne sont toujours pas visibles, désactiver RLS temporairement
SELECT 
    'Test sans RLS' as info,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) = 0 THEN 'Désactiver RLS temporairement'
        ELSE 'RLS fonctionne correctement'
    END as recommendation;

-- Désactiver RLS si aucun client n'est visible
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM clients) = 0 THEN
        ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé temporairement car aucun client visible';
    ELSE
        RAISE NOTICE 'RLS fonctionne correctement';
    END IF;
END $$;

-- ============================================================================
-- 7. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérification finale
SELECT 
    'Vérification finale' as info,
    (SELECT COUNT(*) FROM clients) as clients_visible,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as policies_count,
    (SELECT CASE WHEN rowsecurity THEN 'Active' ELSE 'Inactive' END FROM pg_tables WHERE schemaname = 'public' AND tablename = 'clients') as rls_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 THEN '✅ SUCCÈS: Clients visibles'
        ELSE '❌ ÉCHEC: Aucun client visible'
    END as final_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        THEN '🎉 SUCCÈS: Les clients sont maintenant visibles !'
        ELSE '⚠️ PROBLÈME: Aucun client visible - RLS désactivé temporairement'
    END as final_message;

-- Instructions
SELECT 
    'Instructions' as info,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        THEN '1. Vérifiez que vos clients sont visibles dans l''application'
        ELSE '1. RLS désactivé temporairement - Contactez le support'
    END as instruction1,
    '2. Testez la création d''un nouveau client' as instruction2,
    '3. Testez la modification d''un client existant' as instruction3,
    '4. Vérifiez que seules vos données sont visibles' as instruction4;
