-- =====================================================
-- TRIGGER POUR AJOUT AUTOMATIQUE DES NOUVEAUX UTILISATEURS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Ce trigger ajoute automatiquement les nouveaux utilisateurs à subscription_status
-- pour qu'ils apparaissent immédiatement dans la page admin

-- =====================================================
-- ÉTAPE 1: CRÉATION DE LA FONCTION
-- =====================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insérer le nouvel utilisateur dans subscription_status
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    activated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
    NEW.email,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN true
      ELSE false
    END,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
      ELSE 'free'
    END,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'Administrateur - accès complet'
      ELSE 'Nouveau compte - en attente d''activation'
    END,
    CASE 
      WHEN NEW.email_confirmed_at IS NOT NULL THEN NEW.email_confirmed_at
      ELSE NULL
    END
  );
  
  -- Log de l'action
  RAISE NOTICE 'Nouvel utilisateur ajouté automatiquement: % (%)', NEW.email, NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 2: CRÉATION DU TRIGGER
-- =====================================================

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Créer le trigger sur la table auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 3: SYNCHRONISATION DES UTILISATEURS EXISTANTS
-- =====================================================

-- Ajouter les utilisateurs existants qui ne sont pas dans subscription_status
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
    ELSE 'Compte existant - synchronisé automatiquement'
  END as notes,
  COALESCE(u.email_confirmed_at, NOW()) as activated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
);

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION
-- =====================================================

-- Vérifier que le trigger a été créé
SELECT 
  'Trigger créé' as info,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Compter les utilisateurs synchronisés
SELECT 
  'Synchronisation terminée' as info,
  COUNT(*) as total_users_in_auth,
  (SELECT COUNT(*) FROM subscription_status) as total_users_in_subscription
FROM auth.users;

-- =====================================================
-- ÉTAPE 5: RAPPORT FINAL
-- =====================================================

SELECT 
  'Configuration terminée' as status,
  'Les nouveaux utilisateurs seront automatiquement ajoutés à la page admin' as message;
