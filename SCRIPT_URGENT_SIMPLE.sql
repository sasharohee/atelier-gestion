-- SCRIPT URGENT SIMPLE - Copiez et collez ceci dans Supabase SQL Editor
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
SELECT 'Trigger supprimé - Inscription fonctionne maintenant' as status;
