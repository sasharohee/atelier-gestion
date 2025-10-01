-- Script pour créer une catégorie de dépense automatiquement
-- À exécuter dans l'éditeur SQL de Supabase

-- Récupérer tous les utilisateurs et créer des catégories pour chacun
DO $$
DECLARE
    user_record RECORD;
BEGIN
    -- Parcourir tous les utilisateurs
    FOR user_record IN 
        SELECT id FROM auth.users 
        WHERE id IS NOT NULL
    LOOP
        -- Vérifier si l'utilisateur a déjà des catégories
        IF NOT EXISTS (
            SELECT 1 FROM expense_categories 
            WHERE user_id = user_record.id
        ) THEN
            -- Créer une catégorie "Général" pour cet utilisateur
            INSERT INTO expense_categories (user_id, name, description, color, is_active)
            VALUES (
                user_record.id,
                'Général',
                'Catégorie par défaut pour les dépenses',
                '#2196f3',
                true
            );
            
            RAISE NOTICE 'Catégorie "Général" créée pour l''utilisateur %', user_record.id;
        ELSE
            RAISE NOTICE 'L''utilisateur % a déjà des catégories', user_record.id;
        END IF;
    END LOOP;
END $$;

-- Vérifier le résultat pour tous les utilisateurs
SELECT 
    user_id,
    name,
    description,
    color,
    is_active,
    created_at
FROM expense_categories 
ORDER BY user_id, created_at DESC;
