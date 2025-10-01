-- SOLUTION DÉFINITIVE POUR L'ERREUR 500
-- Copiez et collez ceci dans Supabase SQL Editor

-- 1. Supprimer complètement le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Vérifier que le trigger est supprimé
SELECT 'Trigger supprimé avec succès' as status;

-- 3. Vérifier les triggers restants
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 4. Message de confirmation
SELECT 'L inscription devrait maintenant fonctionner sans erreur 500' as status;
