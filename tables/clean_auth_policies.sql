-- Script de nettoyage des politiques d'authentification
-- Exécutez ce script AVANT d'exécuter setup_auth_tables.sql

-- Supprimer toutes les politiques existantes sur la table users
DROP POLICY IF EXISTS "Users can view all users" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Only admins can create users" ON public.users;
DROP POLICY IF EXISTS "Only admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.users;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON public.users;

-- Supprimer toutes les politiques existantes sur la table user_profiles
DROP POLICY IF EXISTS "Users can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.user_profiles;

-- Supprimer toutes les politiques existantes sur la table user_preferences
DROP POLICY IF EXISTS "Users can view own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can create own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.user_preferences;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.user_preferences;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.user_preferences;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.user_preferences;

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON public.user_preferences;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Supprimer les fonctions existantes (sauf update_updated_at_column qui est utilisée par d'autres tables)
DROP FUNCTION IF EXISTS public.handle_new_user();
-- Ne pas supprimer update_updated_at_column() car elle est utilisée par d'autres tables
-- DROP FUNCTION IF EXISTS public.update_updated_at_column();

-- Vérification du nettoyage
SELECT 'Nettoyage terminé' as status;
