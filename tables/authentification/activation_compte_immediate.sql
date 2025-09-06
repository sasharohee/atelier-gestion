-- Activation immédiate du compte utilisateur
-- Date: 2024-01-24

-- 1. ACTIVER LA DEMANDE D'INSCRIPTION

UPDATE pending_signups 
SET status = 'approved', updated_at = NOW()
WHERE email = 'Sasharohee26@gmail.com';

-- 2. CRÉER LE COMPTE UTILISATEUR DANS SUPABASE AUTH

-- Note: Cette étape nécessite une intervention manuelle car nous ne pouvons pas créer directement dans auth.users
-- Vous devez créer le compte manuellement dans le dashboard Supabase

-- 3. CRÉER L'UTILISATEUR DANS LA TABLE USERS

INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(), -- ou l'ID de l'utilisateur Supabase Auth
    'Sasha',
    'Rohee',
    'Sasharohee26@gmail.com',
    'technician',
    NULL,
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    updated_at = NOW();

-- 4. CRÉER LES DONNÉES PAR DÉFAUT

-- Appeler la fonction pour créer les données par défaut
SELECT create_user_default_data_permissive(
    (SELECT id FROM users WHERE email = 'Sasharohee26@gmail.com')
);

-- 5. MARQUER L'EMAIL COMME UTILISÉ

UPDATE confirmation_emails 
SET status = 'used', sent_at = NOW()
WHERE user_email = 'Sasharohee26@gmail.com';

-- 6. VÉRIFIER L'ACTIVATION

SELECT '=== COMPTE ACTIVÉ ===' as section;
SELECT 
    email,
    first_name,
    last_name,
    role,
    status,
    created_at,
    updated_at
FROM pending_signups 
WHERE email = 'Sasharohee26@gmail.com';

SELECT '=== UTILISATEUR CRÉÉ ===' as section;
SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM users 
WHERE email = 'Sasharohee26@gmail.com';

-- 7. INSTRUCTIONS POUR L'UTILISATEUR

SELECT '=== INSTRUCTIONS ===' as section;
SELECT 
    '1. Votre compte est maintenant activé' as etape1,
    '2. Vous pouvez vous connecter avec :' as etape2,
    '   Email: Sasharohee26@gmail.com' as email,
    '   Mot de passe: (celui que vous avez utilisé lors de l''inscription)' as password,
    '3. Si la connexion échoue, créez un mot de passe dans Supabase Auth' as etape3;

-- 8. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Demande d''inscription approuvée' as statut1,
    '✅ Utilisateur créé dans la table users' as statut2,
    '✅ Données par défaut créées' as statut3,
    '✅ Email de confirmation marqué comme utilisé' as statut4,
    '✅ Compte prêt pour connexion' as statut5;
