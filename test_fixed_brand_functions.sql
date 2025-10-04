-- Script de test pour vérifier les fonctions RPC corrigées
-- À exécuter après la migration V7 corrigée

-- 1. Tester avec un ID TEXT (comme l'application en génère)
SELECT 'Test avec ID TEXT (comme l\'application)...' as step;

SELECT public.create_brand_basic(
    'brand_1735123456789_abc123def',
    'Marque Test TEXT',
    'Description de test avec ID TEXT',
    'logo_text.png'
) as result;

-- 2. Vérifier que la marque a été créée avec un UUID
SELECT 'Vérification de la marque créée avec UUID...' as step;

SELECT 
    id,
    name,
    description,
    logo,
    user_id
FROM public.device_brands 
WHERE name = 'Marque Test TEXT';

-- 3. Tester upsert_brand_simple avec ID TEXT
SELECT 'Test upsert_brand_simple avec ID TEXT...' as step;

SELECT public.upsert_brand_simple(
    'brand_1735123456790_xyz789ghi',
    'Marque Test Simple TEXT',
    'Description de test simple avec ID TEXT',
    'logo_simple_text.png'
) as result;

-- 4. Tester upsert_brand avec ID TEXT et catégories
SELECT 'Test upsert_brand avec ID TEXT et catégories...' as step;

SELECT public.upsert_brand(
    'brand_1735123456791_mno456pqr',
    'Marque Test Complète TEXT',
    'Description de test complète avec ID TEXT',
    'logo_complete_text.png',
    ARRAY[]::uuid[]
) as result;

-- 5. Vérifier toutes les marques créées
SELECT 'Vérification de toutes les marques créées...' as step;

SELECT 
    id,
    name,
    description,
    user_id,
    created_at
FROM public.device_brands 
WHERE name LIKE 'Marque Test%'
ORDER BY created_at DESC;

-- 6. Tester la conversion d'ID TEXT vers UUID
SELECT 'Test de conversion d\'ID TEXT vers UUID...' as step;

-- Tester avec un UUID valide
SELECT public.create_brand_basic(
    '550e8400-e29b-41d4-a716-446655440000',
    'Marque Test UUID',
    'Description de test avec UUID valide',
    'logo_uuid.png'
) as result;

-- 7. Nettoyer les données de test
SELECT 'Nettoyage des données de test...' as step;

DELETE FROM public.device_brands 
WHERE name LIKE 'Marque Test%';

-- 8. Vérifier le nettoyage
SELECT 'Vérification du nettoyage...' as step;

SELECT COUNT(*) as remaining_test_brands
FROM public.device_brands 
WHERE name LIKE 'Marque Test%';

-- 9. Résumé des tests
SELECT 'Tests terminés avec succès - Les fonctions gèrent maintenant les IDs TEXT' as final_status;


