-- =====================================================
-- CORRECTION DES POLITIQUES RLS POUR LES DEVIS
-- Ce script corrige les erreurs de politiques existantes
-- =====================================================

-- 1. Supprimer les politiques existantes pour éviter les conflits
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

-- 2. Recréer les politiques RLS pour les devis
CREATE POLICY "Enable read access for authenticated users" ON public.quotes 
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.quotes 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.quotes 
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.quotes 
  FOR DELETE USING (auth.role() = 'authenticated');

-- 3. Recréer les politiques RLS pour les éléments de devis
CREATE POLICY "Enable read access for authenticated users" ON public.quote_items 
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.quote_items 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.quote_items 
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.quote_items 
  FOR DELETE USING (auth.role() = 'authenticated');

-- 4. Vérification
SELECT 
  'POLITIQUES CRÉÉES AVEC SUCCÈS' as status,
  'Toutes les politiques RLS ont été recréées' as message;

-- 5. Lister les politiques existantes
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
WHERE tablename IN ('quotes', 'quote_items')
ORDER BY tablename, policyname;
