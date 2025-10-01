-- Script de test pour créer une dépense avec l'ID utilisateur spécifique
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier que les politiques RLS sont correctes
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'expenses';

-- 2. Récupérer l'ID de la catégorie "Général" pour votre utilisateur
SELECT 
    id as category_id,
    name,
    user_id
FROM expense_categories 
WHERE user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a'::uuid
AND name = 'Général'
LIMIT 1;

-- 3. Créer une dépense de test avec l'ID utilisateur spécifique
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
    '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a'::uuid,
    'Test dépense SQL',
    'Dépense de test créée via SQL',
    25.00,
    (SELECT id FROM expense_categories 
     WHERE user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a'::uuid 
     AND name = 'Général' 
     LIMIT 1),
    'Test Supplier',
    'card',
    'pending',
    CURRENT_DATE
);

-- 4. Vérifier que la dépense a été créée
SELECT 
    id,
    user_id,
    title,
    amount,
    status,
    created_at
FROM expenses 
WHERE user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a'::uuid
ORDER BY created_at DESC
LIMIT 5;
