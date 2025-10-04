-- Script de correction définitive pour la table expenses
-- Ce script résout tous les problèmes de structure identifiés

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
    
    RAISE NOTICE 'Table expenses trouvée';
    
    -- Vérifier les colonnes problématiques
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'PROBLÈME: La colonne "category" (TEXT) existe encore';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'date'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'PROBLÈME: La colonne "date" existe (devrait être "expense_date")';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'PROBLÈME: La colonne "category_id" n''existe pas';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'expense_date'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'PROBLÈME: La colonne "expense_date" n''existe pas';
    END IF;
END $$;

-- 2. Supprimer les colonnes problématiques
DO $$
BEGIN
    RAISE NOTICE '=== SUPPRESSION DES COLONNES PROBLÉMATIQUES ===';
    
    -- Supprimer la colonne category si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses DROP COLUMN category;
        RAISE NOTICE 'Colonne "category" supprimée';
    END IF;
    
    -- Supprimer la colonne date si elle existe (remplacée par expense_date)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses DROP COLUMN date;
        RAISE NOTICE 'Colonne "date" supprimée';
    END IF;
END $$;

-- 3. S'assurer que expense_categories existe avec la bonne structure
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE EXPENSE_CATEGORIES ===';
    
    -- Vérifier si la table existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expense_categories' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Création de la table expense_categories...';
        
        CREATE TABLE public.expense_categories (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            color VARCHAR(7) DEFAULT '#3B82F6',
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            workshop_id UUID,
            created_by UUID
        );
        
        RAISE NOTICE 'Table expense_categories créée';
    ELSE
        RAISE NOTICE 'Table expense_categories existe déjà';
    END IF;
    
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
END $$;

-- 4. Ajouter toutes les colonnes nécessaires
DO $$
BEGIN
    RAISE NOTICE '=== AJOUT DES COLONNES NÉCESSAIRES ===';
    
    -- Ajouter category_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN category_id UUID;
        RAISE NOTICE 'Colonne category_id ajoutée';
    END IF;
    
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
    
    RAISE NOTICE 'Toutes les colonnes nécessaires ont été ajoutées';
END $$;

-- 5. Créer des catégories par défaut
DO $$
BEGIN
    RAISE NOTICE '=== CRÉATION DES CATÉGORIES PAR DÉFAUT ===';
    
    -- Créer des catégories par défaut pour chaque utilisateur qui n'en a pas
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
    
    RAISE NOTICE 'Catégories par défaut créées';
END $$;

-- 6. Mettre à jour les category_id
DO $$
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
    
    -- Rendre category_id NOT NULL
    ALTER TABLE public.expenses ALTER COLUMN category_id SET NOT NULL;
    
    RAISE NOTICE 'Category_id mis à jour et rendu NOT NULL';
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

-- 8. Ajouter les contraintes de validation (sans erreur si elles existent)
DO $$
BEGIN
    RAISE NOTICE '=== AJOUT DES CONTRAINTES DE VALIDATION ===';
    
    -- Contrainte pour payment_method
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'expenses' 
        AND constraint_name = 'chk_payment_method'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses 
        ADD CONSTRAINT chk_payment_method 
        CHECK (payment_method IN ('cash', 'card', 'transfer', 'check'));
        RAISE NOTICE 'Contrainte chk_payment_method ajoutée';
    ELSE
        RAISE NOTICE 'Contrainte chk_payment_method existe déjà';
    END IF;
    
    -- Contrainte pour status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'expenses' 
        AND constraint_name = 'chk_status'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses 
        ADD CONSTRAINT chk_status 
        CHECK (status IN ('pending', 'paid', 'cancelled'));
        RAISE NOTICE 'Contrainte chk_status ajoutée';
    ELSE
        RAISE NOTICE 'Contrainte chk_status existe déjà';
    END IF;
    
    RAISE NOTICE 'Contraintes de validation vérifiées/ajoutées';
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
BEGIN
    RAISE NOTICE '=== TEST FINAL ===';
    
    -- Tester la jointure
    SELECT COUNT(*) INTO test_count
    FROM public.expenses e
    JOIN public.expense_categories ec ON e.category_id = ec.id
    LIMIT 1;
    
    RAISE NOTICE 'Test de jointure réussi: % enregistrements trouvés', test_count;
    
    -- Vérifier qu'il n'y a plus de colonnes problématiques
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ATTENTION: La colonne "category" existe encore !';
    ELSE
        RAISE NOTICE 'OK: La colonne "category" a été supprimée';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'date'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ATTENTION: La colonne "date" existe encore !';
    ELSE
        RAISE NOTICE 'OK: La colonne "date" a été supprimée';
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
    (SELECT COUNT(*) FROM public.expenses e JOIN public.expense_categories ec ON e.category_id = ec.id) as joined_count;
