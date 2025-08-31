-- =====================================================
-- VÉRIFICATION WORKSHOP_ID UTILISATEUR
-- =====================================================

SELECT 'VÉRIFICATION WORKSHOP_ID UTILISATEUR' as section;

-- 1. VÉRIFIER LA TABLE SUBSCRIPTION_STATUS
-- =====================================================

SELECT 
    'SUBSCRIPTION_STATUS' as table_name,
    COUNT(*) as total_utilisateurs,
    COUNT(workshop_id) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM subscription_status;

-- 2. AFFICHER LES UTILISATEURS AVEC LEUR WORKSHOP_ID
-- =====================================================

SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    workshop_id,
    status,
    created_at
FROM subscription_status 
ORDER BY created_at DESC;

-- 3. VÉRIFIER LES WORKSHOP_ID DISTINCTS
-- =====================================================

SELECT 
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NOT NULL
GROUP BY workshop_id
ORDER BY nombre_utilisateurs DESC;

-- 4. VÉRIFIER LES UTILISATEURS SANS WORKSHOP_ID
-- =====================================================

SELECT 
    'UTILISATEURS SANS WORKSHOP_ID' as probleme,
    COUNT(*) as nombre,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NULL;

-- 5. VÉRIFIER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 6. VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 7. TESTER LA FONCTION AUTH.JWT()
-- =====================================================

-- Cette requête doit être exécutée par un utilisateur connecté
SELECT 
    'TEST AUTH.JWT()' as test,
    auth.jwt() as jwt_token,
    auth.jwt() ->> 'workshop_id' as workshop_id_from_jwt,
    auth.uid() as user_id_from_auth;

-- 8. VÉRIFIER LES CONTRAINTES DE LA TABLE ORDERS
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
  AND column_name IN ('workshop_id', 'created_by', 'created_at', 'updated_at')
ORDER BY column_name;

-- 9. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Workshop_id utilisateur vérifié' as description;
