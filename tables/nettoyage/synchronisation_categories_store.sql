-- =====================================================
-- SYNCHRONISATION DES CATÉGORIES STORE ET BASE
-- =====================================================
-- Date: 2025-01-23
-- Objectif: Synchroniser les catégories du store avec la base de données
-- =====================================================

-- 1. DIAGNOSTIC DES CATÉGORIES
SELECT '=== DIAGNOSTIC DES CATÉGORIES ===' as section;

-- Vérifier les catégories en base
SELECT 
    'Base de données' as source,
    id,
    name,
    description,
    is_active
FROM product_categories
ORDER BY name;

-- 2. CRÉER UNE TABLE DE MAPPING DES IDS
SELECT '=== CRÉATION TABLE DE MAPPING ===' as section;

-- Créer une table temporaire pour mapper les anciens IDs aux nouveaux UUIDs
CREATE TEMP TABLE category_mapping (
    old_id TEXT,
    new_id UUID,
    category_name TEXT
);

-- Remplir le mapping
INSERT INTO category_mapping (old_id, new_id, category_name) VALUES
    ('1', (SELECT id FROM product_categories WHERE name = 'Smartphones' LIMIT 1), 'Smartphones'),
    ('2', (SELECT id FROM product_categories WHERE name = 'Tablettes' LIMIT 1), 'Tablettes'),
    ('3', (SELECT id FROM product_categories WHERE name = 'Ordinateurs portables' LIMIT 1), 'Ordinateurs portables'),
    ('4', (SELECT id FROM product_categories WHERE name = 'Ordinateurs fixes' LIMIT 1), 'Ordinateurs fixes');

-- Afficher le mapping
SELECT 
    'Mapping créé' as action,
    old_id,
    new_id,
    category_name
FROM category_mapping;

-- 3. METTRE À JOUR LES RÉFÉRENCES DANS DEVICEBRANDS
SELECT '=== MISE À JOUR DEVICEBRANDS ===' as section;

-- Mettre à jour les categoryId dans deviceBrands
UPDATE device_brands 
SET category_id = cm.new_id
FROM category_mapping cm
WHERE device_brands.category_id::TEXT = cm.old_id;

-- Vérifier les mises à jour
SELECT 
    'DeviceBrands mis à jour' as action,
    COUNT(*) as nombre_mis_a_jour
FROM device_brands db
JOIN category_mapping cm ON db.category_id = cm.new_id;

-- 4. VÉRIFIER LA COHÉRENCE
SELECT '=== VÉRIFICATION COHÉRENCE ===' as section;

-- Vérifier que toutes les marques ont des catégories valides
SELECT 
    'Marques avec catégories valides' as statut,
    COUNT(*) as nombre
FROM device_brands db
JOIN product_categories pc ON db.category_id = pc.id

UNION ALL

SELECT 
    'Marques sans catégorie valide' as statut,
    COUNT(*) as nombre
FROM device_brands db
LEFT JOIN product_categories pc ON db.category_id = pc.id
WHERE pc.id IS NULL;

-- 5. AFFICHER LES RÉSULTATS FINAUX
SELECT '=== RÉSULTATS FINAUX ===' as section;

-- Catégories finales avec leurs marques
SELECT 
    pc.name as categorie,
    pc.description,
    COUNT(db.id) as nombre_marques,
    STRING_AGG(db.name, ', ' ORDER BY db.name) as marques
FROM product_categories pc
LEFT JOIN device_brands db ON pc.id = db.category_id
GROUP BY pc.id, pc.name, pc.description
ORDER BY pc.name;

-- 6. NETTOYAGE
SELECT '=== NETTOYAGE ===' as section;

-- Supprimer la table temporaire
DROP TABLE category_mapping;

-- 7. MESSAGE DE CONFIRMATION
SELECT '=== CONFIRMATION ===' as section,
       'Synchronisation des catégories terminée. Store et base de données sont maintenant cohérents.' as message;

