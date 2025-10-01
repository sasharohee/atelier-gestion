-- Script pour vérifier et corriger les politiques RLS de la table expenses
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les politiques RLS existantes pour la table expenses
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'expenses'
ORDER BY policyname;

-- 2. Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Users can view their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON expenses;

-- 3. Créer de nouvelles politiques RLS pour la table expenses
CREATE POLICY "Users can view their own expenses" ON expenses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own expenses" ON expenses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own expenses" ON expenses
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expenses" ON expenses
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Vérifier que les politiques ont été créées
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'expenses'
ORDER BY policyname;

-- 5. Tester la création d'une dépense de test
INSERT INTO expenses (
    user_id,
    title,
    description,
    amount,
    category_id,
    supplier,
    payment_method,
    status,
    expense_date
) VALUES (
    auth.uid(),
    'Test dépense',
    'Dépense de test pour vérifier les politiques RLS',
    25.00,
    (SELECT id FROM expense_categories WHERE user_id = auth.uid() LIMIT 1),
    'Test Supplier',
    'card',
    'pending',
    CURRENT_DATE
);

-- 6. Vérifier que la dépense a été créée
SELECT 
    id,
    user_id,
    title,
    amount,
    status,
    created_at
FROM expenses 
WHERE user_id = auth.uid()
ORDER BY created_at DESC
LIMIT 5;
