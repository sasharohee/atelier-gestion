-- Correction complète des triggers avec suppression en cascade
-- Supprime tous les triggers dépendants de set_workshop_context()

-- 1. Supprimer tous les triggers qui dépendent de set_workshop_context()
DROP TRIGGER IF EXISTS trigger_set_workshop_context_performance_metrics ON performance_metrics;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_reports ON reports;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_advanced_alerts ON advanced_alerts;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_technician_performance ON technician_performance;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_transactions ON transactions;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_activity_logs ON activity_logs;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_advanced_settings ON advanced_settings;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_products ON products;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_user_profiles ON user_profiles;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_user_preferences ON user_preferences;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_repairs ON repairs;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_clients ON clients;
DROP TRIGGER IF EXISTS trigger_set_workshop_context_devices ON devices;
DROP TRIGGER IF EXISTS set_client_context ON clients;
DROP TRIGGER IF EXISTS set_appointment_context ON appointments;
DROP TRIGGER IF EXISTS set_product_context ON products;
DROP TRIGGER IF EXISTS set_sale_context ON sales;
DROP TRIGGER IF EXISTS set_workshop_context_trigger ON users;

-- 2. Supprimer la fonction set_workshop_context()
DROP FUNCTION IF EXISTS set_workshop_context();

-- 3. Supprimer le trigger create_user_profile_trigger pour le recréer proprement
DROP TRIGGER IF EXISTS create_user_profile_trigger ON users;
DROP FUNCTION IF EXISTS create_user_profile_trigger();

-- 4. Recréer la fonction set_workshop_context() corrigée (sans référence à created_by)
CREATE OR REPLACE FUNCTION set_workshop_context()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Récupérer l'ID de l'utilisateur connecté
  v_user_id := auth.uid();
  
  -- Si pas d'utilisateur connecté, utiliser une valeur par défaut
  IF v_user_id IS NULL THEN
    v_user_id := '00000000-0000-0000-0000-000000000000'::UUID;
  END IF;
  
  -- Définir le contexte de l'atelier (sans created_by)
  PERFORM set_config('app.current_user_id', v_user_id::text, false);
  
  RETURN NEW;
END;
$$;

-- 5. Recréer le trigger simplifié pour la création de profils
CREATE OR REPLACE FUNCTION create_user_profile_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Créer automatiquement un profil utilisateur
  INSERT INTO user_profiles (user_id, first_name, last_name, email, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.first_name,
    NEW.last_name,
    NEW.email,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- Créer automatiquement des préférences utilisateur par défaut
  INSERT INTO user_preferences (user_id, created_at, updated_at)
  VALUES (
    NEW.id,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- 6. Attacher le trigger à la table users
CREATE TRIGGER create_user_profile_trigger
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile_trigger();

-- 7. Recréer les triggers essentiels avec la fonction corrigée
CREATE TRIGGER set_workshop_context_trigger
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER set_workshop_context_clients
  BEFORE INSERT OR UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER set_workshop_context_devices
  BEFORE INSERT OR UPDATE ON devices
  FOR EACH ROW
  EXECUTE FUNCTION set_workshop_context();

CREATE TRIGGER set_workshop_context_repairs
  BEFORE INSERT OR UPDATE ON repairs
  FOR EACH ROW
  EXECUTE FUNCTION set_workshop_context();

-- 8. Vérifier que les triggers sont bien créés
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table IN ('users', 'clients', 'devices', 'repairs')
ORDER BY event_object_table, trigger_name;

-- 9. Tester la fonction RPC
SELECT 'Test de la fonction RPC' as test,
       create_user_automatically(
         gen_random_uuid(),
         'Test',
         'Cascade',
         'test.cascade@example.com',
         'technician'
       ) as result;

-- 10. Nettoyer le test
DELETE FROM users WHERE email = 'test.cascade@example.com';

SELECT 'Correction complète des triggers terminée.' as status;
