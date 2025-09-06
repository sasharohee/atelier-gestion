-- Vérification des colonnes de fidélité dans la table clients
-- Ce script diagnostique pourquoi les points ne s'ajoutent pas au client

-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE CLIENTS
SELECT '🔍 STRUCTURE DE LA TABLE CLIENTS:' as info;

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

-- 2. VÉRIFIER SI LES COLONNES DE FIDÉLITÉ EXISTENT
SELECT '🎯 VÉRIFICATION DES COLONNES DE FIDÉLITÉ:' as info;

SELECT 
    'loyalty_points' as colonne,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' 
            AND column_name = 'loyalty_points'
            AND table_schema = 'public'
        ) THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as statut

UNION ALL

SELECT 
    'current_tier_id' as colonne,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' 
            AND column_name = 'current_tier_id'
            AND table_schema = 'public'
        ) THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as statut

UNION ALL

SELECT 
    'created_by' as colonne,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' 
            AND column_name = 'created_by'
            AND table_schema = 'public'
        ) THEN '✅ Existe'
        ELSE '❌ N''existe pas'
    END as statut;

-- 3. AJOUTER LES COLONNES MANQUANTES SI NÉCESSAIRE
SELECT '🔧 AJOUT DES COLONNES MANQUANTES...' as info;

DO $$ 
BEGIN
    -- Ajouter loyalty_points si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'loyalty_points'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN loyalty_points INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_points ajoutée';
    ELSE
        RAISE NOTICE 'Colonne loyalty_points existe déjà';
    END IF;
    
    -- Ajouter current_tier_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'current_tier_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN current_tier_id UUID;
        RAISE NOTICE 'Colonne current_tier_id ajoutée';
    ELSE
        RAISE NOTICE 'Colonne current_tier_id existe déjà';
    END IF;
    
    -- Ajouter created_by si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'created_by'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN created_by UUID;
        RAISE NOTICE 'Colonne created_by ajoutée';
    ELSE
        RAISE NOTICE 'Colonne created_by existe déjà';
    END IF;
END $$;

-- 4. VÉRIFIER LES NIVEAUX DE FIDÉLITÉ
SELECT '🏆 VÉRIFICATION DES NIVEAUX DE FIDÉLITÉ:' as info;

SELECT 
    name,
    description,
    COALESCE(points_required, 0) as points_required,
    COALESCE(discount_percentage, 0) as discount_percentage,
    COALESCE(color, '#000000') as color,
    COALESCE(is_active, true) as is_active
FROM loyalty_tiers
ORDER BY COALESCE(points_required, 0);

-- 5. METTRE À JOUR LES CLIENTS EXISTANTS
SELECT '🔄 MISE À JOUR DES CLIENTS EXISTANTS...' as info;

-- Mettre à jour les points de fidélité
UPDATE clients 
SET loyalty_points = COALESCE(loyalty_points, 0)
WHERE loyalty_points IS NULL;

-- Mettre à jour le niveau de fidélité avec Bronze par défaut
UPDATE clients 
SET current_tier_id = COALESCE(current_tier_id, (SELECT id FROM loyalty_tiers WHERE name = 'Bronze' LIMIT 1))
WHERE current_tier_id IS NULL;

-- 6. VÉRIFIER LES DONNÉES DES CLIENTS
SELECT '👥 DONNÉES DES CLIENTS:' as info;

SELECT 
    id,
    first_name,
    last_name,
    COALESCE(loyalty_points, 0) as loyalty_points,
    current_tier_id,
    created_at
FROM clients
ORDER BY created_at DESC
LIMIT 10;

-- 7. TESTER LA FONCTION ADD_LOYALTY_POINTS
SELECT '🧪 TEST DE LA FONCTION ADD_LOYALTY_POINTS:' as info;

-- Sélectionner un client pour le test
SELECT 
    'Client de test disponible:' as info,
    id as client_id,
    first_name,
    last_name,
    COALESCE(loyalty_points, 0) as points_actuels
FROM clients
LIMIT 1;

-- 8. VÉRIFIER LES PERMISSIONS
SELECT '🔐 VÉRIFICATION DES PERMISSIONS:' as info;

SELECT 
    grantee,
    privilege_type,
    table_name
FROM information_schema.role_table_grants
WHERE table_name = 'clients'
AND grantee IN ('authenticated', 'anon')
ORDER BY grantee, privilege_type;

-- 9. VÉRIFIER LES TRIGGERS OU RLS
SELECT '⚡ VÉRIFICATION DES TRIGGERS ET RLS:' as info;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'clients'
AND trigger_schema = 'public';

-- Vérifier RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'clients'
AND schemaname = 'public';

-- 10. RECOMMANDATIONS
SELECT '💡 RECOMMANDATIONS:' as info;

SELECT '1. Vérifier que les colonnes loyalty_points et current_tier_id existent' as recommandation
UNION ALL
SELECT '2. S''assurer que les niveaux de fidélité sont créés'
UNION ALL
SELECT '3. Tester la fonction avec un client_id valide'
UNION ALL
SELECT '4. Vérifier les permissions sur la table clients'
UNION ALL
SELECT '5. Contrôler les triggers et RLS qui pourraient bloquer les mises à jour';

SELECT '✅ Diagnostic terminé !' as result;
