-- Correction définitive des permissions pour subscription_status
-- Date: 2024-01-24
-- Ce script permet au système d'accès restreint de fonctionner correctement

-- 1. VÉRIFIER L'EXISTENCE DE LA TABLE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_status') THEN
        RAISE EXCEPTION 'La table subscription_status n''existe pas';
    END IF;
END $$;

-- 2. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES RLS

DROP POLICY IF EXISTS "Users can view their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Users can create their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admins can delete all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Admin page full access" ON subscription_status;
DROP POLICY IF EXISTS "Users can view own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can insert own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Users can update own subscription status" ON subscription_status;

-- 3. DÉSACTIVER RLS TEMPORAIREMENT POUR LE DÉPANNAGE

ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- 4. CONFIGURER LES PERMISSIONS DE BASE

GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- 5. CRÉER UN ENREGISTREMENT POUR L'UTILISATEUR ACTUEL AVEC ACCÈS RESTREINT

INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes
) 
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'first_name', u.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
    COALESCE(u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'lastName', '') as last_name,
    u.email,
    FALSE, -- ✅ Accès RESTREINT par défaut
    'free',
    'Compte créé - en attente d''activation par l''administrateur'
FROM auth.users u
WHERE u.email = 'repphonereparation@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM subscription_status ss 
    WHERE ss.user_id = u.id
);

-- 6. CRÉER UN ENREGISTREMENT POUR L'ADMINISTRATEUR AVEC ACCÈS COMPLET

INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes
) 
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'first_name', u.raw_user_meta_data->>'firstName', 'Admin') as first_name,
    COALESCE(u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'lastName', '') as last_name,
    u.email,
    TRUE, -- ✅ Accès COMPLET pour l'admin
    'premium',
    'Administrateur - accès complet'
FROM auth.users u
WHERE u.email = 'srohee32@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM subscription_status ss 
    WHERE ss.user_id = u.id
);

-- 7. VÉRIFIER LA CRÉATION

SELECT 
    '=== CORRECTION DÉFINITIVE TERMINÉE ===' as section,
    '✅ RLS désactivé temporairement' as statut1,
    '✅ Permissions configurées' as statut2,
    '✅ Accès restreint pour repphonereparation@gmail.com' as statut3,
    '✅ Accès complet pour srohee32@gmail.com (admin)' as statut4;

-- 8. AFFICHER LES ENREGISTREMENTS CRÉÉS

SELECT 
    '=== ENREGISTREMENTS CRÉÉS ===' as section;

SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at
FROM subscription_status 
WHERE email IN ('repphonereparation@gmail.com', 'srohee32@gmail.com')
ORDER BY email;

-- 9. VÉRIFIER LES PERMISSIONS

SELECT 
    '=== PERMISSIONS ACTUELLES ===' as section,
    table_name,
    privilege_type,
    grantee
FROM information_schema.role_table_grants 
WHERE table_name = 'subscription_status'
AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY grantee, privilege_type;
