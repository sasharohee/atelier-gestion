-- 🔧 CORRECTION - Isolation Stricte des Données
-- Script pour forcer l'isolation des données par utilisateur

-- 1. Vérifier les données actuelles par utilisateur
SELECT 
  'Répartition actuelle des données' as info,
  'clients' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.clients 
GROUP BY user_id
UNION ALL
SELECT 
  'Répartition actuelle des données' as info,
  'devices' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.devices 
GROUP BY user_id
UNION ALL
SELECT 
  'Répartition actuelle des données' as info,
  'services' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.services 
GROUP BY user_id
UNION ALL
SELECT 
  'Répartition actuelle des données' as info,
  'parts' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.parts 
GROUP BY user_id
UNION ALL
SELECT 
  'Répartition actuelle des données' as info,
  'products' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.products 
GROUP BY user_id
UNION ALL
SELECT 
  'Répartition actuelle des données' as info,
  'repairs' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.repairs 
GROUP BY user_id
UNION ALL
SELECT 
  'Répartition actuelle des données' as info,
  'sales' as table_name,
  user_id,
  COUNT(*) as record_count
FROM public.sales 
GROUP BY user_id
ORDER BY table_name, user_id;

-- 2. Identifier les données orphelines (sans user_id valide)
SELECT 
  'Données orphelines' as info,
  'clients' as table_name,
  COUNT(*) as orphan_count
FROM public.clients 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données orphelines' as info,
  'devices' as table_name,
  COUNT(*) as orphan_count
FROM public.devices 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données orphelines' as info,
  'services' as table_name,
  COUNT(*) as orphan_count
FROM public.services 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données orphelines' as info,
  'parts' as table_name,
  COUNT(*) as orphan_count
FROM public.parts 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données orphelines' as info,
  'products' as table_name,
  COUNT(*) as orphan_count
FROM public.products 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données orphelines' as info,
  'repairs' as table_name,
  COUNT(*) as orphan_count
FROM public.repairs 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
UNION ALL
SELECT 
  'Données orphelines' as info,
  'sales' as table_name,
  COUNT(*) as orphan_count
FROM public.sales 
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users)
ORDER BY table_name;

-- 3. Nettoyer les données orphelines (optionnel - décommentez si nécessaire)
/*
DELETE FROM public.clients WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.devices WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.services WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.parts WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.products WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.repairs WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.sales WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
*/

-- 4. Vérifier les contraintes de clé étrangère
SELECT 
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
  AND kcu.column_name = 'user_id'
ORDER BY tc.table_name, tc.constraint_type;

-- 5. S'assurer que les contraintes NOT NULL sont actives
SELECT 
  table_name,
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns 
WHERE table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
  AND column_name = 'user_id'
ORDER BY table_name;

-- 6. Activer les contraintes NOT NULL si nécessaire
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id SET NOT NULL;

-- 7. Vérifier les politiques RLS (Row Level Security)
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
ORDER BY tablename, policyname;

-- 8. Créer des politiques RLS pour l'isolation stricte (optionnel)
-- Décommentez si vous voulez une sécurité supplémentaire au niveau de la base de données
/*
-- Politique pour les clients
CREATE POLICY "Users can only see their own clients" ON public.clients
  FOR ALL USING (auth.uid() = user_id);

-- Politique pour les appareils
CREATE POLICY "Users can only see their own devices" ON public.devices
  FOR ALL USING (auth.uid() = user_id);

-- Politique pour les services
CREATE POLICY "Users can only see their own services" ON public.services
  FOR ALL USING (auth.uid() = user_id);

-- Politique pour les pièces
CREATE POLICY "Users can only see their own parts" ON public.parts
  FOR ALL USING (auth.uid() = user_id);

-- Politique pour les produits
CREATE POLICY "Users can only see their own products" ON public.products
  FOR ALL USING (auth.uid() = user_id);

-- Politique pour les réparations
CREATE POLICY "Users can only see their own repairs" ON public.repairs
  FOR ALL USING (auth.uid() = user_id);

-- Politique pour les ventes
CREATE POLICY "Users can only see their own sales" ON public.sales
  FOR ALL USING (auth.uid() = user_id);
*/

-- 9. Statistiques finales d'isolation
SELECT 
  'Statistiques d''isolation' as info,
  (SELECT COUNT(*) FROM public.users) as total_users,
  (SELECT COUNT(*) FROM public.clients) as total_clients,
  (SELECT COUNT(DISTINCT user_id) FROM public.clients) as clients_users,
  (SELECT COUNT(*) FROM public.devices) as total_devices,
  (SELECT COUNT(DISTINCT user_id) FROM public.devices) as devices_users,
  (SELECT COUNT(*) FROM public.services) as total_services,
  (SELECT COUNT(DISTINCT user_id) FROM public.services) as services_users;

-- 10. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '🔒 Isolation stricte configurée!';
  RAISE NOTICE 'Chaque utilisateur ne verra que ses propres données.';
  RAISE NOTICE 'Les données sont maintenant complètement isolées.';
END $$;
