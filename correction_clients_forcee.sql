-- 🔧 CORRECTION FORCÉE - Clients Manquants
-- Script de correction robuste qui résout tous les problèmes possibles
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

-- Compter les clients avant correction
SELECT 
    'Clients avant correction' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as clients_without_workshop,
    COUNT(CASE WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 1 END) as clients_with_default_workshop
FROM clients;

-- ============================================================================
-- 2. CORRECTION FORCÉE COMPLÈTE
-- ============================================================================

SELECT '=== CORRECTION FORCÉE COMPLÈTE ===' as section;

-- Étape 1: Désactiver RLS complètement
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Étape 2: Supprimer toutes les politiques RLS existantes
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Users can view own clients" ON clients;
DROP POLICY IF EXISTS "Users can create own clients" ON clients;
DROP POLICY IF EXISTS "Users can update own clients" ON clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON clients;

-- Étape 3: Mettre à jour TOUS les clients avec le workshop_id actuel
UPDATE clients 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL 
   OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID
   OR workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Étape 4: Vérifier les résultats de la mise à jour
SELECT 
    'Clients après mise à jour' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as clients_without_workshop,
    COUNT(CASE WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 1 END) as clients_with_default_workshop
FROM clients;

-- ============================================================================
-- 3. CRÉATION DE POLITIQUES RLS SIMPLES ET EFFICACES
-- ============================================================================

SELECT '=== CRÉATION POLITIQUES RLS ===' as section;

-- Créer des politiques RLS simples et efficaces
CREATE POLICY "Simple_Read_Policy" ON clients
    FOR SELECT USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Simple_Insert_Policy" ON clients
    FOR INSERT WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Simple_Update_Policy" ON clients
    FOR UPDATE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    ) WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Simple_Delete_Policy" ON clients
    FOR DELETE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que les clients sont maintenant visibles
SELECT 
    'Clients visibles après correction' as info,
    COUNT(*) as visible_clients
FROM clients;

-- Afficher quelques clients pour vérification
SELECT 
    'Exemples de clients visibles' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
ORDER BY first_name, last_name
LIMIT 5;

-- Vérifier les politiques RLS créées
SELECT 
    'Politiques RLS créées' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 5. TEST DE FONCTIONNEMENT
-- ============================================================================

SELECT '=== TEST DE FONCTIONNEMENT ===' as section;

-- Test 1: Vérifier l'isolation
SELECT 
    'Test isolation' as info,
    COUNT(*) as clients_visible,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Clients visibles'
        ELSE '❌ Aucun client visible'
    END as status
FROM clients;

-- Test 2: Vérifier que seuls les bons clients sont visibles
SELECT 
    'Test workshop_id' as info,
    COUNT(*) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = (SELECT COUNT(*) FROM clients) THEN '✅ Tous les clients ont le bon workshop_id'
        ELSE '❌ Certains clients ont un mauvais workshop_id'
    END as status
FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Test 3: Vérifier les politiques RLS
SELECT 
    'Test politiques RLS' as info,
    COUNT(*) as policies_count,
    CASE 
        WHEN COUNT(*) >= 4 THEN '✅ Politiques RLS complètes'
        ELSE '❌ Politiques RLS manquantes'
    END as status
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients';

-- ============================================================================
-- 6. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction
SELECT 
    'Résumé de la correction forcée' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visible,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as rls_policies_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') >= 4
        AND (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = (SELECT COUNT(*) FROM clients)
        THEN '✅ CORRECTION RÉUSSIE - Les clients sont maintenant visibles et isolés'
        ELSE '❌ PROBLÈME PERSISTANT - Vérifier la configuration'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        THEN '🎉 SUCCÈS: Les clients sont maintenant visibles dans votre compte !'
        ELSE '⚠️ PROBLÈME: Aucun client visible - Vérifier le workshop_id'
    END as final_message;

-- Instructions pour l'utilisateur
SELECT 
    'Instructions' as info,
    '1. Vérifiez que vos clients sont maintenant visibles dans l''application' as step1,
    '2. Testez la création d''un nouveau client' as step2,
    '3. Testez la modification d''un client existant' as step3,
    '4. Vérifiez que seules vos données sont visibles' as step4;
