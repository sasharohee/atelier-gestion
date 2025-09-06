-- Vérification que l'utilisateur a été créé avec succès
-- Exécuter ce script pour confirmer que le problème est résolu

-- 1. Vérifier que l'utilisateur existe maintenant
SELECT 
  id,
  first_name,
  last_name,
  email,
  role,
  created_at,
  updated_at
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 2. Vérifier le nombre total d'utilisateurs
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_users,
  COUNT(CASE WHEN role = 'user' THEN 1 END) as regular_users
FROM public.users;

-- 3. Lister tous les utilisateurs pour vérification
SELECT 
  id,
  first_name,
  last_name,
  email,
  role,
  created_at
FROM public.users 
ORDER BY created_at DESC;

-- 4. Vérifier que l'utilisateur peut accéder à ses données
-- (Test d'isolation des données)
SELECT 
  'clients' as table_name,
  COUNT(*) as count
FROM clients 
WHERE user_id = '14577c87-1336-476b-9747-aa16f8413bfe'
UNION ALL
SELECT 
  'devices' as table_name,
  COUNT(*) as count
FROM devices 
WHERE user_id = '14577c87-1336-476b-9747-aa16f8413bfe'
UNION ALL
SELECT 
  'system_settings' as table_name,
  COUNT(*) as count
FROM system_settings 
WHERE user_id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 5. Message de confirmation
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.users WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe'
  ) THEN
    RAISE NOTICE '✅ SUCCÈS : L''utilisateur 14577c87-1336-476b-9747-aa16f8413bfe a été créé avec succès';
    RAISE NOTICE '✅ Les boucles infinies de requêtes devraient maintenant être résolues';
    RAISE NOTICE '✅ Votre application devrait fonctionner normalement';
  ELSE
    RAISE NOTICE '❌ ERREUR : L''utilisateur n''existe toujours pas';
  END IF;
END $$;
