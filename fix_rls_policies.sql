-- Script pour corriger les politiques RLS
-- À exécuter dans Supabase SQL Editor

-- 1. Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "Users can view their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can insert their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can update their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can delete their own device categories" ON public.device_categories;

DROP POLICY IF EXISTS "Users can view their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can insert their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can update their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can delete their own device brands" ON public.device_brands;

DROP POLICY IF EXISTS "Users can view their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can insert their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can update their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can delete their own device models" ON public.device_models;

DROP POLICY IF EXISTS "Users can view their own brand categories" ON public.brand_categories;
DROP POLICY IF EXISTS "Users can insert their own brand categories" ON public.brand_categories;
DROP POLICY IF EXISTS "Users can update their own brand categories" ON public.brand_categories;
DROP POLICY IF EXISTS "Users can delete their own brand categories" ON public.brand_categories;

-- 2. Créer de nouvelles politiques RLS plus permissives

-- Politiques pour device_categories
CREATE POLICY "Enable read access for all users" ON public.device_categories
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.device_categories
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable update for authenticated users" ON public.device_categories
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable delete for authenticated users" ON public.device_categories
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Politiques pour device_brands
CREATE POLICY "Enable read access for all users" ON public.device_brands
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.device_brands
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable update for authenticated users" ON public.device_brands
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable delete for authenticated users" ON public.device_brands
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Politiques pour device_models
CREATE POLICY "Enable read access for all users" ON public.device_models
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.device_models
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable update for authenticated users" ON public.device_models
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable delete for authenticated users" ON public.device_models
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Politiques pour brand_categories
CREATE POLICY "Enable read access for all users" ON public.brand_categories
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.brand_categories
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable update for authenticated users" ON public.brand_categories
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable delete for authenticated users" ON public.brand_categories
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- 3. Vérifier que RLS est activé
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;

-- 4. Vérifier les nouvelles politiques
SELECT '=== NOUVELLES POLITIQUES RLS ===' as info;

SELECT 
    tablename,
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('device_categories', 'device_brands', 'device_models', 'brand_categories')
ORDER BY tablename, policyname;

SELECT '✅ Politiques RLS mises à jour avec succès !' as result;
SELECT '💡 Vous pouvez maintenant créer, modifier et supprimer des données.' as note;
