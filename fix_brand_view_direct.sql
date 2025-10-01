-- Script pour créer la vue brand_with_categories manquante
-- À exécuter directement dans l'éditeur SQL de Supabase

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

-- Tester la vue
SELECT 'Vue créée avec succès' as status;
SELECT COUNT(*) as total_brands FROM public.brand_with_categories;
