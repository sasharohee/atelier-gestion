-- Script pour créer la vue brand_with_categories dans la base de production
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier que les tables nécessaires existent
SELECT 'Vérification des tables...' as step;

-- Vérifier device_brands
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_brands' AND table_schema = 'public')
        THEN '✅ Table device_brands existe'
        ELSE '❌ Table device_brands manquante'
    END as device_brands_status;

-- Vérifier brand_categories
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'brand_categories' AND table_schema = 'public')
        THEN '✅ Table brand_categories existe'
        ELSE '❌ Table brand_categories manquante'
    END as brand_categories_status;

-- Vérifier device_categories
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_categories' AND table_schema = 'public')
        THEN '✅ Table device_categories existe'
        ELSE '❌ Table device_categories manquante'
    END as device_categories_status;

-- 2. Créer les tables manquantes si nécessaire
-- Créer device_categories si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.device_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer brand_categories si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.brand_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand_id UUID NOT NULL,
    category_id UUID NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES public.device_categories(id) ON DELETE CASCADE
);

-- 3. Activer RLS sur les tables
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;

-- 4. Créer les politiques RLS pour device_brands
DROP POLICY IF EXISTS "Users can view their own brands" ON public.device_brands;
CREATE POLICY "Users can view their own brands" ON public.device_brands
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own brands" ON public.device_brands;
CREATE POLICY "Users can insert their own brands" ON public.device_brands
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own brands" ON public.device_brands;
CREATE POLICY "Users can update their own brands" ON public.device_brands
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own brands" ON public.device_brands;
CREATE POLICY "Users can delete their own brands" ON public.device_brands
    FOR DELETE USING (auth.uid() = user_id);

-- 5. Créer les politiques RLS pour brand_categories
DROP POLICY IF EXISTS "Users can view their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can view their own brand categories" ON public.brand_categories
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can insert their own brand categories" ON public.brand_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can update their own brand categories" ON public.brand_categories
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own brand categories" ON public.brand_categories;
CREATE POLICY "Users can delete their own brand categories" ON public.brand_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 6. Créer les politiques RLS pour device_categories
DROP POLICY IF EXISTS "Users can view their own device categories" ON public.device_categories;
CREATE POLICY "Users can view their own device categories" ON public.device_categories
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own device categories" ON public.device_categories;
CREATE POLICY "Users can insert their own device categories" ON public.device_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own device categories" ON public.device_categories;
CREATE POLICY "Users can update their own device categories" ON public.device_categories
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own device categories" ON public.device_categories;
CREATE POLICY "Users can delete their own device categories" ON public.device_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 7. Supprimer la vue si elle existe déjà
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- 8. Créer la vue brand_with_categories
CREATE VIEW public.brand_with_categories AS
SELECT 
    db.id,
    db.name,
    db.description,
    db.logo,
    db.is_active,
    db.user_id,
    db.created_by,
    db.updated_by,
    db.created_at,
    db.updated_at,
    COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands db
LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.updated_by, db.created_at, db.updated_at;

-- 9. Configurer la sécurité de la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- 10. Tester la vue
SELECT 'Vue brand_with_categories créée avec succès' as status;

-- 11. Vérifier que la vue existe
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'brand_with_categories'
AND schemaname = 'public';

-- 12. Tester la vue avec un utilisateur
SELECT COUNT(*) as total_brands FROM public.brand_with_categories;

-- 13. Afficher les premières marques pour vérification
SELECT id, name, user_id, categories FROM public.brand_with_categories LIMIT 5;


