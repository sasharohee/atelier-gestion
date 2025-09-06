-- Diagnostic de la structure des tables de fidélité
-- Ce script vérifie la structure actuelle des tables et colonnes

-- 1. VÉRIFIER L'EXISTENCE DES TABLES
SELECT '🔍 VÉRIFICATION DE L''EXISTENCE DES TABLES:' as info;

SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as statut
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('clients', 'loyalty_tiers', 'loyalty_points_history')
ORDER BY table_name;

-- 2. STRUCTURE DE LA TABLE CLIENTS
SELECT '📋 STRUCTURE DE LA TABLE CLIENTS:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IN ('loyalty_points', 'current_tier_id', 'created_by') THEN '🎯 Colonne fidélité'
        ELSE '📝 Colonne standard'
    END as type_colonne
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. STRUCTURE DE LA TABLE LOYALTY_TIERS
SELECT '🏆 STRUCTURE DE LA TABLE LOYALTY_TIERS:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'loyalty_tiers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. STRUCTURE DE LA TABLE LOYALTY_POINTS_HISTORY
SELECT '📊 STRUCTURE DE LA TABLE LOYALTY_POINTS_HISTORY:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. VÉRIFIER LES NIVEAUX DE FIDÉLITÉ
SELECT '🎯 NIVEAUX DE FIDÉLITÉ DISPONIBLES:' as info;

SELECT 
    name,
    description,
    COALESCE(points_required, 0) as points_required,
    COALESCE(discount_percentage, 0) as discount_percentage,
    COALESCE(color, '#000000') as color,
    COALESCE(is_active, true) as is_active
FROM loyalty_tiers
ORDER BY COALESCE(points_required, 0);

-- 6. STATISTIQUES DES CLIENTS
SELECT '👥 STATISTIQUES DES CLIENTS:' as info;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points IS NOT NULL THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as clients_avec_created_by,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients;

-- 7. VÉRIFIER LES FONCTIONS DE FIDÉLITÉ
SELECT '⚙️ FONCTIONS DE FIDÉLITÉ DISPONIBLES:' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments,
    p.oid as fonction_id
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('add_loyalty_points', 'use_loyalty_points')
ORDER BY p.proname, p.oid;

-- 8. VÉRIFIER LES CONTRAINTES DE CLÉ ÉTRANGÈRE
SELECT '🔗 CONTRAINTES DE CLÉ ÉTRANGÈRE:' as info;

SELECT 
    tc.table_name,
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
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND tc.table_name IN ('clients', 'loyalty_tiers', 'loyalty_points_history')
ORDER BY tc.table_name, kcu.column_name;

-- 9. RÉSUMÉ DES PROBLÈMES POTENTIELS
SELECT '⚠️ PROBLÈMES POTENTIELS IDENTIFIÉS:' as info;

-- Vérifier les colonnes manquantes dans clients
SELECT 
    'clients' as table_name,
    'loyalty_points' as colonne_manquante,
    'Colonne pour les points de fidélité' as description
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'loyalty_points'
    AND table_schema = 'public'
)

UNION ALL

SELECT 
    'clients' as table_name,
    'current_tier_id' as colonne_manquante,
    'Colonne pour le niveau de fidélité actuel' as description
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'current_tier_id'
    AND table_schema = 'public'
)

UNION ALL

SELECT 
    'loyalty_points_history' as table_name,
    'points_before' as colonne_manquante,
    'Colonne pour les points avant modification' as description
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'loyalty_points_history' 
    AND column_name = 'points_before'
    AND table_schema = 'public'
)

UNION ALL

SELECT 
    'loyalty_points_history' as table_name,
    'points_after' as colonne_manquante,
    'Colonne pour les points après modification' as description
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'loyalty_points_history' 
    AND column_name = 'points_after'
    AND table_schema = 'public'
);

-- 10. RECOMMANDATIONS
SELECT '💡 RECOMMANDATIONS:' as info;

SELECT '✅ Diagnostic terminé !' as result;
