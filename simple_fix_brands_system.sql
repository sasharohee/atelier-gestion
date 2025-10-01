-- ============================================================================
-- CORRECTION SIMPLE POUR PERMETTRE LA MODIFICATION DE TOUTES LES MARQUES
-- ============================================================================
-- Exécutez ce script dans l'interface Supabase SQL Editor
-- ============================================================================

-- 1. SUPPRIMER LES FONCTIONS EXISTANTES
-- ============================================================================
DROP FUNCTION IF EXISTS public.update_brand_categories(text, uuid[]) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_brand(text, text, text, text, uuid[]) CASCADE;

-- 2. SUPPRIMER LES VUES
-- ============================================================================
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- 3. SUPPRIMER LES CONTRAINTES
-- ============================================================================
ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_brand_id_fkey;
ALTER TABLE public.device_models DROP CONSTRAINT IF EXISTS device_models_brand_id_fkey;
ALTER TABLE public.device_brands DROP CONSTRAINT IF EXISTS device_brands_pkey;
ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_pkey;

-- 4. MODIFIER LES TYPES DE COLONNES
-- ============================================================================
ALTER TABLE public.device_brands ALTER COLUMN id TYPE TEXT;
ALTER TABLE public.brand_categories ALTER COLUMN brand_id TYPE TEXT;
ALTER TABLE public.device_models ALTER COLUMN brand_id TYPE TEXT;

-- 5. RECRÉER LES CONTRAINTES
-- ============================================================================
ALTER TABLE public.device_brands ADD CONSTRAINT device_brands_pkey PRIMARY KEY (id);
ALTER TABLE public.brand_categories ADD CONSTRAINT brand_categories_pkey PRIMARY KEY (id);
ALTER TABLE public.brand_categories ADD CONSTRAINT brand_categories_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD CONSTRAINT device_models_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE;

-- 6. CRÉER LA VUE
-- ============================================================================
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
        json_agg(
            json_build_object(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description,
                'icon', dc.icon
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands db
LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.created_at, db.updated_at;

ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- 7. CRÉER LES FONCTIONS
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids UUID[]
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM device_brands WHERE id = p_brand_id AND user_id = v_user_id) THEN
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;
    
    DELETE FROM brand_categories WHERE brand_id = p_brand_id;
    
    IF p_category_ids IS NOT NULL AND array_length(p_category_ids, 1) > 0 THEN
        INSERT INTO brand_categories (brand_id, category_id)
        SELECT p_brand_id, unnest(p_category_ids)
        WHERE unnest(p_category_ids) IN (
            SELECT id FROM device_categories WHERE user_id = v_user_id
        );
    END IF;
    
    SELECT json_build_object(
        'id', db.id,
        'name', db.name,
        'description', db.description,
        'logo', db.logo,
        'is_active', db.is_active,
        'categories', COALESCE(
            json_agg(
                json_build_object(
                    'id', dc.id,
                    'name', dc.name,
                    'description', dc.description,
                    'icon', dc.icon
                )
            ) FILTER (WHERE dc.id IS NOT NULL),
            '[]'::json
        )
    ) INTO v_result
    FROM device_brands db
    LEFT JOIN brand_categories bc ON db.id = bc.brand_id
    LEFT JOIN device_categories dc ON bc.category_id = dc.id
    WHERE db.id = p_brand_id AND db.user_id = v_user_id
    GROUP BY db.id, db.name, db.description, db.logo, db.is_active;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.upsert_brand(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_ids UUID[] DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    INSERT INTO device_brands (id, name, description, logo, user_id, created_by)
    VALUES (p_id, p_name, p_description, p_logo, v_user_id, v_user_id)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_at = NOW()
    WHERE device_brands.user_id = v_user_id;
    
    IF p_category_ids IS NOT NULL THEN
        PERFORM public.update_brand_categories(p_id, p_category_ids);
    END IF;
    
    SELECT json_build_object(
        'id', db.id,
        'name', db.name,
        'description', db.description,
        'logo', db.logo,
        'is_active', db.is_active,
        'categories', COALESCE(
            json_agg(
                json_build_object(
                    'id', dc.id,
                    'name', dc.name,
                    'description', dc.description,
                    'icon', dc.icon
                )
            ) FILTER (WHERE dc.id IS NOT NULL),
            '[]'::json
        )
    ) INTO v_result
    FROM device_brands db
    LEFT JOIN brand_categories bc ON db.id = bc.brand_id
    LEFT JOIN device_categories dc ON bc.category_id = dc.id
    WHERE db.id = p_id AND db.user_id = v_user_id
    GROUP BY db.id, db.name, db.description, db.logo, db.is_active;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. CRÉER LES MARQUES PAR DÉFAUT
-- ============================================================================
DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        -- Créer une catégorie par défaut
        INSERT INTO device_categories (name, description, icon, is_active, user_id, created_by)
        VALUES ('Électronique', 'Catégorie par défaut', 'smartphone', true, v_user_id, v_user_id)
        ON CONFLICT DO NOTHING;
        
        SELECT id INTO v_category_id FROM device_categories 
        WHERE name = 'Électronique' AND user_id = v_user_id LIMIT 1;
        
        -- Créer les marques par défaut
        INSERT INTO device_brands (id, name, description, logo, is_active, user_id, created_by)
        VALUES 
            ('1', 'Apple', 'Fabricant américain de produits électroniques premium', '', true, v_user_id, v_user_id),
            ('2', 'Samsung', 'Fabricant sud-coréen d''électronique grand public', '', true, v_user_id, v_user_id),
            ('3', 'Google', 'Entreprise américaine de technologie', '', true, v_user_id, v_user_id),
            ('4', 'Microsoft', 'Entreprise américaine de technologie', '', true, v_user_id, v_user_id),
            ('5', 'Sony', 'Conglomérat japonais d''électronique', '', true, v_user_id, v_user_id)
        ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            description = EXCLUDED.description,
            logo = EXCLUDED.logo,
            updated_at = NOW()
        WHERE device_brands.user_id = v_user_id;
        
        -- Associer les marques à la catégorie
        IF v_category_id IS NOT NULL THEN
            INSERT INTO brand_categories (brand_id, category_id)
            VALUES 
                ('1', v_category_id),
                ('2', v_category_id),
                ('3', v_category_id),
                ('4', v_category_id),
                ('5', v_category_id)
            ON CONFLICT (brand_id, category_id) DO NOTHING;
        END IF;
        
        RAISE NOTICE '✅ Marques par défaut créées avec succès';
    END IF;
END $$;

-- 9. VÉRIFICATION
-- ============================================================================
SELECT 'Vérification des marques créées:' as info;
SELECT id, name, description FROM device_brands WHERE user_id = auth.uid() ORDER BY name;

SELECT 'Test de la fonction upsert_brand:' as info;
SELECT public.upsert_brand('test', 'Test', 'Description test', '', ARRAY[(SELECT id FROM device_categories WHERE user_id = auth.uid() LIMIT 1)]) as result;

-- Nettoyer le test
DELETE FROM device_brands WHERE id = 'test' AND user_id = auth.uid();

SELECT '✅ Script exécuté avec succès !' as result;
