-- Script de correction pour résoudre le conflit entre les colonnes category et category_id
-- Ce script corrige définitivement la structure de la table expenses

-- 1. Diagnostic de la structure actuelle
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSTIC DE LA STRUCTURE ACTUELLE ===';
    
    -- Vérifier les colonnes existantes
    PERFORM 1 FROM information_schema.columns 
    WHERE table_name = 'expenses' 
    AND column_name = 'category'
    AND table_schema = 'public';
    
    IF FOUND THEN
        RAISE NOTICE 'PROBLÈME: La colonne "category" (TEXT) existe encore';
    ELSE
        RAISE NOTICE 'OK: La colonne "category" n''existe pas';
    END IF;
    
    -- Vérifier category_id
    PERFORM 1 FROM information_schema.columns 
    WHERE table_name = 'expenses' 
    AND column_name = 'category_id'
    AND table_schema = 'public';
    
    IF FOUND THEN
        RAISE NOTICE 'OK: La colonne "category_id" existe';
    ELSE
        RAISE NOTICE 'PROBLÈME: La colonne "category_id" n''existe pas';
    END IF;
END $$;

-- 2. Afficher la structure actuelle
SELECT 
    'Structure actuelle' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
AND column_name IN ('category', 'category_id')
ORDER BY column_name;

-- 3. Supprimer la colonne category si elle existe
DO $$
BEGIN
    RAISE NOTICE '=== SUPPRESSION DE LA COLONNE CATEGORY ===';
    
    -- Vérifier si la colonne category existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category'
        AND table_schema = 'public'
    ) THEN
        -- Supprimer la colonne category
        ALTER TABLE public.expenses DROP COLUMN category;
        RAISE NOTICE 'Colonne "category" supprimée';
    ELSE
        RAISE NOTICE 'Colonne "category" n''existe pas, pas de suppression nécessaire';
    END IF;
END $$;

-- 4. S'assurer que category_id existe et est correctement configurée
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE CATEGORY_ID ===';
    
    -- Vérifier si category_id existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne category_id
        ALTER TABLE public.expenses ADD COLUMN category_id UUID;
        RAISE NOTICE 'Colonne category_id ajoutée';
    ELSE
        RAISE NOTICE 'Colonne category_id existe déjà';
    END IF;
    
    -- Vérifier le type de category_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND data_type != 'uuid'
        AND table_schema = 'public'
    ) THEN
        -- Corriger le type
        ALTER TABLE public.expenses ALTER COLUMN category_id TYPE UUID USING category_id::UUID;
        RAISE NOTICE 'Type de category_id corrigé vers UUID';
    END IF;
END $$;

-- 5. S'assurer que expense_categories a la bonne structure
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

-- 6. Créer des catégories par défaut si nécessaire
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

-- 7. Mettre à jour les expenses avec category_id
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

-- 8. Établir la contrainte de clé étrangère
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

-- 9. Vérifier que toutes les colonnes attendues existent
DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[]::TEXT[];
    col_name TEXT;
    expected_columns TEXT[] := ARRAY[
        'id', 'user_id', 'title', 'description', 'amount', 
        'category_id', 'supplier', 'invoice_number', 'payment_method', 
        'status', 'expense_date', 'due_date', 'receipt_path', 'tags',
        'created_at', 'updated_at'
    ];
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DES COLONNES ATTENDUES ===';
    
    FOREACH col_name IN ARRAY expected_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expenses' 
            AND column_name = col_name
            AND table_schema = 'public'
        ) THEN
            missing_columns := array_append(missing_columns, col_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) > 0 THEN
        RAISE NOTICE 'Colonnes manquantes: %', array_to_string(missing_columns, ', ');
        
        -- Ajouter les colonnes manquantes
        FOREACH col_name IN ARRAY missing_columns
        LOOP
            CASE col_name
                WHEN 'title' THEN
                    ALTER TABLE public.expenses ADD COLUMN title VARCHAR(255);
                WHEN 'description' THEN
                    ALTER TABLE public.expenses ADD COLUMN description TEXT;
                WHEN 'supplier' THEN
                    ALTER TABLE public.expenses ADD COLUMN supplier VARCHAR(255);
                WHEN 'invoice_number' THEN
                    ALTER TABLE public.expenses ADD COLUMN invoice_number VARCHAR(255);
                WHEN 'payment_method' THEN
                    ALTER TABLE public.expenses ADD COLUMN payment_method VARCHAR(20) DEFAULT 'card';
                WHEN 'status' THEN
                    ALTER TABLE public.expenses ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
                WHEN 'expense_date' THEN
                    ALTER TABLE public.expenses ADD COLUMN expense_date DATE;
                WHEN 'due_date' THEN
                    ALTER TABLE public.expenses ADD COLUMN due_date DATE;
                WHEN 'receipt_path' THEN
                    ALTER TABLE public.expenses ADD COLUMN receipt_path TEXT;
                WHEN 'tags' THEN
                    ALTER TABLE public.expenses ADD COLUMN tags TEXT[];
            END CASE;
            
            RAISE NOTICE 'Colonne % ajoutée', col_name;
        END LOOP;
    ELSE
        RAISE NOTICE 'Toutes les colonnes attendues existent';
    END IF;
END $$;

-- 10. Ajouter les contraintes de validation
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

-- 11. Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON public.expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_due_date ON public.expenses(due_date);
CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON public.expense_categories(user_id);

-- 12. Configurer RLS
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

-- 13. Test final
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
    
    -- Vérifier qu'il n'y a plus de colonne category
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
    
    -- Vérifier que category_id existe
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
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du test: %', SQLERRM;
END $$;

-- 14. Résumé final
SELECT 
    'Résumé final' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count,
    (SELECT COUNT(*) FROM public.expenses e JOIN public.expense_categories ec ON e.category_id = ec.id) as joined_count;
