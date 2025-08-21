-- 🔧 CORRECTION - Isolation des Données par Utilisateur
-- Script pour rétablir l'isolation des données entre les utilisateurs

-- 1. Vérifier l'état actuel des contraintes
SELECT 
  tc.table_name,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON rc.unique_constraint_name = ccu.constraint_name
  AND rc.unique_constraint_schema = ccu.table_schema
WHERE tc.table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
  AND kcu.column_name = 'user_id'
ORDER BY tc.table_name;

-- 2. Rétablir les contraintes NOT NULL pour user_id
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id SET NOT NULL;

-- 3. Rétablir les contraintes de clé étrangère vers la table users
-- (Assurez-vous que la table users existe et a la bonne structure)

-- Clients
ALTER TABLE public.clients 
ADD CONSTRAINT clients_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Devices
ALTER TABLE public.devices 
ADD CONSTRAINT devices_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Services
ALTER TABLE public.services 
ADD CONSTRAINT services_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Parts
ALTER TABLE public.parts 
ADD CONSTRAINT parts_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Products
ALTER TABLE public.products 
ADD CONSTRAINT products_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Repairs
ALTER TABLE public.repairs 
ADD CONSTRAINT repairs_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Sales
ALTER TABLE public.sales 
ADD CONSTRAINT sales_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- 4. Nettoyer les données orphelines (optionnel)
-- Supprimer les enregistrements sans user_id valide
DELETE FROM public.clients WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.devices WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.services WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.parts WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.products WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.repairs WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
DELETE FROM public.sales WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);

-- 5. Vérifier la structure finale
SELECT 
  table_name,
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns 
WHERE table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
  AND column_name = 'user_id'
ORDER BY table_name;

-- 6. Vérifier les contraintes finales
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

-- 7. Statistiques d'isolation
SELECT 
  'clients' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.clients
UNION ALL
SELECT 
  'devices' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.devices
UNION ALL
SELECT 
  'services' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.services
UNION ALL
SELECT 
  'parts' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.parts
UNION ALL
SELECT 
  'products' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.products
UNION ALL
SELECT 
  'repairs' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.repairs
UNION ALL
SELECT 
  'sales' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users
FROM public.sales;

-- 8. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ Isolation des données rétablie!';
  RAISE NOTICE 'Les données sont maintenant isolées par utilisateur.';
  RAISE NOTICE 'Chaque utilisateur ne voit que ses propres données.';
END $$;
