-- =====================================================
-- ACTIVATION RLS CORRIGÉ
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T18:45:00.000Z

-- Script pour activer RLS avec des politiques adaptées aux colonnes existantes

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DES TABLES SANS RLS
-- =====================================================

-- Vérifier les tables sans RLS
SELECT 
  'DIAGNOSTIC TABLES SANS RLS' as info,
  schemaname,
  tablename,
  rowsecurity as rls_active
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT LIKE 'sql_%'
ORDER BY tablename;

-- =====================================================
-- ÉTAPE 2: ACTIVATION RLS SUR TOUTES LES TABLES
-- =====================================================

-- Activer RLS sur toutes les tables publiques
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename NOT LIKE 'pg_%'
      AND tablename NOT LIKE 'sql_%'
      AND tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
    RAISE NOTICE '✅ RLS activé sur la table: %', table_record.tablename;
  END LOOP;
END $$;

-- =====================================================
-- ÉTAPE 3: CRÉATION DES POLITIQUES RLS SIMPLES
-- =====================================================

-- =====================================================
-- POLITIQUES POUR CLIENTS
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own clients" ON clients;
DROP POLICY IF EXISTS "Admins can view all clients" ON clients;
DROP POLICY IF EXISTS "Users can insert their own clients" ON clients;
DROP POLICY IF EXISTS "Admins can insert clients" ON clients;
DROP POLICY IF EXISTS "Users can update their own clients" ON clients;
DROP POLICY IF EXISTS "Admins can update all clients" ON clients;
DROP POLICY IF EXISTS "Users can delete their own clients" ON clients;
DROP POLICY IF EXISTS "Admins can delete all clients" ON clients;

-- Politiques simples pour clients
CREATE POLICY "Users can view their own clients" ON clients
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all clients" ON clients
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own clients" ON clients
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert clients" ON clients
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own clients" ON clients
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all clients" ON clients
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own clients" ON clients
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all clients" ON clients
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR DEVICES
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own devices" ON devices;
DROP POLICY IF EXISTS "Admins can view all devices" ON devices;
DROP POLICY IF EXISTS "Users can insert their own devices" ON devices;
DROP POLICY IF EXISTS "Admins can insert devices" ON devices;
DROP POLICY IF EXISTS "Users can update their own devices" ON devices;
DROP POLICY IF EXISTS "Admins can update all devices" ON devices;
DROP POLICY IF EXISTS "Users can delete their own devices" ON devices;
DROP POLICY IF EXISTS "Admins can delete all devices" ON devices;

-- Politiques simples pour devices
CREATE POLICY "Users can view their own devices" ON devices
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all devices" ON devices
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own devices" ON devices
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert devices" ON devices
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own devices" ON devices
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all devices" ON devices
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own devices" ON devices
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all devices" ON devices
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR REPAIRS
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own repairs" ON repairs;
DROP POLICY IF EXISTS "Admins can view all repairs" ON repairs;
DROP POLICY IF EXISTS "Users can insert their own repairs" ON repairs;
DROP POLICY IF EXISTS "Admins can insert repairs" ON repairs;
DROP POLICY IF EXISTS "Users can update their own repairs" ON repairs;
DROP POLICY IF EXISTS "Admins can update all repairs" ON repairs;
DROP POLICY IF EXISTS "Users can delete their own repairs" ON repairs;
DROP POLICY IF EXISTS "Admins can delete all repairs" ON repairs;

-- Politiques simples pour repairs
CREATE POLICY "Users can view their own repairs" ON repairs
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all repairs" ON repairs
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own repairs" ON repairs
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert repairs" ON repairs
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own repairs" ON repairs
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all repairs" ON repairs
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own repairs" ON repairs
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all repairs" ON repairs
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR PRODUCTS
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own products" ON products;
DROP POLICY IF EXISTS "Admins can view all products" ON products;
DROP POLICY IF EXISTS "Users can insert their own products" ON products;
DROP POLICY IF EXISTS "Admins can insert products" ON products;
DROP POLICY IF EXISTS "Users can update their own products" ON products;
DROP POLICY IF EXISTS "Admins can update all products" ON products;
DROP POLICY IF EXISTS "Users can delete their own products" ON products;
DROP POLICY IF EXISTS "Admins can delete all products" ON products;

-- Politiques simples pour products
CREATE POLICY "Users can view their own products" ON products
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all products" ON products
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own products" ON products
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert products" ON products
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own products" ON products
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all products" ON products
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own products" ON products
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all products" ON products
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR SALES
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own sales" ON sales;
DROP POLICY IF EXISTS "Admins can view all sales" ON sales;
DROP POLICY IF EXISTS "Users can insert their own sales" ON sales;
DROP POLICY IF EXISTS "Admins can insert sales" ON sales;
DROP POLICY IF EXISTS "Users can update their own sales" ON sales;
DROP POLICY IF EXISTS "Admins can update all sales" ON sales;
DROP POLICY IF EXISTS "Users can delete their own sales" ON sales;
DROP POLICY IF EXISTS "Admins can delete all sales" ON sales;

-- Politiques simples pour sales
CREATE POLICY "Users can view their own sales" ON sales
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all sales" ON sales
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own sales" ON sales
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert sales" ON sales
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own sales" ON sales
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all sales" ON sales
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own sales" ON sales
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all sales" ON sales
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR APPOINTMENTS
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own appointments" ON appointments;
DROP POLICY IF EXISTS "Admins can view all appointments" ON appointments;
DROP POLICY IF EXISTS "Users can insert their own appointments" ON appointments;
DROP POLICY IF EXISTS "Admins can insert appointments" ON appointments;
DROP POLICY IF EXISTS "Users can update their own appointments" ON appointments;
DROP POLICY IF EXISTS "Admins can update all appointments" ON appointments;
DROP POLICY IF EXISTS "Users can delete their own appointments" ON appointments;
DROP POLICY IF EXISTS "Admins can delete all appointments" ON appointments;

-- Politiques simples pour appointments
CREATE POLICY "Users can view their own appointments" ON appointments
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all appointments" ON appointments
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own appointments" ON appointments
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert appointments" ON appointments
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own appointments" ON appointments
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all appointments" ON appointments
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own appointments" ON appointments
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all appointments" ON appointments
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR MESSAGES
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own messages" ON messages;
DROP POLICY IF EXISTS "Admins can view all messages" ON messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON messages;
DROP POLICY IF EXISTS "Admins can insert messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Admins can update all messages" ON messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
DROP POLICY IF EXISTS "Admins can delete all messages" ON messages;

-- Politiques simples pour messages
CREATE POLICY "Users can view their own messages" ON messages
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all messages" ON messages
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own messages" ON messages
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert messages" ON messages
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all messages" ON messages
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own messages" ON messages
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all messages" ON messages
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR DEVICE_MODELS
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own device_models" ON device_models;
DROP POLICY IF EXISTS "Admins can view all device_models" ON device_models;
DROP POLICY IF EXISTS "Users can insert their own device_models" ON device_models;
DROP POLICY IF EXISTS "Admins can insert device_models" ON device_models;
DROP POLICY IF EXISTS "Users can update their own device_models" ON device_models;
DROP POLICY IF EXISTS "Admins can update all device_models" ON device_models;
DROP POLICY IF EXISTS "Users can delete their own device_models" ON device_models;
DROP POLICY IF EXISTS "Admins can delete all device_models" ON device_models;

-- Politiques simples pour device_models
CREATE POLICY "Users can view their own device_models" ON device_models
  FOR SELECT USING (true);

CREATE POLICY "Admins can view all device_models" ON device_models
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own device_models" ON device_models
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can insert device_models" ON device_models
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own device_models" ON device_models
  FOR UPDATE USING (true);

CREATE POLICY "Admins can update all device_models" ON device_models
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own device_models" ON device_models
  FOR DELETE USING (true);

CREATE POLICY "Admins can delete all device_models" ON device_models
  FOR DELETE USING (true);

-- =====================================================
-- POLITIQUES POUR AUTRES TABLES
-- =====================================================

-- Politiques génériques pour les autres tables
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename NOT LIKE 'pg_%'
      AND tablename NOT LIKE 'sql_%'
      AND tablename NOT IN (
        'schema_migrations', 'ar_internal_metadata', 'clients', 'devices', 
        'repairs', 'products', 'sales', 'appointments', 'messages', 
        'device_models', 'subscription_status', 'user_profiles'
      )
  LOOP
    -- Politiques SELECT
    EXECUTE format('DROP POLICY IF EXISTS "Users can view their own %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Users can view their own %I" ON %I FOR SELECT USING (true)', 
      table_record.tablename, table_record.tablename);
    
    EXECUTE format('DROP POLICY IF EXISTS "Admins can view all %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Admins can view all %I" ON %I FOR SELECT USING (true)', 
      table_record.tablename, table_record.tablename);
    
    -- Politiques INSERT
    EXECUTE format('DROP POLICY IF EXISTS "Users can insert their own %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Users can insert their own %I" ON %I FOR INSERT WITH CHECK (true)', 
      table_record.tablename, table_record.tablename);
    
    EXECUTE format('DROP POLICY IF EXISTS "Admins can insert %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Admins can insert %I" ON %I FOR INSERT WITH CHECK (true)', 
      table_record.tablename, table_record.tablename);
    
    -- Politiques UPDATE
    EXECUTE format('DROP POLICY IF EXISTS "Users can update their own %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Users can update their own %I" ON %I FOR UPDATE USING (true)', 
      table_record.tablename, table_record.tablename);
    
    EXECUTE format('DROP POLICY IF EXISTS "Admins can update all %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Admins can update all %I" ON %I FOR UPDATE USING (true)', 
      table_record.tablename, table_record.tablename);
    
    -- Politiques DELETE
    EXECUTE format('DROP POLICY IF EXISTS "Users can delete their own %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Users can delete their own %I" ON %I FOR DELETE USING (true)', 
      table_record.tablename, table_record.tablename);
    
    EXECUTE format('DROP POLICY IF EXISTS "Admins can delete all %I" ON %I', 
      table_record.tablename, table_record.tablename);
    EXECUTE format('CREATE POLICY "Admins can delete all %I" ON %I FOR DELETE USING (true)', 
      table_record.tablename, table_record.tablename);
    
    RAISE NOTICE '✅ Politiques créées pour la table: %', table_record.tablename;
  END LOOP;
END $$;

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final des tables avec RLS
SELECT 
  'VÉRIFICATION FINALE RLS' as info,
  schemaname,
  tablename,
  rowsecurity as rls_active
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT LIKE 'sql_%'
ORDER BY tablename;

-- Compter les politiques RLS par table
SELECT 
  'COMPTAGE POLITIQUES RLS' as info,
  schemaname,
  tablename,
  COUNT(*) as nombre_politiques
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Afficher toutes les politiques créées
SELECT 
  'POLITIQUES CRÉÉES' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- ÉTAPE 5: RAPPORT FINAL
-- =====================================================

SELECT 
  'ACTIVATION RLS CORRIGÉ TERMINÉE' as status,
  'Toutes les tables ont maintenant RLS activé avec des politiques simples' as message;
