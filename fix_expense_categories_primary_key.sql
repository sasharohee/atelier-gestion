-- Script de correction pour établir la clé primaire sur expense_categories
-- et corriger la relation avec expenses

-- 1. Vérifier la structure actuelle de expense_categories
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSTIC DE LA STRUCTURE ===';
    
    -- Vérifier si la table existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expense_categories' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ERREUR: La table expense_categories n''existe pas';
        RETURN;
    END IF;
    
    -- Vérifier les contraintes existantes
    PERFORM 1 FROM information_schema.table_constraints 
    WHERE table_name = 'expense_categories' 
    AND constraint_type = 'PRIMARY KEY'
    AND table_schema = 'public';
    
    IF NOT FOUND THEN
        RAISE NOTICE 'PROBLÈME: Aucune clé primaire trouvée sur expense_categories';
    ELSE
        RAISE NOTICE 'OK: Clé primaire existante sur expense_categories';
    END IF;
END $$;

-- 2. Vérifier la structure de la colonne id
SELECT 
    'Structure de expense_categories.id' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'expense_categories' 
AND column_name = 'id'
AND table_schema = 'public';

-- 3. Vérifier les contraintes existantes
SELECT 
    'Contraintes sur expense_categories' as check_type,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'expense_categories'
AND table_schema = 'public';

-- 4. Corriger la structure de expense_categories
DO $$
BEGIN
    RAISE NOTICE '=== CORRECTION DE LA STRUCTURE ===';
    
    -- Vérifier si la colonne id existe et a le bon type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expense_categories' 
        AND column_name = 'id'
        AND data_type = 'uuid'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Correction de la colonne id...';
        
        -- Supprimer l'ancienne colonne si elle existe
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expense_categories' 
            AND column_name = 'id'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE public.expense_categories DROP COLUMN IF EXISTS id;
        END IF;
        
        -- Ajouter la nouvelle colonne id avec UUID
        ALTER TABLE public.expense_categories ADD COLUMN id UUID DEFAULT gen_random_uuid();
    END IF;
    
    -- Vérifier et ajouter la clé primaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'expense_categories' 
        AND constraint_type = 'PRIMARY KEY'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Ajout de la clé primaire...';
        ALTER TABLE public.expense_categories ADD PRIMARY KEY (id);
    END IF;
    
    -- S'assurer que la colonne id est NOT NULL
    ALTER TABLE public.expense_categories ALTER COLUMN id SET NOT NULL;
    
    RAISE NOTICE 'Structure de expense_categories corrigée';
END $$;

-- 5. Vérifier que la table expenses existe et a la bonne structure
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE LA TABLE EXPENSES ===';
    
    -- Vérifier si la table expenses existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expenses' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ERREUR: La table expenses n''existe pas';
        RETURN;
    END IF;
    
    -- Vérifier si la colonne category_id existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Ajout de la colonne category_id...';
        
        -- Ajouter la colonne category_id
        ALTER TABLE public.expenses ADD COLUMN category_id UUID;
        
        -- Créer des catégories par défaut pour les utilisateurs existants
        INSERT INTO public.expense_categories (id, name, description, color, is_active, user_id, workshop_id, created_by)
        SELECT 
            gen_random_uuid(),
            'Général',
            'Catégorie par défaut',
            '#3B82F6',
            true,
            e.user_id,
            COALESCE(e.workshop_id, gen_random_uuid()),
            e.created_by
        FROM public.expenses e
        WHERE NOT EXISTS (
            SELECT 1 FROM public.expense_categories ec 
            WHERE ec.user_id = e.user_id
        )
        GROUP BY e.user_id, e.workshop_id, e.created_by;
        
        -- Mettre à jour les expenses avec les category_id correspondants
        UPDATE public.expenses 
        SET category_id = (
            SELECT ec.id 
            FROM public.expense_categories ec 
            WHERE ec.user_id = expenses.user_id 
            AND ec.name = 'Général'
            LIMIT 1
        )
        WHERE category_id IS NULL;
        
        -- Rendre la colonne category_id NOT NULL
        ALTER TABLE public.expenses ALTER COLUMN category_id SET NOT NULL;
        
        RAISE NOTICE 'Colonne category_id ajoutée et peuplée';
    ELSE
        RAISE NOTICE 'La colonne category_id existe déjà';
    END IF;
END $$;

-- 6. Établir la contrainte de clé étrangère
DO $$
BEGIN
    RAISE NOTICE '=== ÉTABLISSEMENT DE LA CONTRAINTE FK ===';
    
    -- Vérifier si la contrainte existe déjà
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'expenses' 
        AND constraint_name = 'fk_expenses_category_id'
        AND table_schema = 'public'
    ) THEN
        -- Établir la contrainte de clé étrangère
        ALTER TABLE public.expenses 
        ADD CONSTRAINT fk_expenses_category_id 
        FOREIGN KEY (category_id) REFERENCES public.expense_categories(id) ON DELETE RESTRICT;
        
        RAISE NOTICE 'Contrainte de clé étrangère ajoutée';
    ELSE
        RAISE NOTICE 'La contrainte de clé étrangère existe déjà';
    END IF;
END $$;

-- 7. Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON public.expense_categories(user_id);

-- 8. Vérifier que tout fonctionne
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    RAISE NOTICE '=== TEST DE LA RELATION ===';
    
    -- Tester la jointure
    SELECT COUNT(*) INTO test_count
    FROM public.expenses e
    JOIN public.expense_categories ec ON e.category_id = ec.id
    LIMIT 1;
    
    RAISE NOTICE 'Test de jointure réussi: % enregistrements trouvés', test_count;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du test de jointure: %', SQLERRM;
END $$;

-- 9. Afficher un résumé final
SELECT 
    'Résumé final' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count,
    (SELECT COUNT(*) FROM public.expenses e JOIN public.expense_categories ec ON e.category_id = ec.id) as joined_count;
