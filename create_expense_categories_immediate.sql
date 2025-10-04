-- Script immédiat pour créer les catégories de dépenses par défaut
-- Ce script résout le problème en créant les catégories nécessaires

-- 1. Vérifier l'existence de la table expense_categories
DO $$
BEGIN
    RAISE NOTICE '=== VÉRIFICATION DE LA TABLE EXPENSE_CATEGORIES ===';
    
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
END $$;

-- 2. Créer des catégories par défaut pour tous les utilisateurs existants
DO $$
DECLARE
    user_record RECORD;
    category_count INTEGER;
BEGIN
    RAISE NOTICE '=== CRÉATION DES CATÉGORIES PAR DÉFAUT ===';
    
    -- Créer des catégories par défaut pour chaque utilisateur
    FOR user_record IN 
        SELECT DISTINCT user_id FROM public.expenses 
        WHERE user_id IS NOT NULL
    LOOP
        -- Vérifier si l'utilisateur a déjà des catégories
        SELECT COUNT(*) INTO category_count
        FROM public.expense_categories 
        WHERE user_id = user_record.user_id;
        
        IF category_count = 0 THEN
            -- Créer plusieurs catégories par défaut pour cet utilisateur
            INSERT INTO public.expense_categories (
                id, name, description, color, is_active, 
                user_id, workshop_id, created_by, 
                created_at, updated_at
            ) VALUES 
            (
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
            ),
            (
                gen_random_uuid(),
                'Fournitures',
                'Fournitures de bureau et matériel',
                '#4CAF50',
                true,
                user_record.user_id,
                gen_random_uuid(),
                user_record.user_id,
                NOW(),
                NOW()
            ),
            (
                gen_random_uuid(),
                'Équipement',
                'Achat d''équipement technique',
                '#FF9800',
                true,
                user_record.user_id,
                gen_random_uuid(),
                user_record.user_id,
                NOW(),
                NOW()
            ),
            (
                gen_random_uuid(),
                'Transport',
                'Frais de transport et déplacement',
                '#F44336',
                true,
                user_record.user_id,
                gen_random_uuid(),
                user_record.user_id,
                NOW(),
                NOW()
            ),
            (
                gen_random_uuid(),
                'Autres',
                'Autres dépenses',
                '#9E9E9E',
                true,
                user_record.user_id,
                gen_random_uuid(),
                user_record.user_id,
                NOW(),
                NOW()
            );
            
            RAISE NOTICE 'Catégories par défaut créées pour l''utilisateur %', user_record.user_id;
        ELSE
            RAISE NOTICE 'L''utilisateur % a déjà des catégories', user_record.user_id;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Catégories par défaut créées pour tous les utilisateurs';
END $$;

-- 3. Créer des catégories pour l'utilisateur spécifique mentionné dans l'erreur
DO $$
DECLARE
    specific_user_id UUID := 'e454cc8c-3e40-4f72-bf26-4f6f43e78d0b';
    category_count INTEGER;
BEGIN
    RAISE NOTICE '=== CRÉATION DES CATÉGORIES POUR L''UTILISATEUR SPÉCIFIQUE ===';
    
    -- Vérifier si l'utilisateur a déjà des catégories
    SELECT COUNT(*) INTO category_count
    FROM public.expense_categories 
    WHERE user_id = specific_user_id;
    
    IF category_count = 0 THEN
        -- Créer des catégories par défaut pour cet utilisateur spécifique
        INSERT INTO public.expense_categories (
            id, name, description, color, is_active, 
            user_id, workshop_id, created_by, 
            created_at, updated_at
        ) VALUES 
        (
            gen_random_uuid(),
            'Général',
            'Catégorie par défaut',
            '#3B82F6',
            true,
            specific_user_id,
            gen_random_uuid(),
            specific_user_id,
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            'Fournitures',
            'Fournitures de bureau et matériel',
            '#4CAF50',
            true,
            specific_user_id,
            gen_random_uuid(),
            specific_user_id,
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            'Équipement',
            'Achat d''équipement technique',
            '#FF9800',
            true,
            specific_user_id,
            gen_random_uuid(),
            specific_user_id,
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            'Transport',
            'Frais de transport et déplacement',
            '#F44336',
            true,
            specific_user_id,
            gen_random_uuid(),
            specific_user_id,
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            'Autres',
            'Autres dépenses',
            '#9E9E9E',
            true,
            specific_user_id,
            gen_random_uuid(),
            specific_user_id,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Catégories créées pour l''utilisateur spécifique %', specific_user_id;
    ELSE
        RAISE NOTICE 'L''utilisateur spécifique % a déjà des catégories', specific_user_id;
    END IF;
END $$;

-- 4. Mettre à jour les expenses existants avec category_id
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== MISE À JOUR DES EXPENSES EXISTANTS ===';
    
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
END $$;

-- 5. Configurer RLS pour expense_categories
DO $$
BEGIN
    RAISE NOTICE '=== CONFIGURATION RLS POUR EXPENSE_CATEGORIES ===';
    
    -- Activer RLS
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
    
    RAISE NOTICE 'RLS configuré pour expense_categories';
END $$;

-- 6. Test final
DO $$
DECLARE
    test_count INTEGER;
    categories_for_user INTEGER;
BEGIN
    RAISE NOTICE '=== TEST FINAL ===';
    
    -- Vérifier les catégories pour l'utilisateur spécifique
    SELECT COUNT(*) INTO categories_for_user
    FROM public.expense_categories 
    WHERE user_id = 'e454cc8c-3e40-4f72-bf26-4f6f43e78d0b';
    
    RAISE NOTICE 'Catégories disponibles pour l''utilisateur spécifique: %', categories_for_user;
    
    -- Tester une requête simple
    SELECT COUNT(*) INTO test_count
    FROM public.expense_categories;
    
    RAISE NOTICE 'Total des catégories dans la base: %', test_count;
    
    -- Vérifier qu'il n'y a plus d'expenses sans category_id
    SELECT COUNT(*) INTO test_count
    FROM public.expenses 
    WHERE category_id IS NULL;
    
    IF test_count = 0 THEN
        RAISE NOTICE 'OK: Tous les expenses ont un category_id';
    ELSE
        RAISE NOTICE 'ATTENTION: % expenses n''ont pas de category_id', test_count;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du test: %', SQLERRM;
END $$;

-- 7. Résumé final
SELECT 
    'Résumé final' as check_type,
    (SELECT COUNT(*) FROM public.expense_categories) as total_categories,
    (SELECT COUNT(*) FROM public.expense_categories WHERE user_id = 'e454cc8c-3e40-4f72-bf26-4f6f43e78d0b') as categories_for_specific_user,
    (SELECT COUNT(*) FROM public.expenses) as total_expenses,
    (SELECT COUNT(*) FROM public.expenses WHERE category_id IS NULL) as expenses_without_category;
