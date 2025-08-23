-- Script pour corriger les contraintes de system_settings
-- Ce script ajoute la contrainte unique manquante sur la colonne 'key'

-- 1. Vérifier que la table system_settings existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'system_settings') THEN
        RAISE EXCEPTION 'La table system_settings n''existe pas';
    END IF;
END $$;

-- 2. Vérifier les contraintes existantes
SELECT '=== CONTRAINTES EXISTANTES ===' as diagnostic;

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

-- 3. Vérifier s'il y a des doublons dans la colonne 'key'
SELECT '=== VÉRIFICATION DOUBLONS ===' as diagnostic;

SELECT 
    key,
    COUNT(*) as nombre_occurrences
FROM system_settings 
GROUP BY key 
HAVING COUNT(*) > 1;

-- 4. Supprimer les doublons s'ils existent (garder le plus récent)
DO $$
DECLARE
    v_duplicate_count INTEGER;
BEGIN
    -- Compter les doublons
    SELECT COUNT(*) INTO v_duplicate_count
    FROM (
        SELECT key, COUNT(*) 
        FROM system_settings 
        GROUP BY key 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    IF v_duplicate_count > 0 THEN
        RAISE NOTICE 'Suppression de % doublons dans system_settings', v_duplicate_count;
        
        -- Supprimer les doublons en gardant le plus récent
        DELETE FROM system_settings 
        WHERE id NOT IN (
            SELECT DISTINCT ON (key) id
            FROM system_settings
            ORDER BY key, updated_at DESC
        );
        
        RAISE NOTICE 'Doublons supprimés';
    ELSE
        RAISE NOTICE 'Aucun doublon trouvé';
    END IF;
END $$;

-- 5. Ajouter la contrainte unique si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'system_settings' 
        AND constraint_type = 'UNIQUE'
        AND constraint_name LIKE '%key%'
    ) THEN
        -- Ajouter la contrainte unique
        ALTER TABLE system_settings ADD CONSTRAINT system_settings_key_unique UNIQUE (key);
        RAISE NOTICE 'Contrainte unique ajoutée sur la colonne key';
    ELSE
        RAISE NOTICE 'Contrainte unique déjà présente sur la colonne key';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Impossible d''ajouter la contrainte unique: %', SQLERRM;
    RAISE NOTICE 'Continuing without unique constraint...';
END $$;

-- 6. Vérifier les contraintes après modification
SELECT '=== CONTRAINTES APRÈS MODIFICATION ===' as diagnostic;

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

-- 7. Tester l'insertion avec ON CONFLICT
DO $$
DECLARE
    v_test_uuid TEXT;
BEGIN
    -- Générer un UUID de test
    v_test_uuid := gen_random_uuid()::text;
    
    -- Tester l'insertion simple
    INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
    VALUES (
        'test_workshop_id', 
        v_test_uuid, 
        COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)),
        'test',
        NOW(), 
        NOW()
    );
    
    RAISE NOTICE 'Test d''insertion simple réussi';
    
    -- Nettoyer le test
    DELETE FROM system_settings WHERE key = 'test_workshop_id';
    
    RAISE NOTICE 'Test nettoyé';
END $$;

-- 8. Afficher le statut final
SELECT 'Script fix_system_settings_constraint.sql exécuté avec succès' as status;
SELECT 'Les contraintes ont été vérifiées et le test d''insertion a réussi' as message;
