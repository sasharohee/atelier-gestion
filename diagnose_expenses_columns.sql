-- Diagnostic complet de la structure de la table expenses
-- Ce script vérifie toutes les colonnes attendues par le code

-- 1. Vérifier l'existence de la table
SELECT 
    'Table existence' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'expenses' AND table_schema = 'public')
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- 2. Lister toutes les colonnes actuelles de expenses
SELECT 
    'Current columns' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Vérifier les colonnes attendues par le code
-- Colonnes attendues basées sur les erreurs et le code de service
WITH expected_columns AS (
    SELECT unnest(ARRAY[
        'id', 'user_id', 'title', 'description', 'amount', 
        'category_id', 'supplier', 'invoice_number', 'payment_method', 
        'status', 'expense_date', 'due_date', 'receipt_path', 'tags',
        'created_at', 'updated_at'
    ]) as column_name
),
actual_columns AS (
    SELECT column_name
    FROM information_schema.columns 
    WHERE table_name = 'expenses' 
    AND table_schema = 'public'
)
SELECT 
    'Missing columns' as check_type,
    ec.column_name,
    CASE 
        WHEN ac.column_name IS NULL THEN 'MISSING'
        ELSE 'EXISTS'
    END as status
FROM expected_columns ec
LEFT JOIN actual_columns ac ON ec.column_name = ac.column_name
ORDER BY ec.column_name;

-- 4. Vérifier les contraintes et clés
SELECT 
    'Constraints' as check_type,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'expenses'
AND table_schema = 'public';

-- 5. Vérifier les contraintes de clé étrangère
SELECT 
    'Foreign Keys' as check_type,
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

-- 6. Vérifier les données existantes
SELECT 
    'Data check' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM public.expenses;

-- 7. Tester une requête simple
SELECT 
    'Simple query test' as check_type,
    COUNT(*) as result_count
FROM public.expenses
WHERE user_id IS NOT NULL;
