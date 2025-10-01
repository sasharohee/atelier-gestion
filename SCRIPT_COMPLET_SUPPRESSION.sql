-- SCRIPT COMPLET POUR SUPPRIMER TOUS LES TRIGGERS PROBLÉMATIQUES
-- Ce script supprime tous les triggers possibles sur auth.users

-- 1. Supprimer tous les triggers possibles sur auth.users
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_insert ON auth.users;
DROP TRIGGER IF EXISTS handle_new_auth_user ON auth.users;
DROP TRIGGER IF EXISTS create_user_profile ON auth.users;
DROP TRIGGER IF EXISTS create_user_on_signup ON auth.users;

-- 2. Supprimer toutes les fonctions possibles
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.on_auth_user_created();
DROP FUNCTION IF EXISTS public.on_auth_user_insert();
DROP FUNCTION IF EXISTS public.handle_new_auth_user();
DROP FUNCTION IF EXISTS public.create_user_profile();
DROP FUNCTION IF EXISTS public.create_user_on_signup();

-- 3. Vérifier qu'aucun trigger n'existe sur auth.users
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 4. Message de confirmation
SELECT 'Tous les triggers supprimés - Inscription devrait fonctionner' as status;
