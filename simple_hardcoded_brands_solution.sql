-- ============================================================================
-- SOLUTION SIMPLE POUR LES MARQUES HARDCODÉES
-- ============================================================================
-- Date: $(date)
-- Description: Solution simple qui ne modifie pas la structure de la table device_brands
-- ============================================================================

-- 1. CRÉER UNE TABLE DE MAPPING POUR LES MARQUES HARDCODÉES
-- ============================================================================
SELECT '=== CRÉATION TABLE DE MAPPING ===' as section;

CREATE TABLE IF NOT EXISTS public.hardcoded_brand_mapping (
    id SERIAL PRIMARY KEY,
    hardcoded_id TEXT NOT NULL, -- ID hardcodé comme "1", "2", etc.
    database_id UUID NOT NULL,  -- ID UUID généré en base
    brand_name TEXT NOT NULL,
    description TEXT DEFAULT '',
    logo TEXT DEFAULT '',
    category_id UUID REFERENCES public.device_categories(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contrainte d'unicité
    UNIQUE(hardcoded_id, user_id)
);

-- 2. ACTIVER RLS SUR LA NOUVELLE TABLE
-- ============================================================================
SELECT '=== ACTIVATION RLS ===' as section;

ALTER TABLE public.hardcoded_brand_mapping ENABLE ROW LEVEL SECURITY;

-- 3. CRÉER LES POLITIQUES RLS
-- ============================================================================
SELECT '=== POLITIQUES RLS ===' as section;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own hardcoded brand mappings" ON public.hardcoded_brand_mapping;
DROP POLICY IF EXISTS "Users can insert their own hardcoded brand mappings" ON public.hardcoded_brand_mapping;
DROP POLICY IF EXISTS "Users can update their own hardcoded brand mappings" ON public.hardcoded_brand_mapping;
DROP POLICY IF EXISTS "Users can delete their own hardcoded brand mappings" ON public.hardcoded_brand_mapping;

-- Créer les nouvelles politiques
CREATE POLICY "Users can view their own hardcoded brand mappings" ON public.hardcoded_brand_mapping
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own hardcoded brand mappings" ON public.hardcoded_brand_mapping
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own hardcoded brand mappings" ON public.hardcoded_brand_mapping
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own hardcoded brand mappings" ON public.hardcoded_brand_mapping
    FOR DELETE USING (auth.uid() = user_id);

-- 4. CRÉER LE TRIGGER POUR L'ISOLATION
-- ============================================================================
SELECT '=== CRÉATION TRIGGER ===' as section;

-- Fonction pour définir automatiquement user_id et created_by
CREATE OR REPLACE FUNCTION set_hardcoded_brand_mapping_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS set_hardcoded_brand_mapping_context_trigger ON public.hardcoded_brand_mapping;

-- Créer le nouveau trigger
CREATE TRIGGER set_hardcoded_brand_mapping_context_trigger
    BEFORE INSERT ON public.hardcoded_brand_mapping
    FOR EACH ROW
    EXECUTE FUNCTION set_hardcoded_brand_mapping_context();

-- 5. FONCTION POUR CRÉER/METTRE À JOUR UNE MARQUE HARDCODÉE
-- ============================================================================
SELECT '=== CRÉATION FONCTION DE GESTION ===' as section;

CREATE OR REPLACE FUNCTION manage_hardcoded_brand(
    p_hardcoded_id TEXT,
    p_brand_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_database_id UUID;
    v_existing_mapping RECORD;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Vérifier si un mapping existe déjà
    SELECT * INTO v_existing_mapping
    FROM hardcoded_brand_mapping
    WHERE hardcoded_id = p_hardcoded_id AND user_id = v_user_id;
    
    IF v_existing_mapping.id IS NOT NULL THEN
        -- Le mapping existe, mettre à jour la marque en base
        v_database_id := v_existing_mapping.database_id;
        
        UPDATE device_brands SET
            name = p_brand_name,
            description = p_description,
            logo = p_logo,
            category_id = p_category_id,
            updated_at = NOW()
        WHERE id = v_database_id AND user_id = v_user_id;
        
        -- Mettre à jour le mapping
        UPDATE hardcoded_brand_mapping SET
            brand_name = p_brand_name,
            description = p_description,
            logo = p_logo,
            category_id = p_category_id,
            updated_at = NOW()
        WHERE id = v_existing_mapping.id;
        
        RAISE NOTICE '✅ Marque hardcodée mise à jour : % (%)', p_brand_name, p_hardcoded_id;
    ELSE
        -- Le mapping n'existe pas, créer une nouvelle marque
        INSERT INTO device_brands (
            name,
            description,
            logo,
            category_id,
            is_active,
            user_id,
            created_by
        ) VALUES (
            p_brand_name,
            p_description,
            p_logo,
            p_category_id,
            true,
            v_user_id,
            v_user_id
        ) RETURNING id INTO v_database_id;
        
        -- Créer le mapping
        INSERT INTO hardcoded_brand_mapping (
            hardcoded_id,
            database_id,
            brand_name,
            description,
            logo,
            category_id,
            user_id,
            created_by
        ) VALUES (
            p_hardcoded_id,
            v_database_id,
            p_brand_name,
            p_description,
            p_logo,
            p_category_id,
            v_user_id,
            v_user_id
        );
        
        RAISE NOTICE '✅ Marque hardcodée créée : % (%) -> %', p_brand_name, p_hardcoded_id, v_database_id;
    END IF;
    
    RETURN v_database_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. FONCTION POUR RÉCUPÉRER L'ID DE BASE D'UNE MARQUE HARDCODÉE
-- ============================================================================
SELECT '=== CRÉATION FONCTION DE RÉCUPÉRATION ===' as section;

CREATE OR REPLACE FUNCTION get_database_id_for_hardcoded_brand(
    p_hardcoded_id TEXT
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_database_id UUID;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Récupérer l'ID de base correspondant
    SELECT database_id INTO v_database_id
    FROM hardcoded_brand_mapping
    WHERE hardcoded_id = p_hardcoded_id AND user_id = v_user_id;
    
    RETURN v_database_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. CRÉER LES INDEX POUR LES PERFORMANCES
-- ============================================================================
SELECT '=== CRÉATION INDEX ===' as section;

CREATE INDEX IF NOT EXISTS idx_hardcoded_brand_mapping_hardcoded_id ON public.hardcoded_brand_mapping(hardcoded_id);
CREATE INDEX IF NOT EXISTS idx_hardcoded_brand_mapping_database_id ON public.hardcoded_brand_mapping(database_id);
CREATE INDEX IF NOT EXISTS idx_hardcoded_brand_mapping_user_id ON public.hardcoded_brand_mapping(user_id);

-- 8. TEST DE FONCTIONNEMENT
-- ============================================================================
SELECT '=== TEST DE FONCTIONNEMENT ===' as section;

DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
    v_database_id UUID;
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
        
        -- Test de création d'une marque hardcodée
        v_database_id := manage_hardcoded_brand(
            '1',
            'Apple',
            'Fabricant américain de produits électroniques premium',
            '',
            v_category_id
        );
        
        RAISE NOTICE '✅ Test réussi : Apple créée avec ID %', v_database_id;
        
        -- Test de récupération de l'ID
        v_database_id := get_database_id_for_hardcoded_brand('1');
        RAISE NOTICE '✅ Test réussi : ID récupéré %', v_database_id;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour le test';
    END IF;
END $$;

-- 9. VÉRIFICATION FINALE
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure des nouvelles tables
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'hardcoded_brand_mapping'
ORDER BY table_name, ordinal_position;

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'hardcoded_brand_mapping'
ORDER BY policyname;

-- Vérifier les fonctions créées
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%hardcoded%brand%'
ORDER BY routine_name;

DO $$
BEGIN
    RAISE NOTICE '🎉 Solution simple terminée !';
    RAISE NOTICE '✅ Table hardcoded_brand_mapping créée';
    RAISE NOTICE '✅ Fonction manage_hardcoded_brand créée';
    RAISE NOTICE '✅ Fonction get_database_id_for_hardcoded_brand créée';
    RAISE NOTICE '✅ Aucune modification de la structure existante';
    RAISE NOTICE '✅ Les marques hardcodées sont maintenant gérées via un mapping';
END $$;
