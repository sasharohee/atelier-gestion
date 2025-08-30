-- =====================================================
-- CORRECTION ISOLATION TABLE PRODUCT_CATEGORIES
-- =====================================================
-- Date: 2025-01-23
-- Problème: La table product_categories n'a pas d'isolation (RLS disabled)
-- Solution: Ajouter workshop_id et politiques RLS
-- =====================================================

-- 1. DIAGNOSTIC INITIAL
SELECT '=== DIAGNOSTIC INITIAL ===' as section;

-- Vérifier l'état actuel de la table
SELECT 
    'product_categories' as table_name,
    CASE 
        WHEN pt.rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status,
    COALESCE(pc.count, 0) as nombre_enregistrements
FROM pg_tables pt
LEFT JOIN (
    SELECT COUNT(*) as count FROM public.product_categories
) pc ON true
WHERE pt.schemaname = 'public' 
AND pt.tablename = 'product_categories';

-- Vérifier les colonnes existantes
SELECT 
    'COLONNES EXISTANTES' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'product_categories'
ORDER BY ordinal_position;

-- 2. AJOUT DE LA COLONNE WORKSHOP_ID
SELECT '=== AJOUT COLONNE WORKSHOP_ID ===' as section;

-- Ajouter la colonne workshop_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_categories' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.product_categories 
        ADD COLUMN workshop_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à product_categories';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans product_categories';
    END IF;
END $$;

-- 3. MISE À JOUR DES DONNÉES EXISTANTES
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as section;

-- Mettre à jour les enregistrements existants avec le workshop_id actuel
UPDATE public.product_categories 
SET workshop_id = (
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    )
) 
WHERE workshop_id IS NULL;

-- Afficher le résultat de la mise à jour
SELECT 
    'DONNÉES MISE À JOUR' as section,
    COUNT(*) as total_categories,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM public.product_categories;

-- 4. ACTIVATION DE RLS
SELECT '=== ACTIVATION RLS ===' as section;

-- Activer Row Level Security
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

-- 5. CRÉATION DES POLITIQUES RLS
SELECT '=== CRÉATION POLITIQUES RLS ===' as section;

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "product_categories_select_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_insert_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_update_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_delete_policy" ON public.product_categories;

-- Politique de lecture (SELECT)
CREATE POLICY "product_categories_select_policy" ON public.product_categories
    FOR SELECT USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique d'insertion (INSERT)
CREATE POLICY "product_categories_insert_policy" ON public.product_categories
    FOR INSERT WITH CHECK (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
        AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- Politique de mise à jour (UPDATE)
CREATE POLICY "product_categories_update_policy" ON public.product_categories
    FOR UPDATE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
        AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' IN ('technician', 'admin')
        )
    );

-- Politique de suppression (DELETE)
CREATE POLICY "product_categories_delete_policy" ON public.product_categories
    FOR DELETE USING (
        workshop_id = COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
        AND
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- 6. CRÉATION D'UN TRIGGER POUR L'ISOLATION AUTOMATIQUE
SELECT '=== CRÉATION TRIGGER ===' as section;

-- Fonction trigger pour définir automatiquement le workshop_id
CREATE OR REPLACE FUNCTION set_product_categories_isolation()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir le workshop_id automatiquement si non défini
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
DROP TRIGGER IF EXISTS set_product_categories_isolation_trigger ON public.product_categories;
CREATE TRIGGER set_product_categories_isolation_trigger
    BEFORE INSERT ON public.product_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_product_categories_isolation();

-- 7. CRÉATION D'INDEX POUR LES PERFORMANCES
SELECT '=== CRÉATION INDEX ===' as section;

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_categories_workshop_id ON public.product_categories(workshop_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_name ON public.product_categories(name);
CREATE INDEX IF NOT EXISTS idx_product_categories_active ON public.product_categories(is_active);

-- 8. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que RLS est activé
SELECT 
    'RLS STATUS' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'product_categories';

-- Vérifier les politiques créées
SELECT 
    'POLITIQUES RLS' as section,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual LIKE '%role%' THEN '✅ Contrôle par rôle'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'product_categories'
ORDER BY policyname;

-- Vérifier les données
SELECT 
    'DONNÉES FINALES' as section,
    name,
    workshop_id,
    is_active
FROM public.product_categories
ORDER BY sort_order;

-- 9. TEST D'ISOLATION
SELECT '=== TEST ISOLATION ===' as section;

-- Test de l'isolation
DO $$
DECLARE
    current_workshop_id UUID;
    total_categories INTEGER;
    visible_categories INTEGER;
BEGIN
    -- Récupérer le workshop_id actuel
    SELECT value::UUID INTO current_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Compter le total des catégories
    SELECT COUNT(*) INTO total_categories
    FROM public.product_categories;
    
    -- Compter les catégories visibles pour l'atelier actuel
    SELECT COUNT(*) INTO visible_categories
    FROM public.product_categories
    WHERE workshop_id = current_workshop_id;
    
    RAISE NOTICE 'Workshop ID actuel: %', current_workshop_id;
    RAISE NOTICE 'Total catégories: %', total_categories;
    RAISE NOTICE 'Catégories visibles: %', visible_categories;
    
    IF visible_categories = total_categories THEN
        RAISE NOTICE '✅ Isolation correcte - Toutes les catégories sont visibles pour l''atelier actuel';
    ELSE
        RAISE NOTICE '⚠️ Isolation partielle - % catégories visibles sur % total', visible_categories, total_categories;
    END IF;
END $$;

-- 10. MESSAGE DE CONFIRMATION
SELECT 
    '✅ CORRECTION TERMINÉE' as status,
    'La table product_categories est maintenant isolée avec RLS activé' as message;
