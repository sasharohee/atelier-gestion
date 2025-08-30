-- =====================================================
-- SOLUTION RADICALE - ISOLATION PRODUCT_CATEGORIES
-- =====================================================
-- Solution simple et directe pour corriger l'isolation
-- =====================================================

-- ÉTAPE 1: VÉRIFIER L'ÉTAT ACTUEL
SELECT 'ÉTAT ACTUEL' as info, 
       CASE WHEN rowsecurity THEN 'RLS ACTIVÉ' ELSE 'RLS DÉSACTIVÉ' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'product_categories';

-- ÉTAPE 2: AJOUTER LA COLONNE WORKSHOP_ID
ALTER TABLE public.product_categories ADD COLUMN IF NOT EXISTS workshop_id UUID;

-- ÉTAPE 3: ACTIVER RLS
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

-- ÉTAPE 4: SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
DROP POLICY IF EXISTS "product_categories_select_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_insert_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_update_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_delete_policy" ON public.product_categories;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.product_categories;

-- ÉTAPE 5: CRÉER UNE SEULE POLITIQUE SIMPLE
CREATE POLICY "product_categories_isolation" ON public.product_categories
    FOR ALL USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- ÉTAPE 6: METTRE À JOUR LES DONNÉES EXISTANTES
UPDATE public.product_categories 
SET workshop_id = (
    SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
) 
WHERE workshop_id IS NULL;

-- ÉTAPE 7: VÉRIFICATION
SELECT 'VÉRIFICATION' as info, 
       COUNT(*) as total_categories,
       COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as categories_avec_workshop_id
FROM public.product_categories;
