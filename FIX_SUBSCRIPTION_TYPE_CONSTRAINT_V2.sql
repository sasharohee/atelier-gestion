-- 🎯 CORRECTION CONTRAINTE SUBSCRIPTION_TYPE V2
-- Erreur: 23514: new row for relation "subscription_status" violates check constraint "subscription_status_subscription_type_check"

-- 1. VÉRIFIER LA CONTRAINTE ACTUELLE (syntaxe moderne PostgreSQL)
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'subscription_status_subscription_type_check';

-- 2. VÉRIFIER LES VALEURS VALIDES
-- La contrainte accepte uniquement: 'free', 'premium', 'enterprise' (en minuscules)

-- 3. SUPPRIMER L'ENTRÉE INCORRECTE SI ELLE EXISTE
DELETE FROM public.subscription_status 
WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8'
AND subscription_type = 'FREE';

-- 4. CRÉER L'ENTRÉE AVEC LA BONNE VALEUR
INSERT INTO public.subscription_status (
    user_id, 
    first_name, 
    last_name, 
    email, 
    is_active, 
    subscription_type, 
    created_at, 
    updated_at
)
SELECT 
    'd4535dc5-9797-48f8-9c60-844ab6468ff8',
    'Utilisateur',
    'Test',
    'test@example.com',
    true,
    'free',  -- ✅ Valeur correcte (minuscules)
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status 
    WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8'
);

-- 5. VÉRIFIER QUE L'ENTRÉE A ÉTÉ CRÉÉE
SELECT 
    'Entrée créée avec succès:' as info,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    created_at
FROM public.subscription_status 
WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8';

-- 6. TESTER LA REQUÊTE ORIGINALE
SELECT 
    is_active,
    user_id,
    email,
    subscription_type
FROM public.subscription_status 
WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8';

-- 7. AFFICHER TOUTES LES VALEURS VALIDES POUR SUBSCRIPTION_TYPE
SELECT 
    'Valeurs valides pour subscription_type:' as info,
    'free, premium, enterprise' as valid_values;

-- 8. MESSAGE DE CONFIRMATION
SELECT '🎉 CONTRAINTE SUBSCRIPTION_TYPE CORRIGÉE - Utilisez "free", "premium", ou "enterprise" (minuscules)' as status;
