-- Script de diagnostic pour vérifier les contraintes de la table expenses
-- Ce script vérifie l'état actuel des contraintes et colonnes

-- 1. Vérifier l'existence de la table
SELECT 
    'Table existence' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'expenses' AND table_schema = 'public')
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- 2. Vérifier les colonnes existantes
SELECT 
    'Current columns' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Vérifier les contraintes existantes
SELECT 
    'Existing constraints' as check_type,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'expenses'
AND table_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- 4. Vérifier les contraintes de clé étrangère
SELECT 
    'Foreign key constraints' as check_type,
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
AND tc.table_name = 'expenses'
AND tc.table_schema = 'public';

-- 5. Vérifier les politiques RLS
SELECT 
    'RLS Policies' as check_type,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'expenses'
ORDER BY policyname;

-- 6. Vérifier les index
SELECT 
    'Indexes' as check_type,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'expenses'
AND schemaname = 'public'
ORDER BY indexname;

-- 7. Vérifier les données
SELECT 
    'Data check' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(category_id) as with_category_id,
    COUNT(expense_date) as with_expense_date,
    COUNT(status) as with_status
FROM public.expenses;

-- 8. Test de jointure (si possible)
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
