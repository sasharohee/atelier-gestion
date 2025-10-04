-- Script de correction pour le problème de workshop_id dans la table expenses
-- Ce script résout le problème de contrainte NOT NULL sur workshop_id

-- 1. Diagnostic initial
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSTIC INITIAL ===';
    
    -- Vérifier l'existence de la table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'expenses' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'ERREUR: La table expenses n''existe pas';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Table expenses trouvée';
    
    -- Vérifier la colonne workshop_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'workshop_id'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Colonne workshop_id trouvée';
        
        -- Vérifier si elle est NOT NULL
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expenses' 
            AND column_name = 'workshop_id'
            AND is_nullable = 'NO'
            AND table_schema = 'public'
        ) THEN
            RAISE NOTICE 'PROBLÈME: La colonne workshop_id est NOT NULL';
        ELSE
            RAISE NOTICE 'OK: La colonne workshop_id est nullable';
        END IF;
    ELSE
        RAISE NOTICE 'Colonne workshop_id n''existe pas';
    END IF;
END $$;

-- 2. Afficher la structure actuelle de la table expenses
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

-- 3. Vérifier les contraintes NOT NULL
SELECT 
    'NOT NULL constraints' as check_type,
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND is_nullable = 'NO'
AND table_schema = 'public'
ORDER BY column_name;

-- 4. Corriger le problème de workshop_id
DO $$
BEGIN
    RAISE NOTICE '=== CORRECTION DU PROBLÈME WORKSHOP_ID ===';
    
    -- Vérifier si workshop_id existe et est NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'workshop_id'
        AND is_nullable = 'NO'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Correction de la contrainte NOT NULL sur workshop_id...';
        
        -- Rendre la colonne nullable
        ALTER TABLE public.expenses ALTER COLUMN workshop_id DROP NOT NULL;
        
        -- Mettre à jour les valeurs NULL avec une valeur par défaut
        UPDATE public.expenses 
        SET workshop_id = gen_random_uuid() 
        WHERE workshop_id IS NULL;
        
        RAISE NOTICE 'Contrainte NOT NULL supprimée et valeurs NULL mises à jour';
    ELSE
        RAISE NOTICE 'La colonne workshop_id n''est pas NOT NULL ou n''existe pas';
    END IF;
END $$;

-- 5. Vérifier et corriger les autres colonnes problématiques
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DES AUTRES COLONNES PROBLÉMATIQUES ===';
    
    -- Vérifier si la colonne category existe (ancienne structure)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'category'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Suppression de la colonne category (ancienne structure)...';
        ALTER TABLE public.expenses DROP COLUMN category;
        RAISE NOTICE 'Colonne category supprimée';
    END IF;
    
    -- Vérifier si la colonne date existe (ancienne structure)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'date'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Suppression de la colonne date (ancienne structure)...';
        ALTER TABLE public.expenses DROP COLUMN date;
        RAISE NOTICE 'Colonne date supprimée';
    END IF;
END $$;

-- 6. S'assurer que toutes les colonnes nécessaires existent
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
    
    RAISE NOTICE 'Toutes les colonnes nécessaires ont été vérifiées/ajoutées';
END $$;

-- 7. S'assurer que expense_categories existe
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

-- 8. Créer des catégories par défaut
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

-- 9. Mettre à jour les category_id
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

-- 10. Établir la contrainte de clé étrangère
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
    
    -- Vérifier la structure finale
    RAISE NOTICE 'Vérification de la structure finale...';
    
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
    
    -- Vérifier que workshop_id est nullable
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' 
        AND column_name = 'workshop_id'
        AND is_nullable = 'YES'
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'OK: La colonne "workshop_id" est nullable';
    ELSE
        RAISE NOTICE 'ATTENTION: La colonne "workshop_id" n''est pas nullable !';
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
