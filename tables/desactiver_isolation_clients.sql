-- Script pour désactiver temporairement l'isolation des données
-- À utiliser uniquement pour les tests et le débogage

-- 1. Vérifier l'état actuel
SELECT 
    'ÉTAT ACTUEL' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 2. Désactiver RLS temporairement
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- 3. Vérifier la désactivation
SELECT 
    'RLS DÉSACTIVÉ' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients' 
AND schemaname = 'public';

-- 4. Test d'accès sans isolation
SELECT 
    'TEST ACCÈS SANS ISOLATION' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000'::uuid THEN 1 END) as clients_systeme,
    COUNT(CASE WHEN user_id IS NOT NULL AND user_id != '00000000-0000-0000-0000-000000000000'::uuid THEN 1 END) as clients_utilisateur
FROM clients;

-- 5. Afficher tous les clients
SELECT 
    'TOUS LES CLIENTS' as section,
    id,
    first_name,
    last_name,
    email,
    user_id,
    created_at
FROM clients 
ORDER BY created_at DESC 
LIMIT 10;

-- 6. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '⚠️ ATTENTION: RLS désactivé temporairement!';
    RAISE NOTICE '💡 Tous les utilisateurs peuvent maintenant accéder à tous les clients';
    RAISE NOTICE '🔒 Pour réactiver l''isolation, exécutez: correction_isolation_clients.sql';
    RAISE NOTICE '🧪 Vous pouvez maintenant tester le formulaire client sans restrictions';
END $$;
