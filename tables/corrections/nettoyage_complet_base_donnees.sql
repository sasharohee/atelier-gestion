-- Nettoyage complet de la base de données
-- Date: 2024-01-24

-- 1. SUPPRIMER TOUS LES TRIGGERS

SELECT '=== SUPPRESSION DE TOUS LES TRIGGERS ===' as section;

-- Supprimer tous les triggers sur auth.users
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' 
        AND trigger_schema = 'auth'
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_record.trigger_name || ' ON auth.users CASCADE';
        RAISE NOTICE 'Trigger supprimé: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 2. SUPPRIMER TOUTES LES TABLES UTILISATEURS

SELECT '=== SUPPRESSION DES TABLES UTILISATEURS ===' as section;

DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS simple_auth CASCADE;
DROP TABLE IF EXISTS pending_signups CASCADE;
DROP TABLE IF EXISTS confirmation_emails CASCADE;
DROP TABLE IF EXISTS subscription_status CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;

-- 3. SUPPRIMER TOUTES LES FONCTIONS

SELECT '=== SUPPRESSION DES FONCTIONS ===' as section;

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
DROP FUNCTION IF EXISTS list_pending_emails_for_admin() CASCADE;
DROP FUNCTION IF EXISTS send_manual_confirmation_email(TEXT) CASCADE;
DROP FUNCTION IF EXISTS display_pending_emails() CASCADE;
DROP FUNCTION IF EXISTS display_email_content(TEXT) CASCADE;
DROP FUNCTION IF EXISTS cleanup_expired_emails() CASCADE;
DROP FUNCTION IF EXISTS regenerate_expired_email(TEXT) CASCADE;
DROP FUNCTION IF EXISTS simple_login(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS process_pending_signup(TEXT) CASCADE;
DROP FUNCTION IF EXISTS approve_pending_signup(TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_signup_status(TEXT) CASCADE;
DROP FUNCTION IF EXISTS list_pending_signups() CASCADE;

-- 4. SUPPRIMER LES TABLES DE DONNÉES

SELECT '=== SUPPRESSION DES TABLES DE DONNÉES ===' as section;

-- Tables de produits et catalogue
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;

-- Tables de clients et appareils
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS device_models CASCADE;

-- Tables de réparations
DROP TABLE IF EXISTS repairs CASCADE;
DROP TABLE IF EXISTS repair_status CASCADE;

-- Tables de ventes
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS sale_items CASCADE;

-- Tables de rendez-vous
DROP TABLE IF EXISTS appointments CASCADE;

-- Tables de messages
DROP TABLE IF EXISTS messages CASCADE;

-- Tables de kanban
DROP TABLE IF EXISTS kanban_boards CASCADE;
DROP TABLE IF EXISTS kanban_lists CASCADE;
DROP TABLE IF EXISTS kanban_cards CASCADE;

-- Tables de statistiques
DROP TABLE IF EXISTS statistics CASCADE;

-- Tables de transactions
DROP TABLE IF EXISTS transactions CASCADE;

-- 5. SUPPRIMER LES EXTENSIONS SI NÉCESSAIRE

SELECT '=== VÉRIFICATION DES EXTENSIONS ===' as section;

-- Désactiver pg_mail si installé
DROP EXTENSION IF EXISTS pg_mail CASCADE;

-- 6. NETTOYER LES SÉQUENCES

SELECT '=== NETTOYAGE DES SÉQUENCES ===' as section;

-- Réinitialiser toutes les séquences
DO $$
DECLARE
    seq_record RECORD;
BEGIN
    FOR seq_record IN 
        SELECT sequence_name 
        FROM information_schema.sequences 
        WHERE sequence_schema = 'public'
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || seq_record.sequence_name || ' RESTART WITH 1';
        RAISE NOTICE 'Séquence réinitialisée: %', seq_record.sequence_name;
    END LOOP;
END $$;

-- 7. VÉRIFIER LE NETTOYAGE

SELECT '=== VÉRIFICATION DU NETTOYAGE ===' as section;

-- Lister les tables restantes
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Lister les fonctions restantes
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Lister les triggers restants
SELECT 
    trigger_name,
    event_object_table,
    trigger_schema
FROM information_schema.triggers 
WHERE trigger_schema IN ('public', 'auth')
ORDER BY trigger_schema, trigger_name;

-- 8. MESSAGE DE CONFIRMATION

SELECT '=== NETTOYAGE TERMINÉ ===' as section;
SELECT 
    '✅ Tous les triggers supprimés' as statut1,
    '✅ Toutes les tables utilisateur supprimées' as statut2,
    '✅ Toutes les fonctions supprimées' as statut3,
    '✅ Toutes les tables de données supprimées' as statut4,
    '✅ Séquences réinitialisées' as statut5,
    '✅ Base de données complètement nettoyée' as statut6,
    '✅ Prêt pour un nouveau départ' as statut7;

-- 9. INSTRUCTIONS POUR LE REDÉMARRAGE

SELECT '=== INSTRUCTIONS POUR LE REDÉMARRAGE ===' as section;
SELECT 
    '1. La base de données est complètement nettoyée' as etape1,
    '2. Vous pouvez maintenant créer un nouvel utilisateur dans Supabase Auth' as etape2,
    '3. Aucun trigger ne devrait interférer' as etape3,
    '4. Prêt pour une nouvelle installation' as etape4;
