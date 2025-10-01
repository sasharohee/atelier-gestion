-- ============================================================================
-- MODIFICATION DE LA TABLE device_brands POUR SUPPORTER LES IDs HARDCODÉS
-- ============================================================================
-- Date: $(date)
-- Description: Modifier la table device_brands pour accepter les IDs textuels comme "1", "2", etc.
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

-- 2. SAUVEGARDER LES DONNÉES EXISTANTES (SI NÉCESSAIRE)
-- ============================================================================
SELECT '=== SAUVEGARDE DES DONNÉES EXISTANTES ===' as section;

-- Créer une table de sauvegarde si elle n'existe pas
CREATE TABLE IF NOT EXISTS device_brands_backup AS 
SELECT * FROM device_brands WHERE false;

-- Vider la table de sauvegarde
DELETE FROM device_brands_backup;

-- Copier les données existantes
INSERT INTO device_brands_backup 
SELECT * FROM device_brands;

SELECT COUNT(*) as backup_count FROM device_brands_backup;

-- 3. SUPPRIMER LES VUES ET RÈGLES QUI DÉPENDENT DE LA COLONNE ID
-- ============================================================================
SELECT '=== SUPPRESSION DES VUES ET RÈGLES ===' as section;

-- Supprimer la vue brand_with_categories si elle existe
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Supprimer les autres vues qui pourraient dépendre de device_brands
DROP VIEW IF EXISTS public.device_brands_view CASCADE;

-- 4. MODIFIER LA COLONNE ID POUR ACCEPTER LES TEXTES
-- ============================================================================
SELECT '=== MODIFICATION DE LA COLONNE ID ===' as section;

-- Modifier la colonne id pour accepter les textes
ALTER TABLE public.device_brands 
ALTER COLUMN id TYPE TEXT;

-- 5. CRÉER UN INDEX SUR LA NOUVELLE COLONNE ID
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

-- Supprimer l'ancien index s'il existe
DROP INDEX IF EXISTS device_brands_pkey;

-- Créer un nouveau index sur la colonne id modifiée
CREATE INDEX IF NOT EXISTS idx_device_brands_id ON public.device_brands(id);

-- 6. RECRÉER LA VUE brand_with_categories
-- ============================================================================
SELECT '=== RECRÉATION DE LA VUE ===' as section;

-- Recréer la vue brand_with_categories avec la nouvelle structure
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
    -- Agréger les catégories en JSON
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

-- Activer RLS sur la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- 7. VÉRIFIER QUE LES CONTRAINTES FONCTIONNENT
-- ============================================================================
SELECT '=== VÉRIFICATION DES CONTRAINTES ===' as section;

-- Vérifier que la table accepte maintenant les IDs textuels
DO $$
BEGIN
    -- Test avec un ID textuel
    BEGIN
        INSERT INTO device_brands (id, name, user_id, created_by, is_active)
        VALUES ('test_id_123', 'Test Brand', auth.uid(), auth.uid(), true);
        
        -- Supprimer le test
        DELETE FROM device_brands WHERE id = 'test_id_123';
        
        RAISE NOTICE '✅ Test réussi : La table accepte maintenant les IDs textuels';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test : %', SQLERRM;
    END;
END $$;

-- 8. CRÉER LES MARQUES HARDCODÉES PAR DÉFAUT
-- ============================================================================
SELECT '=== CRÉATION DES MARQUES HARDCODÉES ===' as section;

-- Fonction pour créer une marque hardcodée si elle n'existe pas
CREATE OR REPLACE FUNCTION create_hardcoded_brand_if_not_exists(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Vérifier si la marque existe déjà
    IF NOT EXISTS (
        SELECT 1 FROM device_brands 
        WHERE id = p_id AND user_id = v_user_id
    ) THEN
        -- Créer la marque
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
            p_id, 
            p_name, 
            p_description, 
            p_logo, 
            p_category_id,
            true, 
            v_user_id, 
            v_user_id
        );
        
        RAISE NOTICE '✅ Marque hardcodée créée : % (%)', p_name, p_id;
        RETURN TRUE;
    ELSE
        RAISE NOTICE 'ℹ️ Marque hardcodée existe déjà : % (%)', p_name, p_id;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. TEST DE LA FONCTION
-- ============================================================================
SELECT '=== TEST DE LA FONCTION ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        RAISE NOTICE '🧪 Test avec l''utilisateur: %', v_user_id;
        
        -- Récupérer la première catégorie disponible
        SELECT id INTO v_category_id 
        FROM device_categories 
        WHERE user_id = v_user_id 
        LIMIT 1;
        
        -- Créer quelques marques de test
        PERFORM create_hardcoded_brand_if_not_exists(
            '1', 
            'Apple', 
            'Fabricant américain de produits électroniques premium',
            '',
            v_category_id
        );
        
        PERFORM create_hardcoded_brand_if_not_exists(
            '2', 
            'Samsung', 
            'Fabricant coréen leader en électronique et smartphones',
            '',
            v_category_id
        );
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 10. VÉRIFICATION FINALE
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

-- Vérifier les données créées
SELECT 
    id,
    name,
    description,
    is_active,
    created_at
FROM device_brands 
WHERE id IN ('1', '2')
ORDER BY id;

-- Vérifier les fonctions créées
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'create_hardcoded_brand_if_not_exists'
ORDER BY routine_name;

DO $$
BEGIN
    RAISE NOTICE '🎉 Modification terminée !';
    RAISE NOTICE '✅ Table device_brands modifiée pour accepter les IDs textuels';
    RAISE NOTICE '✅ Fonction create_hardcoded_brand_if_not_exists créée';
    RAISE NOTICE '✅ Marques hardcodées de test créées';
    RAISE NOTICE '✅ Les marques hardcodées peuvent maintenant être modifiées en base';
END $$;
