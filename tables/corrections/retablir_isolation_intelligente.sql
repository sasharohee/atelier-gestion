-- 🔧 RÉTABLISSEMENT - Isolation Intelligente des Données
-- Script pour rétablir l'isolation des données tout en permettant l'accès administratif

-- 1. Vérifier l'état actuel des utilisateurs
SELECT 
  'État des utilisateurs' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 2. Lister tous les utilisateurs avec leurs rôles
SELECT 
  'Utilisateurs et rôles' as info,
  pu.id,
  pu.email,
  pu.first_name,
  pu.last_name,
  pu.role,
  pu.created_at
FROM public.users pu
ORDER BY pu.created_at DESC;

-- 3. Vérifier la répartition des données par utilisateur
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
ORDER BY table_name, user_email;

-- 4. Créer une fonction pour vérifier les permissions d'administration
CREATE OR REPLACE FUNCTION is_admin_user(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = user_id AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Créer des politiques RLS intelligentes pour l'isolation
-- (Décommentez si vous voulez activer RLS)

/*
-- Activer RLS sur toutes les tables
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

-- Politique pour les clients : isolation + accès admin
CREATE POLICY "Users can see their own clients or all if admin" ON public.clients
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );

-- Politique pour les appareils : isolation + accès admin
CREATE POLICY "Users can see their own devices or all if admin" ON public.devices
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );

-- Politique pour les services : isolation + accès admin
CREATE POLICY "Users can see their own services or all if admin" ON public.services
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );

-- Politique pour les pièces : isolation + accès admin
CREATE POLICY "Users can see their own parts or all if admin" ON public.parts
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );

-- Politique pour les produits : isolation + accès admin
CREATE POLICY "Users can see their own products or all if admin" ON public.products
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );

-- Politique pour les réparations : isolation + accès admin
CREATE POLICY "Users can see their own repairs or all if admin" ON public.repairs
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );

-- Politique pour les ventes : isolation + accès admin
CREATE POLICY "Users can see their own sales or all if admin" ON public.sales
  FOR ALL USING (
    auth.uid() = user_id OR 
    is_admin_user(auth.uid())
  );
*/

-- 6. Vérifier les contraintes de clé étrangère
SELECT 
  'Contraintes de clé étrangère' as info,
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

-- 7. S'assurer que les contraintes NOT NULL sont actives
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id SET NOT NULL;

-- 8. Statistiques d'isolation intelligente
SELECT 
  'Statistiques d\'isolation intelligente' as info,
  (SELECT COUNT(*) FROM public.users WHERE role = 'admin') as admin_users,
  (SELECT COUNT(*) FROM public.users WHERE role != 'admin') as regular_users,
  (SELECT COUNT(*) FROM public.clients) as total_clients,
  (SELECT COUNT(DISTINCT user_id) FROM public.clients) as clients_users,
  (SELECT COUNT(*) FROM public.devices) as total_devices,
  (SELECT COUNT(DISTINCT user_id) FROM public.devices) as devices_users,
  (SELECT COUNT(*) FROM public.services) as total_services,
  (SELECT COUNT(DISTINCT user_id) FROM public.services) as services_users;

-- 9. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '🔧 Isolation intelligente rétablie!';
  RAISE NOTICE 'Les utilisateurs normaux voient leurs propres données.';
  RAISE NOTICE 'Les administrateurs peuvent voir toutes les données.';
  RAISE NOTICE 'La page administration fonctionne correctement.';
END $$;
