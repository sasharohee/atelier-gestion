-- SOLUTION SIMPLE: Corriger l'erreur d'inscription Supabase Auth
-- Ce script désactive le trigger problématique et permet l'inscription normale

-- 1. Supprimer le trigger problématique qui cause l'erreur 500
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.on_auth_user_created();

-- 3. Vérifier qu'aucun trigger ne reste sur auth.users
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 4. Message de confirmation
SELECT '✅ Triggers problématiques supprimés - Inscription Supabase Auth devrait maintenant fonctionner' as status;
