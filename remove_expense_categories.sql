-- Script pour supprimer les catégories de dépenses et permettre les dépenses sans catégorie
-- Ce script supprime la contrainte NOT NULL sur category_id

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
            RAISE NOTICE 'Colonne category_id est NOT NULL - sera rendue nullable';
        ELSE
            RAISE NOTICE 'Colonne category_id est déjà nullable';
        END IF;
    ELSE
        RAISE NOTICE 'Colonne category_id n''existe pas - sera ajoutée comme nullable';
    END IF;
END $$;

-- 2. Rendre category_id nullable
DO $$
BEGIN
    RAISE NOTICE '=== RENDRE CATEGORY_ID NULLABLE ===';
    
    -- Vérifier si category_id existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        -- Rendre la colonne nullable
        ALTER TABLE public.expenses ALTER COLUMN category_id DROP NOT NULL;
        RAISE NOTICE 'Colonne category_id rendue nullable';
    ELSE
        -- Ajouter la colonne category_id comme nullable
        ALTER TABLE public.expenses ADD COLUMN category_id UUID;
        RAISE NOTICE 'Colonne category_id ajoutée comme nullable';
    END IF;
END $$;

-- 3. Supprimer la contrainte de clé étrangère si elle existe
DO $$
BEGIN
    RAISE NOTICE '=== SUPPRESSION DE LA CONTRAINTE FK ===';
    
    -- Supprimer la contrainte de clé étrangère si elle existe
    ALTER TABLE public.expenses DROP CONSTRAINT IF EXISTS fk_expenses_category_id;
    RAISE NOTICE 'Contrainte de clé étrangère supprimée';
END $$;

-- 4. S'assurer que toutes les colonnes nécessaires existent
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

-- 5. Supprimer les colonnes problématiques si elles existent
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
        RAISE NOTICE 'Colonne category supprimée';
    END IF;
    
    -- Supprimer la colonne date si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses DROP COLUMN date;
        RAISE NOTICE 'Colonne date supprimée';
    END IF;
END $$;

-- 6. Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON public.expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_due_date ON public.expenses(due_date);

-- 7. Configurer RLS
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
    
    RAISE NOTICE 'RLS configuré';
END $$;

-- 8. Test final
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    RAISE NOTICE '=== TEST FINAL ===';
    
    -- Vérifier que category_id est nullable
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND is_nullable = 'YES'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'OK: La colonne category_id est nullable';
    ELSE
        RAISE NOTICE 'ERREUR: La colonne category_id n''est pas nullable !';
    END IF;
    
    -- Vérifier que les colonnes nécessaires existent
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'expense_date'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'OK: La colonne expense_date existe';
    ELSE
        RAISE NOTICE 'ERREUR: La colonne expense_date n''existe pas !';
    END IF;
    
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
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du test: %', SQLERRM;
END $$;

-- 9. Résumé final
SELECT 
    'Résumé final' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expenses WHERE category_id IS NULL) as expenses_without_category;
