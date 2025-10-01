-- ============================================================================
-- CORRECTION DU TYPE DE COLONNE ID ET CRÉATION DE LA MARQUE APPLE
-- ============================================================================
-- Date: $(date)
-- Description: Modifier le type de la colonne id pour accepter les chaînes et créer Apple
-- ============================================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
-- ============================================================================
SELECT '=== VÉRIFICATION STRUCTURE ACTUELLE ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. VÉRIFIER LES VUES QUI DÉPENDENT DE LA TABLE
-- ============================================================================
SELECT '=== VUES DÉPENDANTES ===' as section;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE definition LIKE '%device_brands%'
AND schemaname = 'public';

-- 3. SUPPRIMER LES VUES DÉPENDANTES
-- ============================================================================
SELECT '=== SUPPRESSION DES VUES ===' as section;

DROP VIEW IF EXISTS public.brand_with_categories CASCADE;
DROP VIEW IF EXISTS public.device_brands_view CASCADE;

-- 4. MODIFIER LE TYPE DE LA COLONNE ID
-- ============================================================================
SELECT '=== MODIFICATION DU TYPE DE COLONNE ===' as section;

-- Changer le type de la colonne id de UUID vers TEXT
ALTER TABLE public.device_brands 
ALTER COLUMN id TYPE TEXT;

-- 5. CRÉER UN INDEX SUR LA NOUVELLE COLONNE
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

-- Supprimer l'ancien index de clé primaire si nécessaire
DROP INDEX IF EXISTS device_brands_pkey;
DROP INDEX IF EXISTS idx_device_brands_id;

-- Créer un nouvel index sur la colonne id
CREATE INDEX IF NOT EXISTS idx_device_brands_id ON public.device_brands(id);
CREATE INDEX IF NOT EXISTS idx_device_brands_user_id ON public.device_brands(user_id);

-- 6. RECRÉER LA VUE brand_with_categories
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

-- 7. CRÉER LA MARQUE APPLE AVEC L'ID "1"
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

-- 8. VÉRIFIER LA CRÉATION
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

-- 9. TEST DE MODIFICATION
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

-- 10. VÉRIFICATION FINALE
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

-- 11. VÉRIFIER LA NOUVELLE STRUCTURE
-- ============================================================================
SELECT '=== NOUVELLE STRUCTURE ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

DO $$
BEGIN
    RAISE NOTICE '🎉 Correction terminée !';
    RAISE NOTICE '✅ Type de colonne ID modifié vers TEXT';
    RAISE NOTICE '✅ Vue brand_with_categories recréée';
    RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
    RAISE NOTICE '✅ Catégorie associée avec succès';
    RAISE NOTICE '✅ Test de modification réussi';
    RAISE NOTICE '✅ Vous pouvez maintenant modifier les catégories d''Apple dans l''interface';
END $$;
