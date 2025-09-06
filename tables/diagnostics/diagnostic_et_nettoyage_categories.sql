-- =====================================================
-- DIAGNOSTIC ET NETTOYAGE DES CATÉGORIES
-- =====================================================
-- Date: 2025-01-23
-- Objectif: Diagnostiquer et nettoyer les problèmes avant création des catégories par défaut
-- =====================================================

-- 1. DIAGNOSTIC INITIAL
SELECT '=== DIAGNOSTIC INITIAL ===' as section;

-- Vérifier l'état de la table product_categories
SELECT 
    'product_categories' as table_name,
    COUNT(*) as total_categories,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as categories_sans_user,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 1 END) as categories_user_zero,
    COUNT(CASE WHEN user_id NOT IN (SELECT id FROM auth.users) THEN 1 END) as categories_user_invalide
FROM product_categories;

-- 2. IDENTIFIER LES UTILISATEURS PROBLÉMATIQUES
SELECT '=== UTILISATEURS PROBLÉMATIQUES ===' as section;

-- Utilisateurs avec des catégories mais qui n'existent plus
SELECT 
    pc.user_id,
    COUNT(pc.id) as nombre_categories,
    STRING_AGG(pc.name, ', ' ORDER BY pc.name) as categories
FROM product_categories pc
WHERE pc.user_id NOT IN (SELECT id FROM auth.users)
GROUP BY pc.user_id;

-- 3. VÉRIFIER LES CONTRAINTES UNIQUES
SELECT '=== CONTRAINTES UNIQUES ===' as section;

-- Voir les contraintes existantes
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name as referenced_table,
    ccu.column_name as referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'product_categories'
ORDER BY tc.constraint_name;

-- 4. IDENTIFIER LES DOUBLONS POTENTIELS
SELECT '=== DOUBLONS POTENTIELS ===' as section;

-- Catégories avec le même nom pour le même utilisateur
SELECT 
    user_id,
    name,
    COUNT(*) as occurrences,
    STRING_AGG(id::text, ', ' ORDER BY created_at) as ids
FROM product_categories
GROUP BY user_id, name
HAVING COUNT(*) > 1
ORDER BY user_id, name;

-- 5. NETTOYAGE DES DONNÉES PROBLÉMATIQUES
SELECT '=== NETTOYAGE DES DONNÉES ===' as section;

-- Supprimer les catégories avec user_id NULL ou invalide
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Supprimer les catégories avec user_id NULL
    DELETE FROM product_categories WHERE user_id IS NULL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '🗑️ % catégories avec user_id NULL supprimées', deleted_count;
    
    -- Supprimer les catégories avec user_id = 00000000-0000-0000-0000-000000000000
    DELETE FROM product_categories 
    WHERE user_id = '00000000-0000-0000-0000-000000000000'::UUID;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '🗑️ % catégories avec user_id zero supprimées', deleted_count;
    
    -- Supprimer les catégories avec des utilisateurs inexistants
    DELETE FROM product_categories 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '🗑️ % catégories avec utilisateurs inexistants supprimées', deleted_count;
END $$;

-- 6. RÉSOLUTION DES DOUBLONS
DO $$
DECLARE
    duplicate_record RECORD;
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔄 Résolution des doublons...';
    
    FOR duplicate_record IN 
        SELECT user_id, name, COUNT(*) as occurrences
        FROM product_categories
        GROUP BY user_id, name
        HAVING COUNT(*) > 1
    LOOP
        -- Garder la catégorie la plus récente, supprimer les autres
        DELETE FROM product_categories 
        WHERE user_id = duplicate_record.user_id 
          AND name = duplicate_record.name
          AND id NOT IN (
              SELECT id FROM product_categories 
              WHERE user_id = duplicate_record.user_id 
                AND name = duplicate_record.name
              ORDER BY created_at DESC 
              LIMIT 1
          );
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '🗑️ % doublons supprimés pour % - %', 
            deleted_count, duplicate_record.user_id, duplicate_record.name;
    END LOOP;
    
    RAISE NOTICE '✅ Résolution des doublons terminée';
END $$;

-- 7. VÉRIFICATION POST-NETTOYAGE
SELECT '=== VÉRIFICATION POST-NETTOYAGE ===' as section;

-- Vérifier l'état après nettoyage
SELECT 
    'product_categories (après nettoyage)' as table_name,
    COUNT(*) as total_categories,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as categories_sans_user,
    COUNT(CASE WHEN user_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 1 END) as categories_user_zero,
    COUNT(CASE WHEN user_id NOT IN (SELECT id FROM auth.users) THEN 1 END) as categories_user_invalide
FROM product_categories;

-- 8. STATISTIQUES PAR UTILISATEUR
SELECT '=== STATISTIQUES PAR UTILISATEUR ===' as section;

SELECT 
    u.email,
    COUNT(pc.id) as nombre_categories,
    STRING_AGG(pc.name, ', ' ORDER BY pc.name) as categories_presentes
FROM auth.users u
LEFT JOIN product_categories pc ON u.id = pc.user_id
GROUP BY u.id, u.email
ORDER BY u.email;

-- 9. MESSAGE DE CONFIRMATION
SELECT '=== CONFIRMATION ===' as section,
       'Le diagnostic et le nettoyage sont terminés. Vous pouvez maintenant exécuter le script de création des catégories par défaut.' as message;

