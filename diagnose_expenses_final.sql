-- Diagnostic final complet de la table expenses
-- Ce script identifie tous les problèmes de structure

-- 1. Vérifier l'existence des tables
SELECT 
    'Tables existence' as check_type,
    table_name,
    CASE 
        WHEN table_name = 'expenses' THEN 'expenses'
        WHEN table_name = 'expense_categories' THEN 'expense_categories'
    END as table_type
FROM information_schema.tables 
WHERE table_name IN ('expenses', 'expense_categories')
AND table_schema = 'public';

-- 2. Structure complète de la table expenses
SELECT 
    'expenses structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Structure de la table expense_categories
SELECT 
    'expense_categories structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'expense_categories' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Contraintes sur expenses
SELECT 
    'expenses constraints' as check_type,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'expenses'
AND table_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- 5. Contraintes de clé étrangère
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
AND tc.table_name IN ('expenses', 'expense_categories')
AND tc.table_schema = 'public';

-- 6. Politiques RLS
SELECT 
    'RLS Policies' as check_type,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('expenses', 'expense_categories')
ORDER BY tablename, policyname;

-- 7. Données existantes
SELECT 
    'Data counts' as check_type,
    (SELECT COUNT(*) FROM public.expenses) as expenses_count,
    (SELECT COUNT(*) FROM public.expense_categories) as categories_count;

-- 8. Vérifier les colonnes problématiques spécifiquement
SELECT 
    'Problematic columns check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'category' AND table_schema = 'public')
        THEN 'EXISTS - PROBLEM'
        ELSE 'NOT EXISTS - OK'
    END as category_column_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'category_id' AND table_schema = 'public')
        THEN 'EXISTS - OK'
        ELSE 'NOT EXISTS - PROBLEM'
    END as category_id_column_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'date' AND table_schema = 'public')
        THEN 'EXISTS - PROBLEM'
        ELSE 'NOT EXISTS - OK'
    END as date_column_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'expense_date' AND table_schema = 'public')
        THEN 'EXISTS - OK'
        ELSE 'NOT EXISTS - PROBLEM'
    END as expense_date_column_status;

-- 9. Test de jointure (si possible)
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

-- 10. Vérifier les contraintes NOT NULL
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
