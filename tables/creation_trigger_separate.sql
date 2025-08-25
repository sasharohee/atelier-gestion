-- =====================================================
-- CRÉATION DU TRIGGER POUR NOUVEAUX UTILISATEURS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Script séparé pour créer le trigger sans erreur de syntaxe

-- =====================================================
-- ÉTAPE 1: SUPPRESSION DU TRIGGER EXISTANT
-- =====================================================

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Supprimer la fonction s'il existe déjà
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- ÉTAPE 2: CRÉATION DE LA FONCTION
-- =====================================================

-- Créer la fonction pour gérer les nouveaux utilisateurs
CREATE FUNCTION handle_new_user()
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
    false,
    'free',
    'Nouveau compte - en attente d''activation',
    NULL
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 3: CRÉATION DU TRIGGER
-- =====================================================

-- Créer le trigger sur la table auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

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

-- =====================================================
-- ÉTAPE 5: RAPPORT FINAL
-- =====================================================

SELECT 
  'Trigger configuré' as status,
  'Les nouveaux utilisateurs seront automatiquement ajoutés à subscription_status' as message;
