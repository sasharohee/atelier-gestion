-- Commande ultra-rapide de nettoyage
-- Date: 2024-01-24

-- NETTOYAGE COMPLET EN UNE SEULE COMMANDE

-- Supprimer tous les triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users CASCADE;
DROP TRIGGER IF EXISTS create_user_default_data_trigger ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users CASCADE;

-- Supprimer toutes les tables
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS simple_auth CASCADE;
DROP TABLE IF EXISTS pending_signups CASCADE;
DROP TABLE IF EXISTS confirmation_emails CASCADE;
DROP TABLE IF EXISTS subscription_status CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS repairs CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS kanban_boards CASCADE;
DROP TABLE IF EXISTS kanban_lists CASCADE;
DROP TABLE IF EXISTS kanban_cards CASCADE;
DROP TABLE IF EXISTS statistics CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;

-- Supprimer toutes les fonctions
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data_permissive() CASCADE;
DROP FUNCTION IF EXISTS generate_confirmation_token(TEXT) CASCADE;
DROP FUNCTION IF EXISTS generate_confirmation_token_and_send_email(TEXT) CASCADE;
DROP FUNCTION IF EXISTS validate_confirmation_token(TEXT) CASCADE;
DROP FUNCTION IF EXISTS mark_email_sent(TEXT) CASCADE;
DROP FUNCTION IF EXISTS resend_confirmation_email(TEXT) CASCADE;
DROP FUNCTION IF EXISTS resend_confirmation_email_real(TEXT) CASCADE;
DROP FUNCTION IF EXISTS send_confirmation_email_real(TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS list_pending_emails() CASCADE;
DROP FUNCTION IF EXISTS simple_login(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS process_pending_signup(TEXT) CASCADE;
DROP FUNCTION IF EXISTS approve_pending_signup(TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_signup_status(TEXT) CASCADE;
DROP FUNCTION IF EXISTS list_pending_signups() CASCADE;

-- Message de confirmation
SELECT '✅ BASE DE DONNÉES COMPLÈTEMENT NETTOYÉE' as result;
SELECT 'Vous pouvez maintenant créer un nouvel utilisateur dans Supabase Auth sans erreur.' as instruction;
