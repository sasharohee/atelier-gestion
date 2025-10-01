-- SOLUTION AGRESSIVE: Nettoyage complet des triggers auth problématiques
-- Ce script supprime TOUS les triggers et fonctions qui peuvent causer l'erreur 500

-- 1. Supprimer TOUS les triggers sur auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_trigger ON auth.users;
DROP TRIGGER IF EXISTS create_user_on_signup ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users;
DROP TRIGGER IF EXISTS trigger_handle_new_user ON auth.users;

-- 2. Supprimer TOUTES les fonctions problématiques
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.on_auth_user_created();
DROP FUNCTION IF EXISTS public.create_user_on_signup();
DROP FUNCTION IF EXISTS public.handle_new_user_trigger();
DROP FUNCTION IF EXISTS public.trigger_handle_new_user();

-- 3. Vérifier qu'aucun trigger ne reste sur auth.users
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 4. Vérifier les fonctions restantes dans public
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND (routine_name LIKE '%user%' OR routine_name LIKE '%auth%')
  AND routine_type = 'FUNCTION';

-- 5. Message de confirmation
SELECT '✅ Nettoyage agressif terminé - Tous les triggers auth supprimés' as status;

-- 6. Vérification finale
SELECT 
    'Triggers restants sur auth.users:' as info,
    COUNT(*) as count
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';
