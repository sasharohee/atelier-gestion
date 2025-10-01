-- Script simple pour créer une catégorie de dépense
-- À exécuter dans l'éditeur SQL de Supabase

-- Vérifier l'utilisateur actuel
SELECT auth.uid() as current_user_id;

-- Vérifier s'il existe déjà des catégories
SELECT COUNT(*) as existing_categories_count
FROM expense_categories 
WHERE user_id = auth.uid();

-- Créer une catégorie simple si aucune n'existe
DO $$
BEGIN
    -- Vérifier si l'utilisateur a déjà des catégories
    IF NOT EXISTS (
        SELECT 1 FROM expense_categories 
        WHERE user_id = auth.uid()
    ) THEN
        -- Créer une catégorie "Général"
        INSERT INTO expense_categories (user_id, name, description, color, is_active)
        VALUES (
            auth.uid(),
            'Général',
            'Catégorie par défaut pour les dépenses',
            '#2196f3',
            true
        );
        
        RAISE NOTICE 'Catégorie "Général" créée avec succès';
    ELSE
        RAISE NOTICE 'Des catégories existent déjà pour cet utilisateur';
    END IF;
END $$;

-- Vérifier le résultat
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
