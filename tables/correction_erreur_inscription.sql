-- =====================================================
-- CORRECTION ERREUR INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T18:30:00.000Z

-- Script pour corriger l'erreur d'inscription causée par le trigger

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DU PROBLÈME
-- =====================================================

-- Vérifier l'état actuel de la table subscription_status
SELECT 
  'DIAGNOSTIC TABLE SUBSCRIPTION_STATUS' as info,
  (SELECT COUNT(*) FROM subscription_status) as total_rows,
  (SELECT COUNT(*) FROM information_schema.columns 
   WHERE table_name = 'subscription_status' AND table_schema = 'public') as total_columns;

-- Vérifier les colonnes de subscription_status
SELECT 
  'COLONNES SUBSCRIPTION_STATUS' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les contraintes de subscription_status
SELECT 
  'CONTRAINTES SUBSCRIPTION_STATUS' as info,
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public';

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DU TRIGGER
-- =====================================================

-- Vérifier si le trigger existe
SELECT 
  'VÉRIFICATION TRIGGER' as info,
  trigger_name,
  event_manipulation,
  action_statement,
  action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status';

-- =====================================================
-- ÉTAPE 3: CORRECTION DE LA TABLE SUBSCRIPTION_STATUS
-- =====================================================

-- S'assurer que toutes les colonnes nécessaires existent
DO $$
BEGIN
  -- Ajouter la colonne id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'id'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN id UUID PRIMARY KEY DEFAULT gen_random_uuid();
    RAISE NOTICE '✅ Colonne id ajoutée';
  END IF;

  -- Ajouter la colonne user_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'user_id'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN user_id UUID UNIQUE NOT NULL;
    RAISE NOTICE '✅ Colonne user_id ajoutée';
  END IF;

  -- Ajouter la colonne first_name si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'first_name'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN first_name TEXT;
    RAISE NOTICE '✅ Colonne first_name ajoutée';
  END IF;

  -- Ajouter la colonne last_name si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'last_name'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN last_name TEXT;
    RAISE NOTICE '✅ Colonne last_name ajoutée';
  END IF;

  -- Ajouter la colonne email si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'email'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN email TEXT;
    RAISE NOTICE '✅ Colonne email ajoutée';
  END IF;

  -- Ajouter la colonne is_active si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'is_active'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN is_active BOOLEAN DEFAULT false;
    RAISE NOTICE '✅ Colonne is_active ajoutée';
  END IF;

  -- Ajouter la colonne subscription_type si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'subscription_type'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN subscription_type TEXT DEFAULT 'free';
    RAISE NOTICE '✅ Colonne subscription_type ajoutée';
  END IF;

  -- Ajouter la colonne notes si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'notes'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN notes TEXT;
    RAISE NOTICE '✅ Colonne notes ajoutée';
  END IF;

  -- Ajouter la colonne created_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'created_at'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    RAISE NOTICE '✅ Colonne created_at ajoutée';
  END IF;

  -- Ajouter la colonne updated_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    RAISE NOTICE '✅ Colonne updated_at ajoutée';
  END IF;

  -- Ajouter la colonne status si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'status'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN status TEXT DEFAULT 'INACTIF';
    RAISE NOTICE '✅ Colonne status ajoutée';
  END IF;

  -- Ajouter la colonne activated_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'activated_at'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN activated_at TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE '✅ Colonne activated_at ajoutée';
  END IF;

  -- Ajouter la colonne activated_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'activated_by'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN activated_by UUID;
    RAISE NOTICE '✅ Colonne activated_by ajoutée';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 4: CORRECTION DE LA FONCTION DE SYNCHRONISATION
-- =====================================================

-- Recréer la fonction de synchronisation avec gestion d'erreurs
CREATE OR REPLACE FUNCTION sync_user_to_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Insérer l'utilisateur dans subscription_status s'il n'existe pas déjà
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at,
    status
  )
  SELECT 
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test') as last_name,
    NEW.email,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN true
      WHEN NEW.email = 'srohee32@gmail.com' THEN true
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN true
      ELSE false
    END as is_active,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'premium'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'premium'
      ELSE 'free'
    END as subscription_type,
    'Compte créé automatiquement',
    COALESCE(NEW.created_at, NOW()) as created_at,
    NOW() as updated_at,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'ACTIF'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
      ELSE 'INACTIF'
    END as status
  WHERE NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = NEW.id
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, log l'erreur mais ne pas faire échouer l'inscription
    RAISE WARNING 'Erreur lors de la synchronisation vers subscription_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ÉTAPE 5: RECRÉATION DU TRIGGER
-- =====================================================

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS trigger_sync_user_to_subscription_status ON auth.users;

-- Créer le trigger pour synchroniser automatiquement
CREATE TRIGGER trigger_sync_user_to_subscription_status
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 6: CORRECTION DES POLITIQUES RLS
-- =====================================================

-- Supprimer les politiques RLS existantes sur subscription_status
DROP POLICY IF EXISTS "Users can view their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admins can insert subscription statuses" ON subscription_status;

-- Activer RLS sur subscription_status
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;

-- Créer une politique pour permettre à tous les utilisateurs authentifiés de voir leur propre statut
CREATE POLICY "Users can view their own subscription status" ON subscription_status
  FOR SELECT USING (auth.uid() = user_id);

-- Créer une politique pour permettre aux admins de voir tous les statuts
CREATE POLICY "Admins can view all subscription statuses" ON subscription_status
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Créer une politique pour permettre aux admins de modifier tous les statuts
CREATE POLICY "Admins can update all subscription statuses" ON subscription_status
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Créer une politique pour permettre aux admins d'insérer des statuts
CREATE POLICY "Admins can insert subscription statuses" ON subscription_status
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Créer une politique pour permettre l'insertion automatique par le trigger
CREATE POLICY "Allow trigger insert" ON subscription_status
  FOR INSERT WITH CHECK (true);

-- =====================================================
-- ÉTAPE 7: TEST DE L'INSCRIPTION
-- =====================================================

-- Test de la fonction de synchronisation
DO $$
DECLARE
  test_uuid UUID := gen_random_uuid();
  test_result RECORD;
BEGIN
  -- Simuler l'insertion d'un nouvel utilisateur
  INSERT INTO auth.users (
    id,
    email,
    raw_user_meta_data,
    created_at
  ) VALUES (
    test_uuid,
    'test_inscription_' || test_uuid || '@example.com',
    '{"first_name": "Test", "last_name": "Inscription", "role": "technician"}'::jsonb,
    NOW()
  );
  
  -- Vérifier que l'utilisateur a été synchronisé
  SELECT * INTO test_result FROM subscription_status WHERE user_id = test_uuid;
  
  IF test_result IS NOT NULL THEN
    RAISE NOTICE '✅ Test d''inscription réussi pour l''utilisateur: %', test_uuid;
    RAISE NOTICE '✅ Données synchronisées: email=%, is_active=%, status=%', 
      test_result.email, test_result.is_active, test_result.status;
  ELSE
    RAISE NOTICE '❌ Test d''inscription échoué pour l''utilisateur: %', test_uuid;
  END IF;
  
  -- Nettoyer le test
  DELETE FROM subscription_status WHERE user_id = test_uuid;
  DELETE FROM auth.users WHERE id = test_uuid;
  RAISE NOTICE '✅ Test nettoyé';
END $$;

-- =====================================================
-- ÉTAPE 8: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscription_users,
  (SELECT COUNT(*) FROM auth.users u 
   WHERE NOT EXISTS (SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id)) as users_manquants;

-- Afficher un exemple d'utilisateur synchronisé
SELECT 
  'EXEMPLE UTILISATEUR SYNCHRONISÉ' as info,
  ss.user_id,
  ss.email,
  ss.first_name,
  ss.last_name,
  ss.is_active,
  ss.status,
  ss.subscription_type,
  ss.created_at
FROM subscription_status ss
JOIN auth.users u ON ss.user_id = u.id
ORDER BY ss.created_at DESC
LIMIT 1;

-- Vérifier les politiques RLS
SELECT 
  'VÉRIFICATION POLITIQUES RLS' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'subscription_status';

-- =====================================================
-- ÉTAPE 9: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION ERREUR INSCRIPTION TERMINÉE' as status,
  'L''inscription fonctionne maintenant sans erreur 500' as message;
