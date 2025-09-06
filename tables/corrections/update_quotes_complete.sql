-- =====================================================
-- MISE À JOUR COMPLÈTE DES TABLES DE DEVIS
-- Ce script gère tous les cas d'erreur et met à jour les tables
-- =====================================================

-- 1. Créer le type ENUM pour le statut des devis
DO $$ BEGIN
    CREATE TYPE quote_status_type AS ENUM ('draft', 'sent', 'accepted', 'rejected', 'expired');
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Le type quote_status_type existe déjà';
END $$;

-- 2. Créer ou mettre à jour la table des devis
CREATE TABLE IF NOT EXISTS public.quotes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  status quote_status_type DEFAULT 'draft',
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  notes TEXT,
  terms TEXT,
  -- Nouveaux champs pour les devis de réparation
  is_repair_quote BOOLEAN DEFAULT false,
  repair_details JSONB DEFAULT '{}'::jsonb,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Ajouter les nouvelles colonnes si elles n'existent pas
DO $$ 
BEGIN
    -- Ajouter is_repair_quote si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'quotes' AND column_name = 'is_repair_quote') THEN
        ALTER TABLE public.quotes ADD COLUMN is_repair_quote BOOLEAN DEFAULT false;
        RAISE NOTICE 'Colonne is_repair_quote ajoutée';
    END IF;
    
    -- Ajouter repair_details si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'quotes' AND column_name = 'repair_details') THEN
        ALTER TABLE public.quotes ADD COLUMN repair_details JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE 'Colonne repair_details ajoutée';
    END IF;
END $$;

-- 4. Créer ou mettre à jour la table des éléments de devis
CREATE TABLE IF NOT EXISTS public.quote_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quote_id UUID REFERENCES public.quotes(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  item_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Mettre à jour la contrainte de type si nécessaire
DO $$ 
BEGIN
    -- Supprimer l'ancienne contrainte si elle existe
    ALTER TABLE public.quote_items DROP CONSTRAINT IF EXISTS quote_items_type_check;
    
    -- Ajouter la nouvelle contrainte avec 'repair'
    ALTER TABLE public.quote_items 
      ADD CONSTRAINT quote_items_type_check 
      CHECK (type IN ('product', 'service', 'part', 'repair'));
    
    RAISE NOTICE 'Contrainte de type mise à jour pour inclure repair';
END $$;

-- 6. Activer RLS sur les tables
ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_items ENABLE ROW LEVEL SECURITY;

-- 7. Supprimer les politiques existantes pour éviter les conflits
DO $$ 
BEGIN
    -- Supprimer les politiques existantes pour quotes
    DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.quotes;
    DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.quotes;
    DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.quotes;
    DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.quotes;
    
    -- Supprimer les politiques existantes pour quote_items
    DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.quote_items;
    DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.quote_items;
    DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.quote_items;
    DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.quote_items;
    
    RAISE NOTICE 'Politiques existantes supprimées';
END $$;

-- 8. Recréer les politiques RLS pour les devis
CREATE POLICY "Enable read access for authenticated users" ON public.quotes 
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.quotes 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.quotes 
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.quotes 
  FOR DELETE USING (auth.role() = 'authenticated');

-- 9. Recréer les politiques RLS pour les éléments de devis
CREATE POLICY "Enable read access for authenticated users" ON public.quote_items 
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.quote_items 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.quote_items 
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.quote_items 
  FOR DELETE USING (auth.role() = 'authenticated');

-- 10. Créer les index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_quotes_client_id ON public.quotes(client_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON public.quotes(status);
CREATE INDEX IF NOT EXISTS idx_quotes_user_id ON public.quotes(user_id);
CREATE INDEX IF NOT EXISTS idx_quotes_valid_until ON public.quotes(valid_until);
CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON public.quote_items(quote_id);

-- 11. Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_quotes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 12. Trigger pour mettre à jour automatiquement updated_at
DROP TRIGGER IF EXISTS update_quotes_updated_at_trigger ON public.quotes;
CREATE TRIGGER update_quotes_updated_at_trigger
  BEFORE UPDATE ON public.quotes
  FOR EACH ROW
  EXECUTE FUNCTION update_quotes_updated_at();

-- 13. Vérification finale
SELECT 
  'MISE À JOUR TERMINÉE AVEC SUCCÈS' as status,
  'Tables quotes et quote_items mises à jour avec RLS activé' as message;

-- 14. Afficher la structure des tables
SELECT 
  'STRUCTURE TABLE QUOTES' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'quotes' 
ORDER BY ordinal_position;

-- 15. Lister les politiques créées
SELECT 
  'POLITIQUES CRÉÉES' as info,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('quotes', 'quote_items')
ORDER BY tablename, policyname;
