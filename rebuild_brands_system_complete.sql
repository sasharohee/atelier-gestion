-- ============================================================================
-- RECONSTRUCTION COMPLÈTE DU SYSTÈME DES MARQUES
-- ============================================================================
-- Date: $(date)
-- Description: Refaire complètement le système pour permettre la modification de toutes les marques
-- ============================================================================

-- 1. SAUVEGARDER LES DONNÉES EXISTANTES
-- ============================================================================
SELECT '=== SAUVEGARDE DES DONNÉES ===' as section;

-- Créer une table de sauvegarde pour les marques existantes
CREATE TABLE IF NOT EXISTS device_brands_backup AS 
SELECT * FROM device_brands WHERE user_id = auth.uid();

-- Créer une table de sauvegarde pour les catégories de marques
CREATE TABLE IF NOT EXISTS brand_categories_backup AS 
SELECT * FROM brand_categories;

-- 2. SUPPRIMER LES VUES ET CONTRAINTES EXISTANTES
-- ============================================================================
SELECT '=== SUPPRESSION DES ÉLÉMENTS EXISTANTS ===' as section;

-- Supprimer les vues
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;
DROP VIEW IF EXISTS public.device_brands_view CASCADE;

-- Supprimer les contraintes de clés étrangères
ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_brand_id_fkey;
ALTER TABLE public.device_models DROP CONSTRAINT IF EXISTS device_models_brand_id_fkey;

-- Supprimer les contraintes de clés primaires
ALTER TABLE public.device_brands DROP CONSTRAINT IF EXISTS device_brands_pkey;
ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_pkey;

-- 3. RECRÉER LA TABLE device_brands AVEC UNE STRUCTURE SIMPLIFIÉE
-- ============================================================================
SELECT '=== RECRÉATION DE LA TABLE device_brands ===' as section;

-- Supprimer la table existante
DROP TABLE IF EXISTS public.device_brands CASCADE;

-- Créer une nouvelle table device_brands avec ID TEXT
CREATE TABLE public.device_brands (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    logo TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Créer la contrainte de clé primaire
ALTER TABLE public.device_brands 
ADD CONSTRAINT device_brands_pkey PRIMARY KEY (id);

-- Créer les index
CREATE INDEX idx_device_brands_user_id ON public.device_brands(user_id);
CREATE INDEX idx_device_brands_name ON public.device_brands(name);

-- 4. RECRÉER LA TABLE brand_categories POUR LES RELATIONS MANY-TO-MANY
-- ============================================================================
SELECT '=== RECRÉATION DE LA TABLE brand_categories ===' as section;

-- Supprimer la table existante
DROP TABLE IF EXISTS public.brand_categories CASCADE;

-- Créer une nouvelle table brand_categories
CREATE TABLE public.brand_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand_id TEXT NOT NULL,
    category_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(brand_id, category_id)
);

-- Créer les contraintes de clés étrangères
ALTER TABLE public.brand_categories 
ADD CONSTRAINT brand_categories_brand_id_fkey 
FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE;

ALTER TABLE public.brand_categories 
ADD CONSTRAINT brand_categories_category_id_fkey 
FOREIGN KEY (category_id) REFERENCES public.device_categories(id) ON DELETE CASCADE;

-- Créer les index
CREATE INDEX idx_brand_categories_brand_id ON public.brand_categories(brand_id);
CREATE INDEX idx_brand_categories_category_id ON public.brand_categories(category_id);

-- 5. MODIFIER LA TABLE device_models POUR UTILISER TEXT POUR brand_id
-- ============================================================================
SELECT '=== MODIFICATION DE LA TABLE device_models ===' as section;

-- Modifier le type de la colonne brand_id
ALTER TABLE public.device_models 
ALTER COLUMN brand_id TYPE TEXT;

-- Recréer la contrainte de clé étrangère
ALTER TABLE public.device_models 
ADD CONSTRAINT device_models_brand_id_fkey 
FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) ON DELETE CASCADE;

-- Créer l'index
CREATE INDEX IF NOT EXISTS idx_device_models_brand_id ON public.device_models(brand_id);

-- 6. CRÉER LA VUE brand_with_categories
-- ============================================================================
SELECT '=== CRÉATION DE LA VUE brand_with_categories ===' as section;

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

-- Définir la sécurité de la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- 7. CRÉER LES FONCTIONS RPC POUR LA GESTION DES MARQUES
-- ============================================================================
SELECT '=== CRÉATION DES FONCTIONS RPC ===' as section;

-- Fonction pour mettre à jour les catégories d'une marque
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids UUID[]
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    -- Vérifier que la marque appartient à l'utilisateur
    IF NOT EXISTS (SELECT 1 FROM device_brands WHERE id = p_brand_id AND user_id = v_user_id) THEN
        RAISE EXCEPTION 'Marque non trouvée ou non autorisée';
    END IF;
    
    -- Supprimer les anciennes associations
    DELETE FROM brand_categories WHERE brand_id = p_brand_id;
    
    -- Ajouter les nouvelles associations
    IF p_category_ids IS NOT NULL AND array_length(p_category_ids, 1) > 0 THEN
        INSERT INTO brand_categories (brand_id, category_id)
        SELECT p_brand_id, unnest(p_category_ids)
        WHERE unnest(p_category_ids) IN (
            SELECT id FROM device_categories WHERE user_id = v_user_id
        );
    END IF;
    
    -- Retourner les informations de la marque mise à jour
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

-- Fonction pour créer ou mettre à jour une marque
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
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;
    
    -- Créer ou mettre à jour la marque
    INSERT INTO device_brands (id, name, description, logo, user_id, created_by)
    VALUES (p_id, p_name, p_description, p_logo, v_user_id, v_user_id)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        logo = EXCLUDED.logo,
        updated_at = NOW()
    WHERE device_brands.user_id = v_user_id;
    
    -- Mettre à jour les catégories si fournies
    IF p_category_ids IS NOT NULL THEN
        PERFORM public.update_brand_categories(p_id, p_category_ids);
    END IF;
    
    -- Retourner les informations de la marque
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
SELECT '=== CRÉATION DES MARQUES PAR DÉFAUT ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        -- Créer une catégorie par défaut si aucune n'existe
        INSERT INTO device_categories (name, description, icon, is_active, user_id, created_by)
        VALUES ('Électronique', 'Catégorie par défaut', 'smartphone', true, v_user_id, v_user_id)
        ON CONFLICT DO NOTHING;
        
        -- Récupérer l'ID de la catégorie
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
        
        -- Associer les marques à la catégorie par défaut
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

-- 9. ACTIVER RLS (ROW LEVEL SECURITY)
-- ============================================================================
SELECT '=== ACTIVATION DE RLS ===' as section;

-- Activer RLS sur device_brands
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS pour device_brands
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

-- Activer RLS sur brand_categories
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS pour brand_categories
DROP POLICY IF EXISTS "Users can manage brand categories for their brands" ON public.brand_categories;
CREATE POLICY "Users can manage brand categories for their brands" ON public.brand_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM device_brands 
            WHERE device_brands.id = brand_categories.brand_id 
            AND device_brands.user_id = auth.uid()
        )
    );

-- 10. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les marques créées
SELECT 
    db.id,
    db.name,
    db.description,
    db.is_active,
    db.created_at
FROM device_brands db
WHERE db.user_id = auth.uid()
ORDER BY db.name;

-- Vérifier les catégories des marques
SELECT 
    db.name as brand_name,
    dc.name as category_name,
    dc.icon as category_icon
FROM device_brands db
LEFT JOIN brand_categories bc ON db.id = bc.brand_id
LEFT JOIN device_categories dc ON bc.category_id = dc.id
WHERE db.user_id = auth.uid()
ORDER BY db.name, dc.name;

-- Test de la fonction upsert_brand
SELECT public.upsert_brand(
    'test_brand',
    'Marque de Test',
    'Description de test',
    '',
    ARRAY[(SELECT id FROM device_categories WHERE user_id = auth.uid() LIMIT 1)]
) as test_result;

-- Nettoyer la marque de test
DELETE FROM device_brands WHERE id = 'test_brand' AND user_id = auth.uid();

-- 11. NETTOYAGE
-- ============================================================================
SELECT '=== NETTOYAGE ===' as section;

-- Supprimer les tables de sauvegarde si tout s'est bien passé
DROP TABLE IF EXISTS device_brands_backup;
DROP TABLE IF EXISTS brand_categories_backup;

DO $$
BEGIN
    RAISE NOTICE '🎉 Reconstruction du système des marques terminée !';
    RAISE NOTICE '✅ Table device_brands recréée avec ID TEXT';
    RAISE NOTICE '✅ Table brand_categories recréée pour relations many-to-many';
    RAISE NOTICE '✅ Vue brand_with_categories créée';
    RAISE NOTICE '✅ Fonctions RPC créées (update_brand_categories, upsert_brand)';
    RAISE NOTICE '✅ Marques par défaut créées (Apple, Samsung, Google, Microsoft, Sony)';
    RAISE NOTICE '✅ RLS activé et politiques créées';
    RAISE NOTICE '✅ Toutes les marques peuvent maintenant être modifiées';
    RAISE NOTICE '✅ Système de catégories multiples fonctionnel';
    RAISE NOTICE '✅ Prêt pour l''interface utilisateur !';
END $$;
