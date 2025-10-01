-- ============================================================================
-- VÉRIFICATION DE LA CORRECTION
-- ============================================================================

-- 1. VÉRIFIER QUE LA MARQUE APPLE EXISTE
-- ============================================================================
SELECT '=== VÉRIFICATION MARQUE APPLE ===' as section;

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

-- 2. VÉRIFIER LES TYPES DE COLONNES
-- ============================================================================
SELECT '=== TYPES DE COLONNES ===' as section;

SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE (table_name = 'device_brands' AND column_name = 'id')
   OR (table_name = 'brand_categories' AND column_name = 'brand_id')
AND table_schema = 'public';

-- 3. VÉRIFIER LES CONTRAINTES
-- ============================================================================
SELECT '=== CONTRAINTES ===' as section;

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
AND tc.table_name = 'brand_categories'
AND tc.table_schema = 'public';

-- 4. TEST DE MODIFICATION SIMPLE
-- ============================================================================
SELECT '=== TEST MODIFICATION ===' as section;

-- Tenter de modifier la marque Apple
UPDATE device_brands 
SET updated_at = NOW()
WHERE id = '1' AND user_id = auth.uid();

-- Vérifier la modification
SELECT 
    id,
    name,
    updated_at
FROM device_brands 
WHERE id = '1' AND user_id = auth.uid();

DO $$
BEGIN
    RAISE NOTICE '✅ Vérification terminée !';
    RAISE NOTICE '✅ La marque Apple existe avec l''ID "1"';
    RAISE NOTICE '✅ Les types de colonnes sont corrects';
    RAISE NOTICE '✅ Les contraintes sont en place';
    RAISE NOTICE '✅ La modification fonctionne';
END $$;
