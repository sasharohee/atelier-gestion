-- Script de correction sécurisé pour la table expenses
-- Ce script évite les erreurs de contraintes existantes

-- 1. Diagnostic initial
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSTIC INITIAL ===';
    
    -- Vérifier si la table existe
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
    ELSE
        RAISE NOTICE 'OK: La colonne "category" n''existe pas';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'OK: La colonne "category_id" existe';
    ELSE
        RAISE NOTICE 'PROBLÈME: La colonne "category_id" n''existe pas';
    END IF;
END $$;

-- 2. Supprimer la colonne category si elle existe
DO $$
BEGIN
    RAISE NOTICE '=== SUPPRESSION DE LA COLONNE CATEGORY ===';
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses DROP COLUMN category;
        RAISE NOTICE 'Colonne "category" supprimée';
    ELSE
        RAISE NOTICE 'Colonne "category" n''existe pas, pas de suppression nécessaire';
    END IF;
END $$;

-- 3. S'assurer que category_id existe
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE CATEGORY_ID ===';
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN category_id UUID;
        RAISE NOTICE 'Colonne category_id ajoutée';
    ELSE
        RAISE NOTICE 'Colonne category_id existe déjà';
    END IF;
END $$;

-- 4. S'assurer que expense_categories existe
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE EXPENSE_CATEGORIES ===';
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expense_categories' 
        AND table_schema = 'public'
    ) THEN
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

-- 7. Établir la contrainte de clé étrangère (sans erreur si elle existe)
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

-- 8. Ajouter les colonnes manquantes (sans erreur si elles existent)
DO $$
BEGIN
    RAISE NOTICE '=== AJOUT DES COLONNES MANQUANTES ===';
    
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
    
    RAISE NOTICE 'Toutes les colonnes ont été vérifiées/ajoutées';
END $$;

-- 9. Ajouter les contraintes de validation (sans erreur si elles existent)
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

-- 10. Créer les index (sans erreur si ils existent)
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON public.expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON public.expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_due_date ON public.expenses(due_date);
CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON public.expense_categories(user_id);

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

-- 12. Résumé final
SELECT 
    'Résumé final' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count,
    (SELECT COUNT(*) FROM public.expenses e JOIN public.expense_categories ec ON e.category_id = ec.id) as joined_count;
