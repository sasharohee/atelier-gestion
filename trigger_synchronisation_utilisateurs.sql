-- Trigger pour synchroniser automatiquement les nouveaux utilisateurs
-- Ce trigger crée automatiquement un enregistrement dans public.users quand un utilisateur s'inscrit

-- 1. Créer la fonction de synchronisation
CREATE OR REPLACE FUNCTION sync_user_to_public()
RETURNS TRIGGER AS $$
BEGIN
  -- Insérer l'utilisateur dans public.users s'il n'existe pas déjà
  INSERT INTO public.users (
    id,
    first_name,
    last_name,
    email,
    role,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
    NEW.email,
    'admin',
    NEW.created_at,
    NEW.updated_at
  ) ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Créer le trigger
DROP TRIGGER IF EXISTS sync_user_trigger ON auth.users;
CREATE TRIGGER sync_user_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_public();

-- 3. Vérifier que le trigger a été créé
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'sync_user_trigger';

-- 4. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ Trigger de synchronisation créé avec succès';
  RAISE NOTICE '✅ Les nouveaux utilisateurs seront automatiquement synchronisés';
  RAISE NOTICE '✅ Plus de problèmes d''utilisateurs manquants à l''avenir';
END $$;
