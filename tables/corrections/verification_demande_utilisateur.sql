-- Vérification de la demande d'inscription de l'utilisateur
-- Date: 2024-01-24

-- 1. VÉRIFIER LA DEMANDE D'INSCRIPTION

SELECT 'Demande d''inscription pour Sasharohee26@gmail.com :' as info;
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

SELECT 'Emails de confirmation pour Sasharohee26@gmail.com :' as info;
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

-- 3. AFFICHER TOUS LES EMAILS EN ATTENTE

SELECT 'Tous les emails en attente de confirmation :' as info;
SELECT 
    user_email,
    token,
    status,
    created_at,
    expires_at,
    'http://localhost:3001/auth?tab=confirm&token=' || token as confirmation_url
FROM confirmation_emails 
WHERE status IN ('pending', 'sent')
ORDER BY created_at DESC;

-- 4. VÉRIFIER LES FONCTIONS DISPONIBLES

SELECT 'Fonctions de confirmation disponibles :' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%confirmation%'
ORDER BY routine_name;

-- 5. TESTER LA RÉGÉNÉRATION D'EMAIL

SELECT 'Test de régénération d''email pour Sasharohee26@gmail.com :' as test;
SELECT resend_confirmation_email_real('Sasharohee26@gmail.com') as result;

-- 6. AFFICHER LE CONTENU HTML DE L'EMAIL

SELECT 'Contenu HTML de l''email de confirmation :' as info;
SELECT 
    user_email,
    token,
    'http://localhost:3001/auth?tab=confirm&token=' || token as confirmation_url,
    status,
    created_at
FROM confirmation_emails 
WHERE user_email = 'Sasharohee26@gmail.com'
ORDER BY created_at DESC
LIMIT 1;

-- 7. MESSAGE DE CONFIRMATION

SELECT 'Vérification terminée - Consultez les résultats ci-dessus' as status;
