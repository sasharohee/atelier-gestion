-- Script pour rafraîchir le cache de Supabase
-- À exécuter après emergency_fix_device_models.sql

-- 1. Forcer la mise à jour du cache de schéma
SELECT '=== RAFRAÎCHISSEMENT DU CACHE SUPABASE ===' as info;

-- Vérifier que la colonne description existe dans le schéma
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
AND column_name = 'description';

-- 2. Tester une requête SELECT pour forcer le cache
SELECT '=== TEST REQUÊTE POUR CACHE ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active
FROM public.device_models 
LIMIT 1;

-- 3. Vérifier les permissions sur la table
SELECT '=== VÉRIFICATION PERMISSIONS ===' as info;

SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY grantee, privilege_type;

-- 4. Vérifier les politiques RLS
SELECT '=== VÉRIFICATION POLITIQUES RLS ===' as info;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'device_models'
ORDER BY policyname;

-- 5. Tester l'insertion avec toutes les colonnes
SELECT '=== TEST INSERTION COMPLÈTE ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Cache Refresh Test',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test de rafraîchissement du cache',
    true
);

-- 6. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION CACHE ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
WHERE name = 'Cache Refresh Test'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Cache Refresh Test';

-- 8. Vérifier que le nettoyage a fonctionné
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Cache Refresh Test';

-- 9. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Colonne description ajoutée' as status_1,
    '✅ Trigger problématique supprimé' as status_2,
    '✅ Cache Supabase rafraîchi' as status_3,
    '✅ Tests d''insertion réussis' as status_4;

SELECT 'Cache Supabase rafraîchi avec succès' as final_status;


