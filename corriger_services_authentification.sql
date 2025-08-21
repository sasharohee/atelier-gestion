-- 🔧 CORRECTION - Services d'Authentification
-- Script pour permettre aux services de fonctionner sans authentification stricte

-- 1. Vérifier les contraintes de clé étrangère sur user_id
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
  AND tc.constraint_type = 'FOREIGN KEY';

-- 2. Supprimer les contraintes de clé étrangère problématiques
-- (Exécuter ces commandes une par une si les contraintes existent)

-- Clients
ALTER TABLE public.clients DROP CONSTRAINT IF EXISTS clients_user_id_fkey;

-- Devices
ALTER TABLE public.devices DROP CONSTRAINT IF EXISTS devices_user_id_fkey;

-- Services
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS services_user_id_fkey;

-- Parts
ALTER TABLE public.parts DROP CONSTRAINT IF EXISTS parts_user_id_fkey;

-- Products
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_user_id_fkey;

-- Repairs
ALTER TABLE public.repairs DROP CONSTRAINT IF EXISTS repairs_user_id_fkey;

-- Sales
ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_user_id_fkey;

-- 3. Permettre les valeurs NULL pour user_id
ALTER TABLE public.clients ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.services ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.parts ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.products ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.repairs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.sales ALTER COLUMN user_id DROP NOT NULL;

-- 4. Vérifier la structure des tables
SELECT 
  table_name,
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns 
WHERE table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'sales')
  AND column_name = 'user_id'
ORDER BY table_name;

-- 5. Mettre à jour les données existantes pour permettre le développement
-- (Optionnel - décommentez si nécessaire)
/*
UPDATE public.clients SET user_id = NULL WHERE user_id IS NOT NULL;
UPDATE public.devices SET user_id = NULL WHERE user_id IS NOT NULL;
UPDATE public.services SET user_id = NULL WHERE user_id IS NOT NULL;
UPDATE public.parts SET user_id = NULL WHERE user_id IS NOT NULL;
UPDATE public.products SET user_id = NULL WHERE user_id IS NOT NULL;
UPDATE public.repairs SET user_id = NULL WHERE user_id IS NOT NULL;
UPDATE public.sales SET user_id = NULL WHERE user_id IS NOT NULL;
*/

-- 6. Vérifier les contraintes restantes
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
ORDER BY tc.table_name, tc.constraint_type;

-- 7. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ Correction terminée!';
  RAISE NOTICE 'Les services peuvent maintenant fonctionner sans authentification stricte.';
  RAISE NOTICE 'Mode développement activé - pas de filtrage par utilisateur.';
END $$;
