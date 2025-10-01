-- Migration V6: Création de la vue brand_with_categories
-- Cette vue permet de récupérer les marques avec leurs catégories associées

-- Supprimer la vue si elle existe déjà
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

-- Configurer la sécurité de la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- Créer les politiques RLS pour la vue
CREATE POLICY "Users can view their own brands with categories" ON public.brand_with_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own brands with categories" ON public.brand_with_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own brands with categories" ON public.brand_with_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own brands with categories" ON public.brand_with_categories
    FOR DELETE USING (auth.uid() = user_id);

-- Activer RLS sur la vue (si nécessaire)
-- Note: Les vues héritent des politiques des tables sous-jacentes
