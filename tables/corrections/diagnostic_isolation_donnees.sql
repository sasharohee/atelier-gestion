-- 🔍 DIAGNOSTIC - Isolation des Données
-- Script pour diagnostiquer et corriger le problème d'isolation des données

-- 1. Vérifier les utilisateurs et leurs rôles
SELECT 
  'Utilisateurs et rôles' as info,
  id,
  email,
  first_name,
  last_name,
  role,
  created_at
FROM public.users 
ORDER BY created_at DESC;

-- 2. Vérifier la répartition des données par utilisateur
SELECT 
  'Répartition des données par utilisateur' as info,
  'clients' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(c.id) as record_count
FROM public.users pu
LEFT JOIN public.clients c ON pu.id = c.user_id
GROUP BY pu.id, pu.email, pu.role
UNION ALL
SELECT 
  'Répartition des données par utilisateur' as info,
  'devices' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(d.id) as record_count
FROM public.users pu
LEFT JOIN public.devices d ON pu.id = d.user_id
GROUP BY pu.id, pu.email, pu.role
UNION ALL
SELECT 
  'Répartition des données par utilisateur' as info,
  'services' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(s.id) as record_count
FROM public.users pu
LEFT JOIN public.services s ON pu.id = s.user_id
GROUP BY pu.id, pu.email, pu.role
UNION ALL
SELECT 
  'Répartition des données par utilisateur' as info,
  'parts' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(p.id) as record_count
FROM public.users pu
LEFT JOIN public.parts p ON pu.id = p.user_id
GROUP BY pu.id, pu.email, pu.role
UNION ALL
SELECT 
  'Répartition des données par utilisateur' as info,
  'products' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(pr.id) as record_count
FROM public.users pu
LEFT JOIN public.products pr ON pu.id = pr.user_id
GROUP BY pu.id, pu.email, pu.role
UNION ALL
SELECT 
  'Répartition des données par utilisateur' as info,
  'repairs' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(r.id) as record_count
FROM public.users pu
LEFT JOIN public.repairs r ON pu.id = r.user_id
GROUP BY pu.id, pu.email, pu.role
UNION ALL
SELECT 
  'Répartition des données par utilisateur' as info,
  'sales' as table_name,
  pu.email as user_email,
  pu.role as user_role,
  COUNT(sa.id) as record_count
FROM public.users pu
LEFT JOIN public.sales sa ON pu.id = sa.user_id
GROUP BY pu.id, pu.email, pu.role
ORDER BY table_name, user_email;

-- 3. Identifier les données sans user_id (orphelines)
SELECT 
  'Données orphelines (sans user_id)' as info,
  'clients' as table_name,
  COUNT(*) as orphan_count
FROM public.clients 
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Données orphelines (sans user_id)' as info,
  'devices' as table_name,
  COUNT(*) as orphan_count
FROM public.devices 
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Données orphelines (sans user_id)' as info,
  'services' as table_name,
  COUNT(*) as orphan_count
FROM public.services 
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Données orphelines (sans user_id)' as info,
  'parts' as table_name,
  COUNT(*) as orphan_count
FROM public.parts 
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Données orphelines (sans user_id)' as info,
  'products' as table_name,
  COUNT(*) as orphan_count
FROM public.products 
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Données orphelines (sans user_id)' as info,
  'repairs' as table_name,
  COUNT(*) as orphan_count
FROM public.repairs 
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Données orphelines (sans user_id)' as info,
  'sales' as table_name,
  COUNT(*) as orphan_count
FROM public.sales 
WHERE user_id IS NULL
ORDER BY table_name;

-- 4. Identifier les données avec user_id invalide
SELECT 
  'Données avec user_id invalide' as info,
  'clients' as table_name,
  COUNT(*) as invalid_count
FROM public.clients 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données avec user_id invalide' as info,
  'devices' as table_name,
  COUNT(*) as invalid_count
FROM public.devices 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données avec user_id invalide' as info,
  'services' as table_name,
  COUNT(*) as invalid_count
FROM public.services 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données avec user_id invalide' as info,
  'parts' as table_name,
  COUNT(*) as invalid_count
FROM public.parts 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données avec user_id invalide' as info,
  'products' as table_name,
  COUNT(*) as invalid_count
FROM public.products 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données avec user_id invalide' as info,
  'repairs' as table_name,
  COUNT(*) as invalid_count
FROM public.repairs 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données avec user_id invalide' as info,
  'sales' as table_name,
  COUNT(*) as invalid_count
FROM public.sales 
WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM public.users)
ORDER BY table_name;

-- 5. Nettoyer les données orphelines et invalides (optionnel)
-- Décommentez si vous voulez nettoyer automatiquement
/*
DELETE FROM public.clients WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.devices WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.services WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.parts WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.products WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.repairs WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.sales WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
*/

-- 6. Assigner les données orphelines à un utilisateur admin (optionnel)
-- Décommentez si vous voulez assigner les données orphelines à un admin
/*
UPDATE public.clients 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;

UPDATE public.devices 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;

UPDATE public.services 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;

UPDATE public.parts 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;

UPDATE public.products 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;

UPDATE public.repairs 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;

UPDATE public.sales 
SET user_id = (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1)
WHERE user_id IS NULL;
*/

-- 7. Vérifier les contraintes NOT NULL
SELECT 
  'Contraintes NOT NULL' as info,
  table_name,
  column_name,
  is_nullable
FROM information_schema.columns 
WHERE table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
  AND column_name = 'user_id'
ORDER BY table_name;

-- 8. S'assurer que les contraintes NOT NULL sont actives
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id SET NOT NULL;

-- 9. Statistiques finales
SELECT 
  'Statistiques finales' as info,
  (SELECT COUNT(*) FROM public.users WHERE role = 'admin') as admin_users,
  (SELECT COUNT(*) FROM public.users WHERE role != 'admin') as regular_users,
  (SELECT COUNT(*) FROM public.clients) as total_clients,
  (SELECT COUNT(DISTINCT user_id) FROM public.clients) as clients_users,
  (SELECT COUNT(*) FROM public.devices) as total_devices,
  (SELECT COUNT(DISTINCT user_id) FROM public.devices) as devices_users,
  (SELECT COUNT(*) FROM public.services) as total_services,
  (SELECT COUNT(DISTINCT user_id) FROM public.services) as services_users;

-- 10. Message de diagnostic
DO $$
BEGIN
  RAISE NOTICE '🔍 Diagnostic terminé!';
  RAISE NOTICE 'Vérifiez les résultats ci-dessus pour identifier les problèmes d''isolation.';
  RAISE NOTICE 'Si des données sont orphelines, elles peuvent être nettoyées ou assignées.';
END $$;
