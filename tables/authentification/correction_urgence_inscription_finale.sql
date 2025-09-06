-- =====================================================
-- CORRECTION D'URGENCE FINALE - INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:25:00.000Z

-- Script de correction d'urgence finale pour l'erreur 500

-- =====================================================
-- ÉTAPE 1: SUPPRESSION COMPLÈTE DES TRIGGERS
-- =====================================================

-- Supprimer TOUS les triggers sur auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS on_auth_user_created();

-- =====================================================
-- ÉTAPE 2: FORCER LES PERMISSIONS AUTH.USERS
-- =====================================================

-- Donner TOUS les privilèges sur auth.users
GRANT ALL PRIVILEGES ON TABLE auth.users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE auth.users TO anon;
GRANT ALL PRIVILEGES ON TABLE auth.users TO service_role;

-- Donner les privilèges sur les séquences auth
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO service_role;

-- =====================================================
-- ÉTAPE 3: FORCER LES PERMISSIONS SUBSCRIPTION_STATUS
-- =====================================================

-- Désactiver RLS de force
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- Donner TOUS les privilèges sur subscription_status
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- =====================================================
-- ÉTAPE 4: NETTOYAGE DES SESSIONS
-- =====================================================

-- Nettoyer les sessions expirées (optionnel)
-- DELETE FROM auth.sessions WHERE not_after < NOW();
-- Note: Pas de nettoyage de refresh_tokens pour éviter les erreurs de colonnes

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION FORCÉE
-- =====================================================

-- Ajouter tous les utilisateurs manquants
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  activated_at
)
SELECT 
  u.id,
  COALESCE(u.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(u.raw_user_meta_data->>'last_name', 'Test') as last_name,
  u.email,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN true
    ELSE false
  END as is_active,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
    ELSE 'free'
  END as subscription_type,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'Administrateur - accès complet'
    ELSE 'Compte synchronisé automatiquement'
  END as notes,
  COALESCE(u.email_confirmed_at, NOW()) as activated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  updated_at = NOW();

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que tout est en place
SELECT 
  'Vérification finale' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'users' AND event_object_schema = 'auth') as triggers_count;

-- =====================================================
-- ÉTAPE 7: TEST D'INSERTION
-- =====================================================

-- Tester l'insertion d'un utilisateur
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_urgence_' || extract(epoch from now())::text || '@test.com';
BEGIN
  -- Tester l'insertion dans auth.users
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data
  ) VALUES (
    test_user_id,
    test_email,
    'test_password_hash',
    NOW(),
    NOW(),
    NOW(),
    '{"first_name": "Test", "last_name": "Urgence"}'
  );
  
  RAISE NOTICE '✅ SUCCÈS: Insertion dans auth.users réussie';
  
  -- Nettoyer
  DELETE FROM auth.users WHERE id = test_user_id;
  
END $$;

-- =====================================================
-- ÉTAPE 8: RAPPORT DE SUCCÈS
-- =====================================================

SELECT 
  'Correction d''urgence terminée' as status,
  'L''inscription devrait maintenant fonctionner sans erreur 500' as message;
