-- Diagnostic rapide des tables expenses et expense_categories

-- 1. Vérifier l'existence des tables
SELECT 
    'Tables' as type,
    table_name,
    CASE 
        WHEN table_name = 'expenses' THEN 'expenses'
        WHEN table_name = 'expense_categories' THEN 'expense_categories'
    END as table_type
FROM information_schema.tables 
WHERE table_name IN ('expenses', 'expense_categories')
AND table_schema = 'public';

-- 2. Vérifier la structure de expense_categories
SELECT 
    'expense_categories structure' as type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'expense_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Vérifier les contraintes sur expense_categories
SELECT 
    'expense_categories constraints' as type,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'expense_categories'
AND table_schema = 'public';

-- 4. Vérifier la structure de expenses
SELECT 
    'expenses structure' as type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Vérifier les contraintes sur expenses
SELECT 
    'expenses constraints' as type,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'expenses'
AND table_schema = 'public';

-- 6. Compter les données
SELECT 
    'Data counts' as type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count;
