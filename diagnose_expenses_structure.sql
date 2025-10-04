-- Script de diagnostic pour vérifier la structure des tables expenses et expense_categories

-- 1. Vérifier l'existence des tables
SELECT 
    'Tables existantes' as check_type,
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name IN ('expenses', 'expense_categories')
AND table_schema = 'public';

-- 2. Vérifier la structure de la table expenses
SELECT 
    'Structure de expenses' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Vérifier la structure de la table expense_categories
SELECT 
    'Structure de expense_categories' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'expense_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Vérifier les contraintes de clé étrangère
SELECT 
    'Contraintes FK' as check_type,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('expenses', 'expense_categories')
AND tc.table_schema = 'public';

-- 5. Vérifier les politiques RLS
SELECT 
    'Politiques RLS' as check_type,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('expenses', 'expense_categories')
ORDER BY tablename, policyname;

-- 6. Vérifier les données existantes
SELECT 
    'Données expenses' as check_type,
    COUNT(*) as total_expenses,
    COUNT(DISTINCT user_id) as users_with_expenses
FROM public.expenses;

SELECT 
    'Données expense_categories' as check_type,
    COUNT(*) as total_categories,
    COUNT(DISTINCT user_id) as users_with_categories
FROM public.expense_categories;

-- 7. Test de jointure (si possible)
DO $$
DECLARE
    join_test_result INTEGER;
BEGIN
    BEGIN
        SELECT COUNT(*) INTO join_test_result
        FROM public.expenses e
        JOIN public.expense_categories ec ON e.category_id = ec.id
        LIMIT 1;
        
        RAISE NOTICE 'Test de jointure réussi: % enregistrements trouvés', join_test_result;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Erreur lors du test de jointure: %', SQLERRM;
    END;
END $$;

-- 8. Vérifier les index
SELECT 
    'Index' as check_type,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('expenses', 'expense_categories')
AND schemaname = 'public'
ORDER BY tablename, indexname;
