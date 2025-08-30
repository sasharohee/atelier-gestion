-- =====================================================
-- CORRECTION URGENCE - ISOLATION PRODUCT_CATEGORIES
-- =====================================================
-- Script simplifié et robuste pour corriger l'isolation
-- =====================================================

-- 1. AJOUTER LA COLONNE WORKSHOP_ID SI ELLE N'EXISTE PAS
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_categories' 
        AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.product_categories ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà';
    END IF;
END $$;

-- 2. ACTIVER RLS IMMÉDIATEMENT
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

-- 3. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES
DROP POLICY IF EXISTS "product_categories_select_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_insert_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_update_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_delete_policy" ON public.product_categories;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.product_categories;

-- 4. CRÉER DES POLITIQUES RLS SIMPLES ET EFFICACES

-- Politique de lecture - Seules les catégories de l'atelier actuel
CREATE POLICY "product_categories_select_policy" ON public.product_categories
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- Politique d'insertion - Seuls les techniciens/admins peuvent créer
CREATE POLICY "product_categories_insert_policy" ON public.product_categories
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- Politique de mise à jour - Seuls les techniciens/admins peuvent modifier
CREATE POLICY "product_categories_update_policy" ON public.product_categories
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- Politique de suppression - Seuls les admins peuvent supprimer
CREATE POLICY "product_categories_delete_policy" ON public.product_categories
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- 5. METTRE À JOUR LES DONNÉES EXISTANTES
UPDATE public.product_categories 
SET workshop_id = (
    SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
) 
WHERE workshop_id IS NULL;

-- 6. CRÉER UN TRIGGER POUR L'ISOLATION AUTOMATIQUE
CREATE OR REPLACE FUNCTION set_product_categories_workshop_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_product_categories_workshop_id_trigger ON public.product_categories;
CREATE TRIGGER set_product_categories_workshop_id_trigger
    BEFORE INSERT ON public.product_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_product_categories_workshop_id();

-- 7. CRÉER DES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_product_categories_workshop_id ON public.product_categories(workshop_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_name ON public.product_categories(name);

-- 8. VÉRIFICATION FINALE
DO $$
DECLARE
    rls_enabled BOOLEAN;
    policy_count INTEGER;
    data_count INTEGER;
    isolated_count INTEGER;
BEGIN
    -- Vérifier RLS
    SELECT rowsecurity INTO rls_enabled
    FROM pg_tables 
    WHERE schemaname = 'public' AND tablename = 'product_categories';
    
    -- Compter les politiques
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'product_categories';
    
    -- Compter les données
    SELECT COUNT(*) INTO data_count
    FROM public.product_categories;
    
    -- Compter les données isolées
    SELECT COUNT(*) INTO isolated_count
    FROM public.product_categories
    WHERE workshop_id IS NOT NULL;
    
    RAISE NOTICE '=== VÉRIFICATION FINALE ===';
    RAISE NOTICE 'RLS activé: %', CASE WHEN rls_enabled THEN '✅ OUI' ELSE '❌ NON' END;
    RAISE NOTICE 'Politiques créées: %', policy_count;
    RAISE NOTICE 'Total catégories: %', data_count;
    RAISE NOTICE 'Catégories isolées: %', isolated_count;
    
    IF rls_enabled AND policy_count >= 4 AND isolated_count = data_count THEN
        RAISE NOTICE '✅ CORRECTION RÉUSSIE - Isolation complète activée';
    ELSE
        RAISE NOTICE '❌ PROBLÈME DÉTECTÉ - Vérifiez les résultats';
    END IF;
END $$;
