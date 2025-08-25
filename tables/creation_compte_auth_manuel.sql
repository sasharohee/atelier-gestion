-- Création manuelle du compte dans Supabase Auth
-- Date: 2024-01-24

-- 1. ÉTAPES POUR CRÉER LE COMPTE DANS SUPABASE AUTH

SELECT '=== CRÉATION MANUELLE DU COMPTE ===' as section;
SELECT 
    '1. Allez dans votre dashboard Supabase' as etape1,
    '2. Cliquez sur "Authentication" dans le menu' as etape2,
    '3. Cliquez sur "Users" dans le sous-menu' as etape3,
    '4. Cliquez sur "Add user" ou "Invite user"' as etape4,
    '5. Remplissez les informations :' as etape5,
    '   - Email: Sasharohee26@gmail.com' as email,
    '   - Password: (choisissez un mot de passe)' as password,
    '   - Email confirm: true' as confirm,
    '6. Cliquez sur "Create user"' as etape6;

-- 2. ALTERNATIVE : UTILISER L'API SUPABASE

SELECT '=== ALTERNATIVE : API SUPABASE ===' as section;
SELECT 
    'Vous pouvez aussi utiliser cette commande curl :' as instruction,
    'curl -X POST "https://wlqyrmntfxwdvkzzsujv.supabase.co/auth/v1/admin/users"' as commande,
    '  -H "apikey: VOTRE_SERVICE_ROLE_KEY"' as header1,
    '  -H "Authorization: Bearer VOTRE_SERVICE_ROLE_KEY"' as header2,
    '  -H "Content-Type: application/json"' as header3,
    '  -d "{"email":"Sasharohee26@gmail.com","password":"VOTRE_MOT_DE_PASSE","email_confirm":true}"' as data;

-- 3. VÉRIFIER QUE LE COMPTE EXISTE

SELECT '=== VÉRIFICATION ===' as section;
SELECT 
    'Après création, vérifiez que le compte existe :' as instruction,
    'SELECT * FROM auth.users WHERE email = ''Sasharohee26@gmail.com'';' as commande;

-- 4. MISE À JOUR DE L'ID UTILISATEUR

SELECT '=== MISE À JOUR ID UTILISATEUR ===' as section;
SELECT 
    'Une fois le compte créé, mettez à jour l''ID :' as instruction,
    'UPDATE users SET id = (SELECT id FROM auth.users WHERE email = ''Sasharohee26@gmail.com'') WHERE email = ''Sasharohee26@gmail.com'';' as commande;

-- 5. INSTRUCTIONS FINALES

SELECT '=== INSTRUCTIONS FINALES ===' as section;
SELECT 
    '1. Créez le compte dans Supabase Auth (voir étapes ci-dessus)' as etape1,
    '2. Exécutez le script d''activation : tables/activation_compte_immediate.sql' as etape2,
    '3. Mettez à jour l''ID utilisateur si nécessaire' as etape3,
    '4. Testez la connexion avec vos identifiants' as etape4;

-- 6. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Suivez les étapes pour créer le compte dans Supabase Auth' as statut1,
    '✅ Puis exécutez le script d''activation' as statut2,
    '✅ Votre compte sera prêt pour connexion' as statut3;
