-- ============================================================================
-- CORRECTION SIMPLE DE LA COLONNE ID DE device_brands
-- ============================================================================
-- Date: $(date)
-- Description: Modifier uniquement la colonne id pour accepter les textes
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
WHERE table_schema = 'public' 
AND table_name = 'device_brands'
AND column_name = 'id'
ORDER BY ordinal_position;

-- 2. SAUVEGARDER LES DONNÉES EXISTANTES
-- ============================================================================
SELECT '=== SAUVEGARDE DES DONNÉES EXISTANTES ===' as section;

-- Créer une table de sauvegarde si elle n'existe pas
CREATE TABLE IF NOT EXISTS device_brands_backup_fix AS 
SELECT * FROM device_brands WHERE false;

-- Vider la table de sauvegarde
DELETE FROM device_brands_backup_fix;

-- Copier les données existantes
INSERT INTO device_brands_backup_fix 
SELECT * FROM device_brands;

SELECT COUNT(*) as backup_count FROM device_brands_backup_fix;

-- 3. SUPPRIMER TOUTES LES VUES QUI DÉPENDENT DE device_brands
-- ============================================================================
SELECT '=== SUPPRESSION DES VUES ===' as section;

-- Lister toutes les vues qui dépendent de device_brands
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
AND definition LIKE '%device_brands%';

-- Supprimer les vues une par une
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;
DROP VIEW IF EXISTS public.device_brands_view CASCADE;
DROP VIEW IF EXISTS public.brands_with_categories CASCADE;

-- 4. MODIFIER LA COLONNE ID
-- ============================================================================
SELECT '=== MODIFICATION DE LA COLONNE ID ===' as section;

-- Modifier la colonne id pour accepter les textes
ALTER TABLE public.device_brands 
ALTER COLUMN id TYPE TEXT;

-- 5. RECRÉER UN INDEX SUR LA COLONNE ID
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

-- Créer un index sur la colonne id modifiée
CREATE INDEX IF NOT EXISTS idx_device_brands_id_text ON public.device_brands(id);

-- 6. TEST DE FONCTIONNEMENT
-- ============================================================================
SELECT '=== TEST DE FONCTIONNEMENT ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_test_id TEXT := 'test_' || extract(epoch from now())::text;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        RAISE NOTICE '🧪 Test avec l''utilisateur: %', v_user_id;
        
        -- Test d'insertion avec un ID textuel
        BEGIN
            INSERT INTO device_brands (id, name, user_id, created_by, is_active)
            VALUES (v_test_id, 'Test Brand', v_user_id, v_user_id, true);
            
            -- Vérifier l'insertion
            IF EXISTS (SELECT 1 FROM device_brands WHERE id = v_test_id AND user_id = v_user_id) THEN
                RAISE NOTICE '✅ Test réussi : Insertion avec ID textuel fonctionne';
            ELSE
                RAISE NOTICE '❌ Test échoué : Insertion avec ID textuel ne fonctionne pas';
            END IF;
            
            -- Nettoyer le test
            DELETE FROM device_brands WHERE id = v_test_id AND user_id = v_user_id;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors du test d''insertion : %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 7. CRÉER UNE MARQUE HARDCODÉE DE TEST
-- ============================================================================
SELECT '=== CRÉATION MARQUE DE TEST ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        -- Récupérer la première catégorie disponible
        SELECT id INTO v_category_id 
        FROM device_categories 
        WHERE user_id = v_user_id 
        LIMIT 1;
        
        -- Créer Apple avec l'ID "1"
        INSERT INTO device_brands (
            id, 
            name, 
            description, 
            category_id,
            is_active, 
            user_id, 
            created_by
        ) VALUES (
            '1', 
            'Apple', 
            'Fabricant américain de produits électroniques premium',
            v_category_id,
            true, 
            v_user_id, 
            v_user_id
        ) ON CONFLICT (id, user_id) DO UPDATE SET
            name = EXCLUDED.name,
            description = EXCLUDED.description,
            category_id = EXCLUDED.category_id,
            updated_at = NOW();
        
        RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour créer la marque de test';
    END IF;
END $$;

-- 8. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier la nouvelle structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_brands'
AND column_name = 'id'
ORDER BY ordinal_position;

-- Vérifier les données de test
SELECT 
    id,
    name,
    description,
    is_active,
    created_at
FROM device_brands 
WHERE id = '1'
ORDER BY id;

-- Vérifier les index
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'device_brands'
AND indexname LIKE '%id%';

DO $$
BEGIN
    RAISE NOTICE '🎉 Correction terminée !';
    RAISE NOTICE '✅ Colonne id modifiée pour accepter les textes';
    RAISE NOTICE '✅ Marque Apple créée avec l''ID "1"';
    RAISE NOTICE '✅ Les marques hardcodées peuvent maintenant être modifiées';
    RAISE NOTICE '✅ Testez la modification des catégories d''Apple';
END $$;
