-- 🔧 CORRECTION - Clients Manquants Après Isolation
-- Script pour corriger le problème des clients qui ne s'affichent plus
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
-- 2. CORRECTION DES CLIENTS
-- ============================================================================

SELECT '=== CORRECTION DES CLIENTS ===' as section;

-- Étape 1: Désactiver temporairement RLS
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Étape 2: Mettre à jour les clients sans workshop_id
UPDATE clients 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL;

-- Étape 3: Mettre à jour les clients avec workshop_id par défaut
UPDATE clients 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

-- Étape 4: Vérifier les résultats
SELECT 
    'Clients après correction' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as clients_without_workshop,
    COUNT(CASE WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 1 END) as clients_with_default_workshop
FROM clients;

-- ============================================================================
-- 3. RECRÉATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== RECRÉATION DES POLITIQUES RLS ===' as section;

-- Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON clients;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON clients;

-- Créer les nouvelles politiques RLS avec isolation stricte
CREATE POLICY "Enable read access for authenticated users" ON clients
    FOR SELECT USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Enable insert access for authenticated users" ON clients
    FOR INSERT WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Enable update access for authenticated users" ON clients
    FOR UPDATE USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    ) WITH CHECK (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );

CREATE POLICY "Enable delete access for authenticated users" ON clients
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

-- Vérifier les politiques RLS
SELECT 
    'Politiques RLS clients' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 5. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de la correction
SELECT 
    'Résumé de la correction' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visible,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as rls_policies_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') >= 4
        THEN '✅ CORRECTION RÉUSSIE - Les clients sont maintenant visibles'
        ELSE '❌ PROBLÈME PERSISTANT - Vérifier la configuration'
    END as correction_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        THEN '🎉 SUCCÈS: Les clients sont maintenant visibles dans votre compte !'
        ELSE '⚠️ PROBLÈME: Aucun client visible - Vérifier le workshop_id'
    END as final_message;
