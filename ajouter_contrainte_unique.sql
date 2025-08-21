-- AJOUTER UNE CONTRAINTE UNIQUE SUR USER_ID ET KEY
-- Ce script ajoute une contrainte pour éviter les doublons

-- 1. SUPPRIMER LES DOUBLONS EXISTANTS (SI IL Y EN A)
DELETE FROM public.system_settings 
WHERE id NOT IN (
  SELECT MIN(id) 
  FROM public.system_settings 
  GROUP BY user_id, key
);

-- 2. AJOUTER LA CONTRAINTE UNIQUE
ALTER TABLE public.system_settings 
ADD CONSTRAINT unique_user_key UNIQUE (user_id, key);

-- 3. VÉRIFICATION
SELECT 
    'Contrainte ajoutée' as status,
    COUNT(*) as total_settings
FROM public.system_settings;
