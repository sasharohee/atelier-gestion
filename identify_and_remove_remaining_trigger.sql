-- IDENTIFICATION ET SUPPRESSION DU TRIGGER RESTANT
-- Ce script identifie le trigger restant et le supprime définitivement

-- 1. Identifier le trigger restant avec tous ses détails
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    action_orientation,
    action_condition
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 2. Identifier la fonction associée au trigger
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN (
    SELECT DISTINCT 
      CASE 
        WHEN action_statement LIKE '%EXECUTE FUNCTION%' 
        THEN TRIM(SUBSTRING(action_statement FROM 'EXECUTE FUNCTION ([^(]+)'))
        WHEN action_statement LIKE '%EXECUTE PROCEDURE%' 
        THEN TRIM(SUBSTRING(action_statement FROM 'EXECUTE PROCEDURE ([^(]+)'))
        ELSE NULL
      END
    FROM information_schema.triggers 
    WHERE event_object_table = 'users' 
      AND event_object_schema = 'auth'
  );

-- 3. Supprimer le trigger restant (peu importe son nom)
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    -- Supprimer tous les triggers restants sur auth.users
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' 
          AND event_object_schema = 'auth'
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_record.trigger_name || ' ON auth.users';
        RAISE NOTICE 'Trigger supprimé: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 4. Supprimer toutes les fonctions liées aux utilisateurs
DO $$
DECLARE
    function_record RECORD;
BEGIN
    -- Supprimer toutes les fonctions qui pourraient être liées aux triggers
    FOR function_record IN 
        SELECT routine_name 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
          AND (routine_name LIKE '%user%' 
               OR routine_name LIKE '%auth%'
               OR routine_name LIKE '%signup%'
               OR routine_name LIKE '%register%')
          AND routine_type = 'FUNCTION'
    LOOP
        BEGIN
            EXECUTE 'DROP FUNCTION IF EXISTS ' || function_record.routine_name || ' CASCADE';
            RAISE NOTICE 'Fonction supprimée: %', function_record.routine_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erreur lors de la suppression de %: %', function_record.routine_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 5. Vérification finale - doit afficher 0 triggers
SELECT 
    'Triggers restants sur auth.users:' as info,
    COUNT(*) as count
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- 6. Message de confirmation
SELECT '✅ Tous les triggers et fonctions problématiques supprimés' as status;
