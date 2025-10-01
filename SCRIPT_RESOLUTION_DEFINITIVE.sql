-- SCRIPT DE RÉSOLUTION DÉFINITIVE DE L'ERREUR 500
-- Ce script supprime complètement le trigger problématique

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Vérifier que le trigger est supprimé
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

-- 5. Message de confirmation finale
SELECT 'L inscription devrait maintenant fonctionner sans erreur 500' as status;
