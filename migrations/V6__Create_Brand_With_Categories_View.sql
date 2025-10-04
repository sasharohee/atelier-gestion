-- Migration V6: Création de la vue brand_with_categories
-- Cette vue permet de récupérer les marques avec leurs catégories associées

-- 1. Créer les tables manquantes si elles n'existent pas

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

-- 2. Activer RLS sur les nouvelles tables
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;

-- 3. Créer les politiques RLS pour device_categories
CREATE POLICY "Users can view their own device categories" ON public.device_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device categories" ON public.device_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device categories" ON public.device_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device categories" ON public.device_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Créer les politiques RLS pour brand_categories
CREATE POLICY "Users can view their own brand categories" ON public.brand_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own brand categories" ON public.brand_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own brand categories" ON public.brand_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own brand categories" ON public.brand_categories
    FOR DELETE USING (auth.uid() = user_id);

-- 5. Supprimer la vue si elle existe déjà
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Créer la vue brand_with_categories
CREATE VIEW public.brand_with_categories AS
SELECT 
    db.id,
    db.name,
    db.description,
    db.logo,
    db.is_active,
    db.user_id,
    db.created_by,
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
GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.created_at, db.updated_at;

-- Configurer la sécurité de la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- Note: Les vues héritent automatiquement des politiques RLS des tables sous-jacentes
-- Pas besoin de créer des politiques spécifiques sur la vue
