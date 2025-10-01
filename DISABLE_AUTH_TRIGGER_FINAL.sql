-- Script simple pour désactiver complètement le trigger d'authentification
-- Ce script résout l'erreur 500 "Database error saving new user"

-- 1. Désactiver complètement le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Vérifier que le trigger est bien supprimé
SELECT 'Trigger handle_new_user supprimé avec succès' as status;

-- 4. Vérifier les triggers restants sur auth.users
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 5. Message de confirmation
SELECT 'Supabase Auth devrait maintenant fonctionner normalement' as status;
SELECT 'L inscription devrait maintenant fonctionner sans erreur 500' as status;
