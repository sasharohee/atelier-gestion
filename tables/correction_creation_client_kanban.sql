-- Correction du problème de création de client via Kanban
-- Erreur: "null value in column "user_id" of relation "clients" violates not-null constraint"

-- 1. Vérifier la structure actuelle de la table clients
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes sur la table clients
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND table_schema = 'public';

-- 3. Option 1: Rendre user_id nullable (si vous voulez permettre des clients sans utilisateur)
-- ALTER TABLE public.clients ALTER COLUMN user_id DROP NOT NULL;

-- 4. Option 2: Ajouter une valeur par défaut (recommandé)
-- Créer un utilisateur système par défaut
INSERT INTO public.users (id, first_name, last_name, email, role, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Système',
    'Par défaut',
    'system@atelier.com',
    'admin',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 5. Modifier la contrainte pour utiliser l'utilisateur système par défaut
ALTER TABLE public.clients 
ALTER COLUMN user_id SET DEFAULT '00000000-0000-0000-0000-000000000000';

-- 6. Mettre à jour les clients existants sans user_id
UPDATE public.clients 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

-- 7. Vérifier que tous les clients ont maintenant un user_id
SELECT 
    COUNT(*) as total_clients,
    COUNT(user_id) as clients_with_user_id,
    COUNT(*) - COUNT(user_id) as clients_without_user_id
FROM public.clients;

-- 8. Vérification finale
SELECT 
    'Correction terminée' as status,
    COUNT(*) as total_clients,
    COUNT(DISTINCT user_id) as unique_users
FROM public.clients;
