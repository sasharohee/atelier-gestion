-- Diagnostic des colonnes obligatoires de la table loyalty_points_history
-- Ce script identifie toutes les colonnes NOT NULL pour éviter les erreurs de contrainte

-- 1. VÉRIFIER LA STRUCTURE COMPLÈTE DE LA TABLE
SELECT '🔍 STRUCTURE COMPLÈTE DE LOYALTY_POINTS_HISTORY:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' THEN '⚠️ OBLIGATOIRE'
        ELSE '✅ OPTIONNEL'
    END as statut
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. IDENTIFIER LES COLONNES OBLIGATOIRES SANS VALEUR PAR DÉFAUT
SELECT '⚠️ COLONNES OBLIGATOIRES SANS VALEUR PAR DÉFAUT:' as info;

SELECT 
    column_name,
    data_type,
    'Colonne obligatoire sans valeur par défaut' as probleme
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
AND is_nullable = 'NO'
AND column_default IS NULL
ORDER BY column_name;

-- 3. VÉRIFIER LES COLONNES MANQUANTES DANS NOS FONCTIONS
SELECT '🔧 COLONNES À INCLURE DANS LES FONCTIONS:' as info;

SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name IN ('id', 'created_at') THEN 'Généré automatiquement'
        WHEN column_name = 'client_id' THEN 'Paramètre de fonction'
        WHEN column_name = 'points_change' THEN 'Calculé dans la fonction'
        WHEN column_name = 'points_before' THEN 'Récupéré de la base'
        WHEN column_name = 'points_after' THEN 'Calculé dans la fonction'
        WHEN column_name = 'description' THEN 'Paramètre de fonction'
        WHEN column_name = 'points_type' THEN 'Valeur fixe: manual/usage'
        WHEN column_name = 'source_type' THEN 'Valeur fixe: manual'
        ELSE 'À vérifier'
    END as traitement
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 4. GÉNÉRER LA REQUÊTE INSERT CORRECTE
SELECT '📝 REQUÊTE INSERT CORRECTE:' as info;

SELECT 
    'INSERT INTO loyalty_points_history (' ||
    string_agg(column_name, ', ' ORDER BY ordinal_position) ||
    ') VALUES (' ||
    string_agg(
        CASE 
            WHEN column_name = 'id' THEN 'gen_random_uuid()'
            WHEN column_name = 'client_id' THEN 'p_client_id'
            WHEN column_name = 'points_change' THEN 'p_points'
            WHEN column_name = 'points_before' THEN 'v_current_points'
            WHEN column_name = 'points_after' THEN 'v_new_points'
            WHEN column_name = 'description' THEN 'p_description'
            WHEN column_name = 'points_type' THEN '''manual'''
            WHEN column_name = 'source_type' THEN '''manual'''
            WHEN column_name = 'created_at' THEN 'NOW()'
            ELSE 'NULL'
        END, 
        ', ' ORDER BY ordinal_position
    ) ||
    ');' as requete_insert
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public';

-- 5. VÉRIFIER LES CONTRAINTES DE LA TABLE
SELECT '🔗 CONTRAINTES DE LA TABLE:' as info;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'loyalty_points_history' 
AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;

-- 6. RECOMMANDATIONS
SELECT '💡 RECOMMANDATIONS:' as info;

SELECT '1. Ajouter toutes les colonnes NOT NULL dans les requêtes INSERT' as recommandation
UNION ALL
SELECT '2. Utiliser des valeurs par défaut appropriées pour les colonnes obligatoires'
UNION ALL
SELECT '3. Tester les fonctions avec des données réelles'
UNION ALL
SELECT '4. Vérifier les contraintes de clé étrangère';

SELECT '✅ Diagnostic terminé !' as result;
