-- Script pour créer une catégorie de dépense avec l'ID utilisateur spécifique
-- À exécuter dans l'éditeur SQL de Supabase

-- Remplacer 'VOTRE_USER_ID_ICI' par l'ID de votre utilisateur
-- Vous pouvez trouver votre ID utilisateur dans les logs de l'application : 13d6e91c-8f4b-415a-b165-d5f8b4b0f72a

-- Créer une catégorie "Général" pour l'utilisateur spécifique
INSERT INTO expense_categories (user_id, name, description, color, is_active)
VALUES (
    '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a'::uuid,
    'Général',
    'Catégorie par défaut pour les dépenses',
    '#2196f3',
    true
);

-- Vérifier que la catégorie a été créée
SELECT 
    id,
    user_id,
    name,
    description,
    color,
    is_active,
    created_at
FROM expense_categories 
WHERE user_id = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a'::uuid
ORDER BY created_at DESC;
