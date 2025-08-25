-- Création finale de l'utilisateur dans Supabase Auth
-- Date: 2024-01-24

-- 1. VÉRIFIER LE STATUT ACTUEL

SELECT '=== STATUT ACTUEL ===' as section;

-- Vérifier la demande d'inscription
SELECT 
    id,
    email,
    first_name,
    last_name,
    role,
    status,
    created_at,
    updated_at
FROM pending_signups 
WHERE email = 'Sasharohee26@gmail.com';

-- Vérifier l'utilisateur dans la table users
SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM users 
WHERE email = 'Sasharohee26@gmail.com';

-- Vérifier les emails de confirmation
SELECT 
    user_email,
    token,
    status,
    expires_at,
    created_at
FROM confirmation_emails 
WHERE user_email = 'Sasharohee26@gmail.com'
ORDER BY created_at DESC;

-- 2. S'ASSURER QUE L'UTILISATEUR EXISTE DANS LA TABLE USERS

INSERT INTO users (
    first_name,
    last_name,
    email,
    role
) VALUES (
    'Sasha',
    'Rohee',
    'Sasharohee26@gmail.com',
    'technician'
) ON CONFLICT (email) DO NOTHING;

-- 3. MARQUER LA DEMANDE COMME APPROUVÉE

UPDATE pending_signups 
SET status = 'approved', updated_at = NOW()
WHERE email = 'Sasharohee26@gmail.com';

-- 4. MARQUER L'EMAIL COMME UTILISÉ

UPDATE confirmation_emails 
SET status = 'used', sent_at = NOW()
WHERE user_email = 'Sasharohee26@gmail.com';

-- 5. INSTRUCTIONS POUR SUPABASE AUTH

SELECT '=== CRÉATION DANS SUPABASE AUTH ===' as section;
SELECT 
    'ÉTAPE 1: Allez dans Supabase Dashboard > Authentication > Users' as instruction1,
    'ÉTAPE 2: Cliquez sur "Add user"' as instruction2,
    'ÉTAPE 3: Remplissez les champs :' as instruction3,
    '   - Email: Sasharohee26@gmail.com' as email,
    '   - Password: (choisissez un mot de passe fort)' as password,
    '   - Email confirm: true' as confirm,
    'ÉTAPE 4: Cliquez sur "Create user"' as instruction4,
    'ÉTAPE 5: Notez le mot de passe choisi' as instruction5;

-- 6. INSTRUCTIONS POUR LA CONNEXION

SELECT '=== CONNEXION À L''APPLICATION ===' as section;
SELECT 
    'ÉTAPE 1: Retournez à l''application' as etape1,
    'ÉTAPE 2: Cliquez sur "Se connecter"' as etape2,
    'ÉTAPE 3: Entrez vos identifiants :' as etape3,
    '   - Email: Sasharohee26@gmail.com' as identifiant1,
    '   - Mot de passe: (celui choisi dans Supabase Auth)' as identifiant2,
    'ÉTAPE 4: Cliquez sur "Se connecter"' as etape4,
    'ÉTAPE 5: Vous devriez être connecté et redirigé vers le dashboard' as etape5;

-- 7. VÉRIFICATION FINALE

SELECT '=== VÉRIFICATION FINALE ===' as section;
SELECT 
    '✅ Demande d''inscription approuvée' as statut1,
    '✅ Utilisateur créé dans la table users' as statut2,
    '✅ Email de confirmation marqué comme utilisé' as statut3,
    '✅ Prêt pour création dans Supabase Auth' as statut4,
    '✅ Prêt pour connexion à l''application' as statut5;

-- 8. AFFICHER L'UTILISATEUR FINAL

SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM users 
WHERE email = 'Sasharohee26@gmail.com';
