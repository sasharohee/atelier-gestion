-- =====================================================
-- VÉRIFICATION STRUCTURE TABLE SUBSCRIPTION_STATUS
-- =====================================================

SELECT 'VÉRIFICATION STRUCTURE SUBSCRIPTION_STATUS' as section;

-- 1. VÉRIFIER L'EXISTENCE DE LA TABLE
-- =====================================================

SELECT 
    'EXISTENCE TABLE' as verification,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'subscription_status';

-- 2. AFFICHER TOUTES LES COLONNES DE LA TABLE
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'subscription_status'
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES CONTRAINTES DE LA TABLE
-- =====================================================

SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'subscription_status';

-- 4. AFFICHER LES DONNÉES ACTUELLES
-- =====================================================

SELECT 
    'DONNÉES ACTUELLES' as section,
    COUNT(*) as nombre_utilisateurs
FROM subscription_status;

-- 5. AFFICHER UN ÉCHANTILLON DES DONNÉES
-- =====================================================

SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    status,
    created_at
FROM subscription_status 
ORDER BY created_at DESC
LIMIT 5;

-- 6. VÉRIFIER LES INDEX
-- =====================================================

SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'subscription_status';

-- 7. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Structure de subscription_status vérifiée' as description;
