-- =====================================================
-- CRÉATION TRIGGER SÉPARÉE - SIMPLE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:20:00.000Z

-- Script séparé pour créer le trigger sans erreur

-- =====================================================
-- ÉTAPE 1: SUPPRESSION
-- =====================================================

-- Supprimer le trigger et la fonction s'ils existent
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- ÉTAPE 2: CRÉATION FONCTION
-- =====================================================

-- Créer la fonction
CREATE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
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
-- ÉTAPE 3: CRÉATION TRIGGER
-- =====================================================

-- Créer le trigger
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
-- ÉTAPE 5: RAPPORT
-- =====================================================

SELECT 
  'Trigger configuré' as status,
  'Les nouveaux utilisateurs seront ajoutés automatiquement' as message;
