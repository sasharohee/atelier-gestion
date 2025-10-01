-- Script pour récupérer l'ID de la catégorie "Général" de votre utilisateur
-- À exécuter dans l'éditeur SQL de Supabase

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
AND name = 'Général'
ORDER BY created_at DESC
LIMIT 1;
