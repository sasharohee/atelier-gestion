-- VÉRIFICATION DE L'ÉTAT ACTUEL DE LA CONTRAINTE
-- Diagnostic complet pour identifier le problème

-- 1. VÉRIFIER TOUTES LES CONTRAINTES SUR LA TABLE CLIENTS
SELECT '🔍 TOUTES LES CONTRAINTES SUR CLIENTS' as diagnostic;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'clients'
    AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.constraint_name;

-- 2. VÉRIFIER SPÉCIFIQUEMENT LES CONTRAINTES SUR current_tier_id
SELECT '🔍 CONTRAINTES SUR current_tier_id' as diagnostic;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id'
    AND tc.constraint_type = 'FOREIGN KEY';

-- 3. VÉRIFIER LES TABLES EXISTANTES
SELECT '🏗️ TABLES LOYALTY EXISTANTES' as diagnostic;

SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%loyalty%'
AND table_schema = 'public'
ORDER BY table_name;

-- 4. VÉRIFIER LE CONTENU DES TABLES LOYALTY
SELECT '📊 CONTENU DES TABLES LOYALTY' as diagnostic;

-- Vérifier loyalty_tiers_advanced
SELECT 'loyalty_tiers_advanced:' as table_name;
SELECT 
    id,
    name,
    points_required,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 5. VÉRIFIER LES CLIENTS AVEC POINTS
SELECT '👤 CLIENTS AVEC POINTS' as diagnostic;

SELECT 
    id,
    first_name,
    last_name,
    email,
    loyalty_points,
    current_tier_id
FROM clients 
WHERE loyalty_points > 0
ORDER BY loyalty_points DESC;

-- 6. VÉRIFIER LES RÉFÉRENCES INCORRECTES
SELECT '🔗 RÉFÉRENCES CLIENTS-NIVEAUX' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.id as tier_id,
    lt.name as tier_name,
    CASE 
        WHEN c.current_tier_id IS NULL THEN '❌ Aucun niveau assigné'
        WHEN lt.id IS NULL THEN '❌ Niveau introuvable'
        ELSE '✅ Niveau correct'
    END as status
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 7. MESSAGE DE DIAGNOSTIC
SELECT '📋 DIAGNOSTIC TERMINÉ' as result;
SELECT '🔧 Préparez-vous à corriger les problèmes identifiés.' as next_step;


