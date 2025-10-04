-- Script de correction pour le problème de contrainte NOT NULL sur category_id
-- Ce script résout le problème de category_id NULL lors de l'insertion

-- 1. Diagnostic initial
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSTIC INITIAL ===';
    
    -- Vérifier l'existence des tables
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expenses' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ERREUR: La table expenses n''existe pas';
        RETURN;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expense_categories' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ERREUR: La table expense_categories n''existe pas';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Tables expenses et expense_categories trouvées';
    
    -- Vérifier la colonne category_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Colonne category_id trouvée';
        
        -- Vérifier si elle est NOT NULL
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expenses' 
            AND column_name = 'category_id'
            AND is_nullable = 'NO'
            AND table_schema = 'public'
        ) THEN
            RAISE NOTICE 'Colonne category_id est NOT NULL';
        ELSE
            RAISE NOTICE 'Colonne category_id est nullable';
        END IF;
    ELSE
        RAISE NOTICE 'PROBLÈME: La colonne category_id n''existe pas';
    END IF;
END $$;

-- 2. Afficher la structure actuelle
SELECT 
    'expenses structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Vérifier les données existantes
SELECT 
    'Data check' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count,
    (SELECT COUNT(*) FROM public.expenses WHERE category_id IS NULL) as expenses_without_category;

-- 4. S'assurer que expense_categories a la bonne structure
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE EXPENSE_CATEGORIES ===';
    
    -- Vérifier la clé primaire
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'expense_categories' 
        AND constraint_type = 'PRIMARY KEY'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expense_categories ADD PRIMARY KEY (id);
        RAISE NOTICE 'Clé primaire ajoutée à expense_categories';
    END IF;
    
    -- Vérifier que la colonne id est UUID
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expense_categories' 
        AND column_name = 'id'
        AND data_type = 'uuid'
        AND table_schema = 'public'
    ) THEN
        -- Corriger le type de la colonne id
        ALTER TABLE public.expense_categories ALTER COLUMN id TYPE UUID USING id::UUID;
        RAISE NOTICE 'Type de la colonne id corrigé vers UUID';
    END IF;
END $$;

-- 5. Créer des catégories par défaut pour tous les utilisateurs
DO $$
DECLARE
    user_record RECORD;
    category_count INTEGER;
BEGIN
    RAISE NOTICE '=== CRÉATION DES CATÉGORIES PAR DÉFAUT ===';
    
    -- Créer des catégories par défaut pour chaque utilisateur qui n'en a pas
    FOR user_record IN 
        SELECT DISTINCT user_id FROM public.expenses 
        WHERE user_id IS NOT NULL
    LOOP
        -- Vérifier si l'utilisateur a déjà des catégories
        SELECT COUNT(*) INTO category_count
        FROM public.expense_categories 
        WHERE user_id = user_record.user_id;
        
        IF category_count = 0 THEN
            -- Créer une catégorie par défaut pour cet utilisateur
            INSERT INTO public.expense_categories (
                id, name, description, color, is_active, 
                user_id, workshop_id, created_by, 
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(),
                'Général',
                'Catégorie par défaut',
                '#3B82F6',
                true,
                user_record.user_id,
                gen_random_uuid(),
                user_record.user_id,
                NOW(),
                NOW()
            );
            
            RAISE NOTICE 'Catégorie par défaut créée pour l''utilisateur %', user_record.user_id;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Catégories par défaut créées pour tous les utilisateurs';
END $$;

-- 6. Mettre à jour les expenses avec category_id
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== MISE À JOUR DES CATEGORY_ID ===';
    
    -- Mettre à jour les expenses qui n'ont pas de category_id
    UPDATE public.expenses 
    SET category_id = (
        SELECT ec.id 
        FROM public.expense_categories ec 
        WHERE ec.user_id = expenses.user_id 
        AND ec.name = 'Général'
        LIMIT 1
    )
    WHERE category_id IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '% expenses mis à jour avec category_id', updated_count;
    
    -- Vérifier qu'il n'y a plus d'expenses sans category_id
    IF EXISTS (
        SELECT 1 FROM public.expenses 
        WHERE category_id IS NULL
    ) THEN
        RAISE NOTICE 'ATTENTION: Il reste des expenses sans category_id !';
    ELSE
        RAISE NOTICE 'OK: Tous les expenses ont maintenant un category_id';
    END IF;
END $$;

-- 7. Établir la contrainte de clé étrangère
DO $$
BEGIN
    RAISE NOTICE '=== ÉTABLISSEMENT DE LA CONTRAINTE FK ===';
    
    -- Supprimer la contrainte si elle existe déjà
    ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS fk_expenses_category_id;
    
    -- Ajouter la contrainte de clé étrangère
    ALTER TABLE public.expenses 
    ADD CONSTRAINT fk_expenses_category_id 
    FOREIGN KEY (category_id) REFERENCES public.expense_categories(id) ON DELETE RESTRICT;
    
    RAISE NOTICE 'Contrainte de clé étrangère établie';
END $$;

-- 8. S'assurer que toutes les colonnes nécessaires existent
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DES COLONNES NÉCESSAIRES ===';
    
    -- Ajouter title si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'title'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN title VARCHAR(255);
        RAISE NOTICE 'Colonne title ajoutée';
    END IF;
    
    -- Ajouter description si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'description'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN description TEXT;
        RAISE NOTICE 'Colonne description ajoutée';
    END IF;
    
    -- Ajouter supplier si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'supplier'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN supplier VARCHAR(255);
        RAISE NOTICE 'Colonne supplier ajoutée';
    END IF;
    
    -- Ajouter invoice_number si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'invoice_number'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN invoice_number VARCHAR(255);
        RAISE NOTICE 'Colonne invoice_number ajoutée';
    END IF;
    
    -- Ajouter payment_method si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'payment_method'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN payment_method VARCHAR(20) DEFAULT 'card';
        RAISE NOTICE 'Colonne payment_method ajoutée';
    END IF;
    
    -- Ajouter status si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'status'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
        RAISE NOTICE 'Colonne status ajoutée';
    END IF;
    
    -- Ajouter expense_date si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'expense_date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN expense_date DATE;
        RAISE NOTICE 'Colonne expense_date ajoutée';
    END IF;
    
    -- Ajouter due_date si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'due_date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN due_date DATE;
        RAISE NOTICE 'Colonne due_date ajoutée';
    END IF;
    
    -- Ajouter receipt_path si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'receipt_path'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN receipt_path TEXT;
        RAISE NOTICE 'Colonne receipt_path ajoutée';
    END IF;
    
    -- Ajouter tags si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'tags'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN tags TEXT[];
        RAISE NOTICE 'Colonne tags ajoutée';
    END IF;
    
    RAISE NOTICE 'Toutes les colonnes nécessaires ont été vérifiées/ajoutées';
END $$;

-- 9. Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON public.expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_due_date ON public.expenses(due_date);
CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON public.expense_categories(user_id);

-- 10. Configurer RLS
DO $$
BEGIN
    RAISE NOTICE '=== CONFIGURATION RLS ===';
    
    -- Activer RLS sur expenses
    ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
    
    -- Supprimer les anciennes politiques
    DROP POLICY IF EXISTS "Users can view their own expenses" ON public.expenses;
    DROP POLICY IF EXISTS "Users can insert their own expenses" ON public.expenses;
    DROP POLICY IF EXISTS "Users can update their own expenses" ON public.expenses;
    DROP POLICY IF EXISTS "Users can delete their own expenses" ON public.expenses;
    
    -- Créer les nouvelles politiques
    CREATE POLICY "Users can view their own expenses" ON public.expenses
        FOR SELECT USING (auth.uid() = user_id);
        
    CREATE POLICY "Users can insert their own expenses" ON public.expenses
        FOR INSERT WITH CHECK (auth.uid() = user_id);
        
    CREATE POLICY "Users can update their own expenses" ON public.expenses
        FOR UPDATE USING (auth.uid() = user_id);
        
    CREATE POLICY "Users can delete their own expenses" ON public.expenses
        FOR DELETE USING (auth.uid() = user_id);
    
    -- Activer RLS sur expense_categories
    ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
    
    -- Supprimer les anciennes politiques
    DROP POLICY IF EXISTS "Users can view their own expense categories" ON public.expense_categories;
    DROP POLICY IF EXISTS "Users can insert their own expense categories" ON public.expense_categories;
    DROP POLICY IF EXISTS "Users can update their own expense categories" ON public.expense_categories;
    DROP POLICY IF EXISTS "Users can delete their own expense categories" ON public.expense_categories;
    
    -- Créer les nouvelles politiques
    CREATE POLICY "Users can view their own expense categories" ON public.expense_categories
        FOR SELECT USING (auth.uid() = user_id);
        
    CREATE POLICY "Users can insert their own expense categories" ON public.expense_categories
        FOR INSERT WITH CHECK (auth.uid() = user_id);
        
    CREATE POLICY "Users can update their own expense categories" ON public.expense_categories
        FOR UPDATE USING (auth.uid() = user_id);
        
    CREATE POLICY "Users can delete their own expense categories" ON public.expense_categories
        FOR DELETE USING (auth.uid() = user_id);
    
    RAISE NOTICE 'RLS configuré';
END $$;

-- 11. Test final
DO $$
DECLARE
    test_count INTEGER;
    expenses_without_category INTEGER;
BEGIN
    RAISE NOTICE '=== TEST FINAL ===';
    
    -- Tester la jointure
    SELECT COUNT(*) INTO test_count
    FROM public.expenses e
    JOIN public.expense_categories ec ON e.category_id = ec.id
    LIMIT 1;
    
    RAISE NOTICE 'Test de jointure réussi: % enregistrements trouvés', test_count;
    
    -- Vérifier qu'il n'y a plus d'expenses sans category_id
    SELECT COUNT(*) INTO expenses_without_category
    FROM public.expenses 
    WHERE category_id IS NULL;
    
    IF expenses_without_category = 0 THEN
        RAISE NOTICE 'OK: Tous les expenses ont un category_id';
    ELSE
        RAISE NOTICE 'ATTENTION: % expenses n''ont pas de category_id', expenses_without_category;
    END IF;
    
    -- Vérifier que les colonnes nécessaires existent
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'OK: La colonne "category_id" existe';
    ELSE
        RAISE NOTICE 'ERREUR: La colonne "category_id" n''existe pas !';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'expense_date'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'OK: La colonne "expense_date" existe';
    ELSE
        RAISE NOTICE 'ERREUR: La colonne "expense_date" n''existe pas !';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du test: %', SQLERRM;
END $$;

-- 12. Résumé final
SELECT 
    'Résumé final' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count,
    (SELECT COUNT(*) FROM public.expenses e JOIN public.expense_categories ec ON e.category_id = ec.id) as joined_count,
    (SELECT COUNT(*) FROM public.expenses WHERE category_id IS NULL) as expenses_without_category;
