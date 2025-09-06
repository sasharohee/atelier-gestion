-- SCRIPT DE DÉBOGAGE : Vérifier les paramètres utilisateur
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'existence des tables
SELECT 'Tables existantes' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_profiles', 'user_preferences');

-- 2. Vérifier la structure des tables
SELECT 'Structure user_profiles' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_profiles';

SELECT 'Structure user_preferences' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_preferences';

-- 3. Vérifier les politiques RLS
SELECT 'Politiques RLS user_profiles' as info;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'user_profiles';

SELECT 'Politiques RLS user_preferences' as info;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'user_preferences';

-- 4. Vérifier les données existantes
SELECT 'Données user_profiles' as info;
SELECT COUNT(*) as count FROM user_profiles;

SELECT 'Données user_preferences' as info;
SELECT COUNT(*) as count FROM user_preferences;

-- 5. Vérifier l'utilisateur actuel
SELECT 'Utilisateur actuel' as info;
SELECT auth.uid() as current_user_id;

-- 6. Tester les permissions
SELECT 'Test permissions user_profiles' as info;
SELECT * FROM user_profiles WHERE user_id = auth.uid();

SELECT 'Test permissions user_preferences' as info;
SELECT * FROM user_preferences WHERE user_id = auth.uid();
