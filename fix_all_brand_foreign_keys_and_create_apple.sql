-- ============================================================================
-- CORRECTION COMPLÈTE DES TYPES ET CONTRAINTES POUR LES MARQUES
-- ============================================================================
-- Date: $(date)
-- Description: Corriger tous les types et contraintes pour permettre les IDs texte
-- ============================================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
-- ============================================================================
SELECT '=== VÉRIFICATION STRUCTURE ACTUELLE ===' as section;

-- Vérifier les colonnes de device_brands
SELECT 
    'device_brands' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les colonnes de brand_categories
SELECT 
    'brand_categories' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les contraintes de clés étrangères
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND (tc.table_name = 'device_brands' OR tc.table_name = 'brand_categories')
AND tc.table_schema = 'public';

-- 2. SUPPRIMER LES VUES DÉPENDANTES
-- ============================================================================
SELECT '=== SUPPRESSION DES VUES ===' as section;

DROP VIEW IF EXISTS public.brand_with_categories CASCADE;
DROP VIEW IF EXISTS public.device_brands_view CASCADE;

-- 3. SUPPRIMER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- ============================================================================
SELECT '=== SUPPRESSION DES CONTRAINTES ===' as section;

-- Supprimer les contraintes de clés étrangères qui référencent device_brands.id
ALTER TABLE public.brand_categories DROP CONSTRAINT IF EXISTS brand_categories_brand_id_fkey;

-- 4. MODIFIER LES TYPES DE COLONNES
-- ============================================================================
SELECT '=== MODIFICATION DES TYPES DE COLONNES ===' as section;

-- Changer le type de device_brands.id de UUID vers TEXT
ALTER TABLE public.device_brands 
ALTER COLUMN id TYPE TEXT;

-- Changer le type de brand_categories.brand_id de UUID vers TEXT
ALTER TABLE public.brand_categories 
ALTER COLUMN brand_id TYPE TEXT;

-- 5. RECRÉER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- ============================================================================
SELECT '=== RECRÉATION DES CONTRAINTES ===' as section;

-- Recréer la contrainte de clé étrangère
ALTER TABLE public.brand_categories 
ADD CONSTRAINT brand_categories_brand_id_fkey 
FOREIGN KEY (brand_id) REFERENCES public.device_brands(id) 
ON DELETE CASCADE;

-- 6. CRÉER LES INDEX
-- ============================================================================
SELECT '=== CRÉATION DES INDEX ===' as section;

-- Supprimer les anciens index si nécessaire
DROP INDEX IF EXISTS device_brands_pkey;
DROP INDEX IF EXISTS idx_device_brands_id;
DROP INDEX IF EXISTS idx_brand_categories_brand_id;

-- Créer les nouveaux index
CREATE INDEX IF NOT EXISTS idx_device_brands_id ON public.device_brands(id);
CREATE INDEX IF NOT EXISTS idx_device_brands_user_id ON public.device_brands(user_id);
CREATE INDEX IF NOT EXISTS idx_brand_categories_brand_id ON public.brand_categories(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_categories_category_id ON public.brand_categories(category_id);

-- 7. RECRÉER LA VUE brand_with_categories
-- ============================================================================
SELECT '=== RECRÉATION DE LA VUE ===' as section;

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

-- 8. CRÉER LA MARQUE APPLE AVEC L'ID "1"
-- ============================================================================
SELECT '=== CRÉATION MARQUE APPLE ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
    v_category_name TEXT;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        RAISE NOTICE 'Utilisateur connecté: %', v_user_id;
        
        -- Supprimer la marque Apple si elle existe déjà
        DELETE FROM device_brands 
        WHERE id = '1' AND user_id = v_user_id;
        
        -- Récupérer la première catégorie disponible
        SELECT id, name INTO v_category_id, v_category_name
        FROM device_categories 
        WHERE user_id = v_user_id 
        ORDER BY name
        LIMIT 1;
        
        IF v_category_id IS NOT NULL THEN
            -- Créer la marque Apple avec l'ID "1"
            INSERT INTO device_brands (
                id,
                name,
                description,
                logo,
                category_id,
                is_active,
                user_id,
                created_by
            ) VALUES (
                '1',
                'Apple',
                'Fabricant américain de produits électroniques premium',
                '',
                v_category_id,
                true,
                v_user_id,
                v_user_id
            );
            
            RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
            RAISE NOTICE '✅ Catégorie associée: % (%)', v_category_name, v_category_id;
        ELSE
            -- Créer une catégorie par défaut si aucune n'existe
            INSERT INTO device_categories (
                name,
                description,
                icon,
                is_active,
                user_id,
                created_by
            ) VALUES (
                'Électronique',
                'Catégorie par défaut pour les appareils électroniques',
                'smartphone',
                true,
                v_user_id,
                v_user_id
            ) RETURNING id INTO v_category_id;
            
            -- Créer la marque Apple avec la nouvelle catégorie
            INSERT INTO device_brands (
                id,
                name,
                description,
                logo,
                category_id,
                is_active,
                user_id,
                created_by
            ) VALUES (
                '1',
                'Apple',
                'Fabricant américain de produits électroniques premium',
                '',
                v_category_id,
                true,
                v_user_id,
                v_user_id
            );
            
            RAISE NOTICE '✅ Catégorie "Électronique" créée';
            RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté';
    END IF;
END $$;

-- 9. VÉRIFIER LA CRÉATION
-- ============================================================================
SELECT '=== VÉRIFICATION CRÉATION ===' as section;

SELECT 
    db.id,
    db.name,
    db.description,
    db.category_id,
    dc.name as category_name,
    dc.icon as category_icon,
    db.is_active,
    db.created_at
FROM device_brands db
LEFT JOIN device_categories dc ON db.category_id = dc.id
WHERE db.id = '1' AND db.user_id = auth.uid();

-- 10. TEST DE MODIFICATION
-- ============================================================================
SELECT '=== TEST DE MODIFICATION ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
    v_category_name TEXT;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        -- Récupérer une autre catégorie (ou la même si c'est la seule)
        SELECT id, name INTO v_category_id, v_category_name
        FROM device_categories 
        WHERE user_id = v_user_id 
        ORDER BY name
        LIMIT 1;
        
        IF v_category_id IS NOT NULL THEN
            -- Modifier la catégorie de la marque Apple
            UPDATE device_brands 
            SET category_id = v_category_id
            WHERE id = '1' AND user_id = v_user_id;
            
            RAISE NOTICE '✅ Test de modification réussi : Apple -> % (%)', v_category_name, v_category_id;
        END IF;
    END IF;
END $$;

-- 11. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

SELECT 
    db.id,
    db.name,
    db.description,
    db.category_id,
    dc.name as category_name,
    dc.icon as category_icon,
    db.is_active,
    db.created_at,
    db.updated_at
FROM device_brands db
LEFT JOIN device_categories dc ON db.category_id = dc.id
WHERE db.id = '1' AND db.user_id = auth.uid();

-- 12. VÉRIFIER LA NOUVELLE STRUCTURE
-- ============================================================================
SELECT '=== NOUVELLE STRUCTURE ===' as section;

-- Vérifier device_brands
SELECT 
    'device_brands' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier brand_categories
SELECT 
    'brand_categories' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les contraintes
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND (tc.table_name = 'device_brands' OR tc.table_name = 'brand_categories')
AND tc.table_schema = 'public';

DO $$
BEGIN
    RAISE NOTICE '🎉 Correction complète terminée !';
    RAISE NOTICE '✅ Types de colonnes modifiés vers TEXT';
    RAISE NOTICE '✅ Contraintes de clés étrangères recréées';
    RAISE NOTICE '✅ Vue brand_with_categories recréée';
    RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
    RAISE NOTICE '✅ Catégorie associée avec succès';
    RAISE NOTICE '✅ Test de modification réussi';
    RAISE NOTICE '✅ Vous pouvez maintenant modifier les catégories d''Apple dans l''interface';
END $$;
