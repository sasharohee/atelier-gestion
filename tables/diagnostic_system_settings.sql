-- Script de diagnostic pour la table system_settings
-- Ce script va analyser la structure et les contraintes de la table

-- 1. Vérifier la structure de la table
SELECT '=== STRUCTURE DE LA TABLE SYSTEM_SETTINGS ===' as diagnostic;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes
SELECT '=== CONTRAINTES DE LA TABLE ===' as diagnostic;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.is_deferrable,
    tc.initially_deferred
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'system_settings'
ORDER BY tc.constraint_type, kcu.column_name;

-- 3. Vérifier les données existantes
SELECT '=== DONNÉES EXISTANTES ===' as diagnostic;

SELECT 
    id,
    key,
    value,
    user_id,
    category,
    created_at,
    updated_at
FROM system_settings
ORDER BY key, created_at;

-- 4. Vérifier les valeurs NULL
SELECT '=== VALEURS NULL ===' as diagnostic;

SELECT 
    column_name,
    COUNT(*) as nombre_lignes_avec_null
FROM (
    SELECT 
        CASE WHEN id IS NULL THEN 'id' END as column_name
    FROM system_settings
    UNION ALL
    SELECT 
        CASE WHEN key IS NULL THEN 'key' END
    FROM system_settings
    UNION ALL
    SELECT 
        CASE WHEN value IS NULL THEN 'value' END
    FROM system_settings
    UNION ALL
    SELECT 
        CASE WHEN user_id IS NULL THEN 'user_id' END
    FROM system_settings
    UNION ALL
    SELECT 
        CASE WHEN category IS NULL THEN 'category' END
    FROM system_settings
    UNION ALL
    SELECT 
        CASE WHEN created_at IS NULL THEN 'created_at' END
    FROM system_settings
    UNION ALL
    SELECT 
        CASE WHEN updated_at IS NULL THEN 'updated_at' END
    FROM system_settings
) null_check
WHERE column_name IS NOT NULL
GROUP BY column_name
ORDER BY column_name;

-- 5. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as diagnostic;

SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ Non authentifié'
        ELSE '✅ Authentifié'
    END as statut;

-- 6. Vérifier les permissions
SELECT '=== PERMISSIONS ===' as diagnostic;

SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'system_settings'
ORDER BY grantee, privilege_type;

-- 7. Test d'insertion sécurisé
SELECT '=== TEST D''INSERTION SÉCURISÉ ===' as diagnostic;

DO $$
DECLARE
    v_user_id UUID;
    v_test_uuid TEXT;
    v_insert_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    v_test_uuid := gen_random_uuid()::text;
    
    -- Vérifier si l'utilisateur est authentifié
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Utilisateur non authentifié - Impossible d''insérer';
        RETURN;
    END IF;
    
    -- Tenter l'insertion
    BEGIN
        INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
        VALUES (
            'test_diagnostic', 
            v_test_uuid, 
            v_user_id,
            'diagnostic',
            NOW(), 
            NOW()
        );
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Insertion réussie avec user_id: %', v_user_id;
        
        -- Nettoyer le test
        DELETE FROM system_settings WHERE key = 'test_diagnostic';
        RAISE NOTICE '✅ Test nettoyé';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion: %', SQLERRM;
    END;
    
    IF v_insert_success THEN
        RAISE NOTICE '✅ Test d''insertion réussi';
    ELSE
        RAISE NOTICE '❌ Test d''insertion échoué';
    END IF;
END $$;

-- 8. Recommandations
SELECT '=== RECOMMANDATIONS ===' as diagnostic;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM system_settings WHERE user_id IS NULL) > 0 
        THEN '❌ CRITIQUE: Des enregistrements sans user_id existent'
        ELSE '✅ Tous les enregistrements ont un user_id'
    END as recommandation_1
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM system_settings WHERE key = 'workshop_id') = 0 
        THEN '⚠️ ATTENTION: Aucun workshop_id défini'
        ELSE '✅ Workshop_id défini'
    END as recommandation_2
UNION ALL
SELECT 
    CASE 
        WHEN auth.uid() IS NULL 
        THEN '❌ CRITIQUE: Utilisateur non authentifié'
        ELSE '✅ Utilisateur authentifié'
    END as recommandation_3;

-- 9. Afficher le statut final
SELECT 'Script diagnostic_system_settings.sql exécuté avec succès' as status;
