-- ⚡ TEST IMMÉDIAT - État des Clients
-- Script de test rapide pour vérifier l'état des clients
-- Date: 2025-01-23

-- ============================================================================
-- TEST RAPIDE
-- ============================================================================

-- Test 1: Vérifier le workshop_id
SELECT 
    'Workshop ID' as info,
    value as current_workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- Test 2: Compter les clients avec RLS
SELECT 
    'Clients avec RLS' as info,
    COUNT(*) as visible_clients
FROM clients;

-- Test 3: Désactiver RLS et compter
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

SELECT 
    'Clients sans RLS' as info,
    COUNT(*) as total_clients
FROM clients;

-- Test 4: Afficher quelques clients
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

-- Test 5: Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Test 6: Vérifier les politiques RLS
SELECT 
    'Politiques RLS' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients';

-- Test 7: Résumé final
SELECT 
    'Résumé' as info,
    (SELECT COUNT(*) FROM clients) as clients_visible,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as policies_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 THEN '✅ Clients visibles'
        ELSE '❌ Aucun client visible'
    END as status;
