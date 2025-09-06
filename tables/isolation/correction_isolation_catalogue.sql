-- Correction de l'isolation des données dans le catalogue
-- Ce script corrige les politiques RLS pour assurer l'isolation des données

-- 1. Vérifier les politiques RLS actuelles
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
WHERE tablename IN ('devices', 'clients', 'services', 'parts', 'products')
ORDER BY tablename, policyname;

-- 2. Supprimer les anciennes politiques RLS pour les recréer
DROP POLICY IF EXISTS "Users can view own devices" ON devices;
DROP POLICY IF EXISTS "Users can insert own devices" ON devices;
DROP POLICY IF EXISTS "Users can update own devices" ON devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON devices;

DROP POLICY IF EXISTS "Users can view own clients" ON clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON clients;
DROP POLICY IF EXISTS "Users can update own clients" ON clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON clients;

DROP POLICY IF EXISTS "Users can view own services" ON services;
DROP POLICY IF EXISTS "Users can insert own services" ON services;
DROP POLICY IF EXISTS "Users can update own services" ON services;
DROP POLICY IF EXISTS "Users can delete own services" ON services;

DROP POLICY IF EXISTS "Users can view own parts" ON parts;
DROP POLICY IF EXISTS "Users can insert own parts" ON parts;
DROP POLICY IF EXISTS "Users can update own parts" ON parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON parts;

DROP POLICY IF EXISTS "Users can view own products" ON products;
DROP POLICY IF EXISTS "Users can insert own products" ON products;
DROP POLICY IF EXISTS "Users can update own products" ON products;
DROP POLICY IF EXISTS "Users can delete own products" ON products;

-- 3. Activer RLS sur toutes les tables
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 4. Créer les nouvelles politiques RLS pour devices
CREATE POLICY "Users can view own devices" ON devices
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

CREATE POLICY "Users can insert own devices" ON devices
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can update own devices" ON devices
  FOR UPDATE USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can delete own devices" ON devices
  FOR DELETE USING (
    auth.uid() = user_id
  );

-- 5. Créer les nouvelles politiques RLS pour clients
CREATE POLICY "Users can view own clients" ON clients
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

CREATE POLICY "Users can insert own clients" ON clients
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can update own clients" ON clients
  FOR UPDATE USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can delete own clients" ON clients
  FOR DELETE USING (
    auth.uid() = user_id
  );

-- 6. Créer les nouvelles politiques RLS pour services
CREATE POLICY "Users can view own services" ON services
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

CREATE POLICY "Users can insert own services" ON services
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can update own services" ON services
  FOR UPDATE USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can delete own services" ON services
  FOR DELETE USING (
    auth.uid() = user_id
  );

-- 7. Créer les nouvelles politiques RLS pour parts
CREATE POLICY "Users can view own parts" ON parts
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

CREATE POLICY "Users can insert own parts" ON parts
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can update own parts" ON parts
  FOR UPDATE USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can delete own parts" ON parts
  FOR DELETE USING (
    auth.uid() = user_id
  );

-- 8. Créer les nouvelles politiques RLS pour products
CREATE POLICY "Users can view own products" ON products
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

CREATE POLICY "Users can insert own products" ON products
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can update own products" ON products
  FOR UPDATE USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Users can delete own products" ON products
  FOR DELETE USING (
    auth.uid() = user_id
  );

-- 9. Vérifier que les politiques ont été créées
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename IN ('devices', 'clients', 'services', 'parts', 'products')
ORDER BY tablename, policyname;

-- 10. Tester l'isolation avec l'utilisateur actuel
DO $$
DECLARE
  current_user_id UUID;
BEGIN
  -- Récupérer l'utilisateur actuel
  SELECT auth.uid() INTO current_user_id;
  
  IF current_user_id IS NOT NULL THEN
    RAISE NOTICE 'Test d''isolation pour l''utilisateur: %', current_user_id;
    
    -- Compter les données de l'utilisateur
    RAISE NOTICE 'Devices de l''utilisateur: %', (
      SELECT COUNT(*) FROM devices WHERE user_id = current_user_id
    );
    
    RAISE NOTICE 'Clients de l''utilisateur: %', (
      SELECT COUNT(*) FROM clients WHERE user_id = current_user_id
    );
    
    RAISE NOTICE 'Services de l''utilisateur: %', (
      SELECT COUNT(*) FROM services WHERE user_id = current_user_id
    );
    
    RAISE NOTICE 'Parts de l''utilisateur: %', (
      SELECT COUNT(*) FROM parts WHERE user_id = current_user_id
    );
    
    RAISE NOTICE 'Products de l''utilisateur: %', (
      SELECT COUNT(*) FROM products WHERE user_id = current_user_id
    );
  ELSE
    RAISE NOTICE 'Aucun utilisateur connecté';
  END IF;
END $$;
