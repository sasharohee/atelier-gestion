-- Script immédiat pour créer une catégorie de dépense
-- À exécuter dans l'éditeur SQL de Supabase

-- Vérifier d'abord l'utilisateur actuel
SELECT auth.uid() as current_user_id;

-- Créer une catégorie "Général" pour l'utilisateur actuel
-- Vérifier d'abord si elle n'existe pas déjà
INSERT INTO expense_categories (user_id, name, description, color, is_active)
SELECT 
    auth.uid(),
    'Général',
    'Catégorie par défaut pour les dépenses',
    '#2196f3',
    true
WHERE NOT EXISTS (
    SELECT 1 FROM expense_categories 
    WHERE user_id = auth.uid() 
    AND name = 'Général'
);

-- Vérifier que la catégorie a été créée
SELECT 
    id,
    name,
    description,
    color,
    is_active,
    created_at
FROM expense_categories 
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
