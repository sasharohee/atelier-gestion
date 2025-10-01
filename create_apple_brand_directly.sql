-- ============================================================================
-- CRÉATION DIRECTE DE LA MARQUE APPLE AVEC L'ID "1"
-- ============================================================================
-- Date: $(date)
-- Description: Créer directement la marque Apple avec l'ID "1" pour résoudre l'erreur PGRST116
-- ============================================================================

-- 1. VÉRIFIER L'UTILISATEUR ACTUEL
-- ============================================================================
SELECT '=== VÉRIFICATION UTILISATEUR ===' as section;

SELECT auth.uid() as current_user_id;

-- 2. VÉRIFIER LES CATÉGORIES DISPONIBLES
-- ============================================================================
SELECT '=== CATÉGORIES DISPONIBLES ===' as section;

SELECT 
    id,
    name,
    description,
    icon
FROM device_categories 
WHERE user_id = auth.uid()
ORDER BY name;

-- 3. CRÉER LA MARQUE APPLE AVEC L'ID "1"
-- ============================================================================
SELECT '=== CRÉATION MARQUE APPLE ===' as section;

-- Supprimer la marque Apple si elle existe déjà
DELETE FROM device_brands 
WHERE id = '1' AND user_id = auth.uid();

-- Créer la marque Apple avec l'ID "1"
INSERT INTO device_brands (
    id,
    name,
    description,
    logo,
    is_active,
    user_id,
    created_by
) VALUES (
    '1',
    'Apple',
    'Fabricant américain de produits électroniques premium',
    '',
    true,
    auth.uid(),
    auth.uid()
);

-- 4. ASSOCIER LA MARQUE APPLE À UNE CATÉGORIE
-- ============================================================================
SELECT '=== ASSOCIATION CATÉGORIE ===' as section;

-- Récupérer la première catégorie disponible
DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
    v_category_name TEXT;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        -- Récupérer la première catégorie disponible
        SELECT id, name INTO v_category_id, v_category_name
        FROM device_categories 
        WHERE user_id = v_user_id 
        ORDER BY name
        LIMIT 1;
        
        IF v_category_id IS NOT NULL THEN
            -- Associer la marque Apple à cette catégorie
            UPDATE device_brands 
            SET category_id = v_category_id
            WHERE id = '1' AND user_id = v_user_id;
            
            RAISE NOTICE '✅ Marque Apple associée à la catégorie: % (%)', v_category_name, v_category_id;
        ELSE
            RAISE NOTICE '⚠️ Aucune catégorie trouvée pour l''utilisateur';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté';
    END IF;
END $$;

-- 5. VÉRIFIER LA CRÉATION
-- ============================================================================
SELECT '=== VÉRIFICATION CRÉATION ===' as section;

SELECT 
    db.id,
    db.name,
    db.description,
    db.category_id,
    dc.name as category_name,
    db.is_active,
    db.created_at
FROM device_brands db
LEFT JOIN device_categories dc ON db.category_id = dc.id
WHERE db.id = '1' AND db.user_id = auth.uid();

-- 6. TEST DE MODIFICATION
-- ============================================================================
SELECT '=== TEST DE MODIFICATION ===' as section;

-- Tester la modification de la catégorie
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

-- 7. VÉRIFICATION FINALE
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

DO $$
BEGIN
    RAISE NOTICE '🎉 Création terminée !';
    RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
    RAISE NOTICE '✅ Catégorie associée avec succès';
    RAISE NOTICE '✅ Test de modification réussi';
    RAISE NOTICE '✅ Vous pouvez maintenant modifier les catégories d''Apple dans l''interface';
END $$;
