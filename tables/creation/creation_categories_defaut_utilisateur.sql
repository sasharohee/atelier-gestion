-- =====================================================
-- CRÉATION AUTOMATIQUE DES CATÉGORIES PAR DÉFAUT
-- =====================================================
-- Date: 2025-01-23
-- Objectif: Créer automatiquement les 4 catégories par défaut pour chaque utilisateur
-- =====================================================

-- 1. FONCTION POUR CRÉER LES CATÉGORIES PAR DÉFAUT
CREATE OR REPLACE FUNCTION create_default_categories_for_user(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    category_exists BOOLEAN;
BEGIN
    -- Vérifier et créer la catégorie "Smartphones"
    SELECT EXISTS(
        SELECT 1 FROM product_categories 
        WHERE user_id = p_user_id AND name = 'Smartphones'
    ) INTO category_exists;
    
    IF NOT category_exists THEN
        INSERT INTO product_categories (
            id, user_id, name, description, icon, is_active, created_at, updated_at
        ) VALUES (
            gen_random_uuid(), p_user_id, 'Smartphones', 
            'Téléphones mobiles et smartphones', 'smartphone', true, NOW(), NOW()
        );
        RAISE NOTICE '✅ Catégorie "Smartphones" créée pour l''utilisateur %', p_user_id;
    ELSE
        RAISE NOTICE 'ℹ️ Catégorie "Smartphones" existe déjà pour l''utilisateur %', p_user_id;
    END IF;

    -- Vérifier et créer la catégorie "Tablettes"
    SELECT EXISTS(
        SELECT 1 FROM product_categories 
        WHERE user_id = p_user_id AND name = 'Tablettes'
    ) INTO category_exists;
    
    IF NOT category_exists THEN
        INSERT INTO product_categories (
            id, user_id, name, description, icon, is_active, created_at, updated_at
        ) VALUES (
            gen_random_uuid(), p_user_id, 'Tablettes', 
            'Tablettes tactiles', 'tablet', true, NOW(), NOW()
        );
        RAISE NOTICE '✅ Catégorie "Tablettes" créée pour l''utilisateur %', p_user_id;
    ELSE
        RAISE NOTICE 'ℹ️ Catégorie "Tablettes" existe déjà pour l''utilisateur %', p_user_id;
    END IF;

    -- Vérifier et créer la catégorie "Ordinateurs portables"
    SELECT EXISTS(
        SELECT 1 FROM product_categories 
        WHERE user_id = p_user_id AND name = 'Ordinateurs portables'
    ) INTO category_exists;
    
    IF NOT category_exists THEN
        INSERT INTO product_categories (
            id, user_id, name, description, icon, is_active, created_at, updated_at
        ) VALUES (
            gen_random_uuid(), p_user_id, 'Ordinateurs portables', 
            'Laptops et notebooks', 'laptop', true, NOW(), NOW()
        );
        RAISE NOTICE '✅ Catégorie "Ordinateurs portables" créée pour l''utilisateur %', p_user_id;
    ELSE
        RAISE NOTICE 'ℹ️ Catégorie "Ordinateurs portables" existe déjà pour l''utilisateur %', p_user_id;
    END IF;

    -- Vérifier et créer la catégorie "Ordinateurs fixes"
    SELECT EXISTS(
        SELECT 1 FROM product_categories 
        WHERE user_id = p_user_id AND name = 'Ordinateurs fixes'
    ) INTO category_exists;
    
    IF NOT category_exists THEN
        INSERT INTO product_categories (
            id, user_id, name, description, icon, is_active, created_at, updated_at
        ) VALUES (
            gen_random_uuid(), p_user_id, 'Ordinateurs fixes', 
            'PC de bureau et stations de travail', 'desktop', true, NOW(), NOW()
        );
        RAISE NOTICE '✅ Catégorie "Ordinateurs fixes" créée pour l''utilisateur %', p_user_id;
    ELSE
        RAISE NOTICE 'ℹ️ Catégorie "Ordinateurs fixes" existe déjà pour l''utilisateur %', p_user_id;
    END IF;

    RAISE NOTICE '🎉 Création des catégories par défaut terminée pour l''utilisateur %', p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. TRIGGER POUR CRÉER AUTOMATIQUEMENT LES CATÉGORIES
CREATE OR REPLACE FUNCTION trigger_create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer les catégories par défaut pour le nouvel utilisateur
    PERFORM create_default_categories_for_user(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CRÉER LE TRIGGER SUR LA TABLE users
DROP TRIGGER IF EXISTS create_default_categories_trigger ON auth.users;
CREATE TRIGGER create_default_categories_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_categories();

-- 4. NETTOYER LES DONNÉES ORPHELINES AVANT CRÉATION
DO $$
DECLARE
    orphaned_count INTEGER;
BEGIN
    RAISE NOTICE '🧹 Nettoyage des données orphelines...';
    
    -- Supprimer les catégories avec user_id invalide ou NULL
    DELETE FROM product_categories 
    WHERE user_id IS NULL 
       OR user_id = '00000000-0000-0000-0000-000000000000'::UUID
       OR user_id NOT IN (SELECT id FROM auth.users);
    
    GET DIAGNOSTICS orphaned_count = ROW_COUNT;
    RAISE NOTICE '🗑️ % catégories orphelines supprimées', orphaned_count;
END $$;

-- 5. CRÉER LES CATÉGORIES POUR LES UTILISATEURS EXISTANTS
DO $$
DECLARE
    user_record RECORD;
    success_count INTEGER := 0;
    error_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔄 Création des catégories par défaut pour les utilisateurs existants...';
    
    FOR user_record IN SELECT id FROM auth.users LOOP
        BEGIN
            PERFORM create_default_categories_for_user(user_record.id);
            success_count := success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                error_count := error_count + 1;
                RAISE NOTICE '⚠️ Erreur pour l''utilisateur %: %', user_record.id, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ % utilisateurs traités avec succès, % erreurs', success_count, error_count;
END $$;

-- 6. VÉRIFICATION
SELECT '=== VÉRIFICATION DES CATÉGORIES PAR DÉFAUT ===' as section;

SELECT 
    u.email,
    COUNT(pc.id) as nombre_categories,
    STRING_AGG(pc.name, ', ' ORDER BY pc.name) as categories_presentes
FROM auth.users u
LEFT JOIN product_categories pc ON u.id = pc.user_id
GROUP BY u.id, u.email
ORDER BY u.email;

-- 7. DONNER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION create_default_categories_for_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_categories_for_user(UUID) TO anon;

-- 8. MESSAGE DE CONFIRMATION
SELECT '=== CONFIRMATION ===' as section,
       'Les catégories par défaut sont maintenant créées automatiquement pour chaque utilisateur.' as message;
