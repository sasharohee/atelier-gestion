-- =====================================================
-- VÉRIFICATION ISOLATION IMMÉDIATE
-- =====================================================

SELECT 'VÉRIFICATION IMMÉDIATE' as section;

-- 1. VÉRIFIER L'UTILISATEUR ACTUEL
-- =====================================================

SELECT 
    'UTILISATEUR ACTUEL' as verification,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN '✅ Authentifié'
        ELSE '❌ Non authentifié'
    END as auth_status;

-- 2. VÉRIFIER LE WORKSHOP_ID DE L'UTILISATEUR ACTUEL
-- =====================================================

SELECT 
    'WORKSHOP_ID UTILISATEUR ACTUEL' as verification,
    ss.user_id,
    ss.email,
    ss.workshop_id,
    CASE 
        WHEN ss.workshop_id IS NOT NULL THEN '✅ Workshop_id défini'
        ELSE '❌ Workshop_id manquant'
    END as workshop_status
FROM subscription_status ss
WHERE ss.user_id = auth.uid();

-- 3. VÉRIFIER TOUTES LES COMMANDES
-- =====================================================

SELECT 
    'TOUTES LES COMMANDES' as verification,
    id,
    order_number,
    workshop_id,
    created_by,
    status,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 4. VÉRIFIER LES COMMANDES DE L'UTILISATEUR ACTUEL
-- =====================================================

SELECT 
    'COMMANDES UTILISATEUR ACTUEL' as verification,
    o.id,
    o.order_number,
    o.workshop_id as order_workshop_id,
    ss.workshop_id as user_workshop_id,
    o.created_by,
    o.status,
    CASE 
        WHEN o.workshop_id = ss.workshop_id THEN '✅ CORRECT'
        ELSE '❌ INCORRECT'
    END as isolation_status
FROM orders o
JOIN subscription_status ss ON o.created_by = ss.user_id
WHERE o.created_by = auth.uid()
ORDER BY o.created_at DESC;

-- 5. VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS' as verification,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 6. TESTER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    'TEST FONCTION ISOLATION' as verification,
    'Exécuter SELECT set_order_isolation();' as instruction;

-- 7. VÉRIFIER LES DOUBLONS DE WORKSHOP_ID
-- =====================================================

SELECT 
    'DOUBLONS WORKSHOP_ID' as verification,
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NOT NULL
GROUP BY workshop_id 
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 8. VÉRIFIER LES UTILISATEURS SANS WORKSHOP_ID
-- =====================================================

SELECT 
    'UTILISATEURS SANS WORKSHOP_ID' as verification,
    user_id,
    email,
    created_at
FROM subscription_status 
WHERE workshop_id IS NULL
ORDER BY created_at;

-- 9. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Diagnostic immédiat effectué' as description;
