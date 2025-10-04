-- Script de correction pour établir la relation entre expenses et expense_categories
-- Ce script corrige la structure des tables pour permettre les jointures

-- 1. Vérifier la structure actuelle des tables
DO $$
BEGIN
    -- Vérifier si la colonne category_id existe dans expenses
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'La colonne category_id n''existe pas dans expenses';
        
        -- Vérifier si la colonne category existe
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expenses' 
            AND column_name = 'category'
            AND table_schema = 'public'
        ) THEN
            RAISE NOTICE 'La colonne category existe, migration nécessaire';
            
            -- Ajouter la colonne category_id
            ALTER TABLE public.expenses ADD COLUMN category_id UUID;
            
            -- Créer des catégories par défaut si elles n'existent pas
            INSERT INTO public.expense_categories (id, name, description, color, is_active, user_id, workshop_id, created_by)
            SELECT 
                gen_random_uuid(),
                'Général',
                'Catégorie par défaut',
                '#3B82F6',
                true,
                e.user_id,
                e.workshop_id,
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
            
            -- Ajouter la contrainte de clé étrangère
            ALTER TABLE public.expenses 
            ADD CONSTRAINT fk_expenses_category_id 
            FOREIGN KEY (category_id) REFERENCES public.expense_categories(id) ON DELETE RESTRICT;
            
            -- Supprimer l'ancienne colonne category
            ALTER TABLE public.expenses DROP COLUMN category;
            
            RAISE NOTICE 'Migration terminée avec succès';
        ELSE
            RAISE NOTICE 'Aucune colonne category trouvée, structure déjà correcte';
        END IF;
    ELSE
        RAISE NOTICE 'La colonne category_id existe déjà';
    END IF;
END $$;

-- 2. Vérifier que la relation fonctionne
DO $$
BEGIN
    -- Tester une requête de jointure
    PERFORM 1 FROM public.expenses e
    JOIN public.expense_categories ec ON e.category_id = ec.id
    LIMIT 1;
    
    RAISE NOTICE 'La relation entre expenses et expense_categories fonctionne correctement';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du test de la relation: %', SQLERRM;
END $$;

-- 3. Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);

-- 4. Vérifier les politiques RLS
DO $$
BEGIN
    -- Vérifier si les politiques RLS existent
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'expenses' 
        AND policyname = 'Users can view their own expenses'
    ) THEN
        RAISE NOTICE 'Création des politiques RLS pour expenses';
        
        -- Activer RLS
        ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
        
        -- Créer les politiques
        CREATE POLICY "Users can view their own expenses" ON public.expenses
            FOR SELECT USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can insert their own expenses" ON public.expenses
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE POLICY "Users can update their own expenses" ON public.expenses
            FOR UPDATE USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can delete their own expenses" ON public.expenses
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
    
    -- Vérifier les politiques pour expense_categories
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'expense_categories' 
        AND policyname = 'Users can view their own expense categories'
    ) THEN
        RAISE NOTICE 'Création des politiques RLS pour expense_categories';
        
        -- Activer RLS
        ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
        
        -- Créer les politiques
        CREATE POLICY "Users can view their own expense categories" ON public.expense_categories
            FOR SELECT USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can insert their own expense categories" ON public.expense_categories
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE POLICY "Users can update their own expense categories" ON public.expense_categories
            FOR UPDATE USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can delete their own expense categories" ON public.expense_categories
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 5. Test final
SELECT 
    'Test de la relation' as test_name,
    COUNT(*) as expenses_count,
    COUNT(DISTINCT e.category_id) as categories_used
FROM public.expenses e
JOIN public.expense_categories ec ON e.category_id = ec.id;
