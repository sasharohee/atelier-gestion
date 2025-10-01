-- SOLUTION IMMÉDIATE : Désactiver le trigger problématique
-- Copiez et collez ce script dans l'éditeur SQL de Supabase

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Vérifier la suppression
SELECT 'Trigger supprimé avec succès' as status;

-- 4. Vérifier les triggers restants
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 5. Confirmation finale
SELECT 'L inscription devrait maintenant fonctionner' as status;
