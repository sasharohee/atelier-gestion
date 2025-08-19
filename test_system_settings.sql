-- Script de test pour vérifier les paramètres système
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier que la table existe et contient des données
SELECT 'Table system_settings' as test, COUNT(*) as count FROM system_settings;

-- 2. Vérifier le contenu de la table
SELECT 'Contenu de la table' as test, key, value, category FROM system_settings ORDER BY category, key;

-- 3. Vérifier les politiques RLS
SELECT 'Politiques RLS' as test, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'system_settings';

-- 4. Vérifier les permissions de l'utilisateur actuel
SELECT 'Utilisateur actuel' as test, auth.uid() as current_user_id;

-- 5. Vérifier si l'utilisateur actuel est administrateur
SELECT 'Rôle utilisateur' as test, role 
FROM users 
WHERE id = auth.uid();

-- 6. Test de lecture directe (sans RLS)
SELECT 'Test lecture directe' as test, COUNT(*) as count 
FROM system_settings;

-- 7. Test de lecture avec RLS (doit être exécuté par un utilisateur connecté)
-- Cette requête peut échouer si l'utilisateur n'a pas les bonnes permissions
SELECT 'Test lecture avec RLS' as test, COUNT(*) as count 
FROM system_settings;

-- 8. Vérifier les triggers
SELECT 'Triggers' as test, trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'system_settings';

-- 9. Vérifier les index
SELECT 'Index' as test, indexname, indexdef
FROM pg_indexes 
WHERE tablename = 'system_settings';
