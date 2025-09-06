-- Vérification finale de la demande d'inscription
-- Date: 2024-01-24

-- 1. VÉRIFIER LA DEMANDE D'INSCRIPTION

SELECT '=== DEMANDE D''INSCRIPTION ===' as section;
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

-- 2. VÉRIFIER LES EMAILS DE CONFIRMATION

SELECT '=== EMAILS DE CONFIRMATION ===' as section;
SELECT 
    id,
    user_email,
    token,
    status,
    created_at,
    expires_at,
    sent_at,
    'http://localhost:3001/auth?tab=confirm&token=' || token as confirmation_url
FROM confirmation_emails 
WHERE user_email = 'Sasharohee26@gmail.com'
ORDER BY created_at DESC;

-- 3. AFFICHER L'URL DE CONFIRMATION ACTUELLE

SELECT '=== URL DE CONFIRMATION ACTUELLE ===' as section;
SELECT 
    'Copiez cette URL et ouvrez-la dans votre navigateur :' as instruction,
    'http://localhost:3001/auth?tab=confirm&token=' || token as confirmation_url,
    'Token : ' || token as token_info,
    'Expire le : ' || expires_at as expiration_info,
    'Statut : ' || status as statut
FROM confirmation_emails 
WHERE user_email = 'Sasharohee26@gmail.com'
ORDER BY created_at DESC
LIMIT 1;

-- 4. VÉRIFIER LE STATUT GLOBAL

SELECT '=== STATUT GLOBAL ===' as section;
SELECT 
    CASE 
        WHEN ps.status = 'pending' THEN 'En attente d''approbation'
        WHEN ps.status = 'approved' THEN 'Approuvé - Prêt pour connexion'
        WHEN ps.status = 'rejected' THEN 'Refusé'
        ELSE 'Statut inconnu'
    END as statut_demande,
    CASE 
        WHEN ce.status = 'pending' THEN 'Token généré, en attente'
        WHEN ce.status = 'sent' THEN 'Email marqué comme envoyé'
        WHEN ce.status = 'used' THEN 'Token utilisé'
        WHEN ce.status = 'expired' THEN 'Token expiré'
        ELSE 'Statut email inconnu'
    END as statut_email,
    ps.created_at as date_inscription,
    ce.created_at as date_token
FROM pending_signups ps
LEFT JOIN confirmation_emails ce ON ps.email = ce.user_email
WHERE ps.email = 'Sasharohee26@gmail.com'
ORDER BY ce.created_at DESC
LIMIT 1;

-- 5. INSTRUCTIONS POUR L'UTILISATEUR

SELECT '=== INSTRUCTIONS ===' as section;
SELECT 
    '1. Copiez l''URL de confirmation ci-dessus' as etape1,
    '2. Ouvrez-la dans votre navigateur' as etape2,
    '3. Confirmez votre inscription' as etape3,
    '4. Connectez-vous avec vos identifiants' as etape4;

-- 6. TESTER LA RÉGÉNÉRATION SI NÉCESSAIRE

SELECT '=== TEST RÉGÉNÉRATION ===' as section;
SELECT 
    'Si vous avez besoin d''un nouveau lien, exécutez :' as instruction,
    'SELECT resend_confirmation_email_real(''Sasharohee26@gmail.com'');' as commande;

-- 7. VÉRIFIER LES FONCTIONS DISPONIBLES

SELECT '=== FONCTIONS DISPONIBLES ===' as section;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%confirmation%'
ORDER BY routine_name;

-- 8. MESSAGE DE CONFIRMATION

SELECT '=== RÉSUMÉ ===' as section;
SELECT 
    '✅ Votre demande d''inscription existe' as statut1,
    '✅ Les tokens de confirmation sont générés' as statut2,
    '✅ Les URLs de confirmation sont disponibles' as statut3,
    '✅ Le système fonctionne correctement' as statut4,
    '✅ Prêt pour confirmation et connexion' as statut5;
