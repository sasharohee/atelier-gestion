-- =====================================================
-- CORRECTION CONTRAINTE UNIQUE - TABLE SYSTEM_SETTINGS
-- =====================================================
-- Objectif: Corriger la contrainte unique manquante pour ON CONFLICT
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION STRUCTURE ACTUELLE
SELECT '=== 1. VÉRIFICATION STRUCTURE ACTUELLE ===' as section;

-- Vérifier les colonnes existantes dans la table system_settings
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;

-- 2. VÉRIFICATION DES CONTRAINTES EXISTANTES
SELECT '=== 2. VÉRIFICATION DES CONTRAINTES ===' as section;

-- Vérifier toutes les contraintes existantes
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'system_settings'
ORDER BY tc.constraint_type, kcu.column_name;

-- 3. VÉRIFICATION DES CONTRAINTES UNIQUES
SELECT '=== 3. VÉRIFICATION CONTRAINTES UNIQUES ===' as section;

-- Vérifier spécifiquement les contraintes UNIQUE
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) as columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'system_settings'
    AND tc.constraint_type = 'UNIQUE'
GROUP BY tc.constraint_name, tc.constraint_type;

-- 4. ANALYSE DE LA STRUCTURE POUR ON CONFLICT
SELECT '=== 4. ANALYSE POUR ON CONFLICT ===' as section;

-- Analyser quelle contrainte unique devrait exister pour ON CONFLICT
DO $$
DECLARE
    has_user_id BOOLEAN := FALSE;
    has_key BOOLEAN := FALSE;
    has_unique_constraint BOOLEAN := FALSE;
    constraint_name TEXT;
BEGIN
    -- Vérifier si user_id existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id'
    ) INTO has_user_id;
    
    -- Vérifier si key existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) INTO has_key;
    
    -- Vérifier s'il existe une contrainte unique sur (user_id, key)
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = 'public' 
            AND tc.table_name = 'system_settings'
            AND tc.constraint_type = 'UNIQUE'
            AND kcu.column_name IN ('user_id', 'key')
    ) INTO has_unique_constraint;
    
    RAISE NOTICE 'Structure system_settings: user_id=%, key=%, unique_constraint=%', has_user_id, has_key, has_unique_constraint;
    
    IF has_user_id AND has_key AND NOT has_unique_constraint THEN
        RAISE NOTICE '⚠️ Contrainte unique manquante sur (user_id, key) pour ON CONFLICT';
    ELSIF has_key AND NOT has_user_id AND NOT has_unique_constraint THEN
        RAISE NOTICE '⚠️ Contrainte unique manquante sur (key) pour ON CONFLICT';
    ELSIF has_unique_constraint THEN
        RAISE NOTICE '✅ Contrainte unique existe déjà';
    ELSE
        RAISE NOTICE '⚠️ Structure inconnue pour system_settings';
    END IF;
END $$;

-- 5. CRÉATION DE LA CONTRAINTE UNIQUE MANQUANTE
SELECT '=== 5. CRÉATION CONTRAINTE UNIQUE ===' as section;

-- Créer la contrainte unique appropriée selon la structure
DO $$
DECLARE
    has_user_id BOOLEAN := FALSE;
    has_key BOOLEAN := FALSE;
    constraint_exists BOOLEAN := FALSE;
    constraint_name TEXT;
BEGIN
    -- Vérifier la structure
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id'
    ) INTO has_user_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) INTO has_key;
    
    -- Vérifier si la contrainte existe déjà
    IF has_user_id AND has_key THEN
        -- Vérifier s'il existe une contrainte unique sur (user_id, key)
        SELECT EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu1 
                ON tc.constraint_name = kcu1.constraint_name
            JOIN information_schema.key_column_usage kcu2 
                ON tc.constraint_name = kcu2.constraint_name
            WHERE tc.table_schema = 'public' 
                AND tc.table_name = 'system_settings'
                AND tc.constraint_type = 'UNIQUE'
                AND kcu1.column_name = 'user_id'
                AND kcu2.column_name = 'key'
        ) INTO constraint_exists;
        
        IF NOT constraint_exists THEN
            constraint_name := 'system_settings_user_id_key_unique';
            EXECUTE format('ALTER TABLE public.system_settings ADD CONSTRAINT %I UNIQUE (user_id, key)', constraint_name);
            RAISE NOTICE '✅ Contrainte unique créée: % (user_id, key)', constraint_name;
        ELSE
            RAISE NOTICE '✅ Contrainte unique existe déjà sur (user_id, key)';
        END IF;
        
    ELSIF has_key AND NOT has_user_id THEN
        -- Vérifier s'il existe une contrainte unique sur (key)
        SELECT EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
            WHERE tc.table_schema = 'public' 
                AND tc.table_name = 'system_settings'
                AND tc.constraint_type = 'UNIQUE'
                AND kcu.column_name = 'key'
        ) INTO constraint_exists;
        
        IF NOT constraint_exists THEN
            constraint_name := 'system_settings_key_unique';
            EXECUTE format('ALTER TABLE public.system_settings ADD CONSTRAINT %I UNIQUE (key)', constraint_name);
            RAISE NOTICE '✅ Contrainte unique créée: % (key)', constraint_name;
        ELSE
            RAISE NOTICE '✅ Contrainte unique existe déjà sur (key)';
        END IF;
        
    ELSE
        RAISE NOTICE '⚠️ Structure non reconnue, impossible de créer la contrainte unique';
    END IF;
END $$;

-- 6. VÉRIFICATION DES COLONNES MANQUANTES
SELECT '=== 6. VÉRIFICATION COLONNES MANQUANTES ===' as section;

-- Vérifier et ajouter les colonnes essentielles si elles manquent
DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[
        'user_id',
        'key',
        'value',
        'created_at',
        'updated_at'
    ];
    col TEXT;
BEGIN
    FOREACH col IN ARRAY missing_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'system_settings' 
                AND column_name = col
        ) THEN
            RAISE NOTICE '⚠️ Colonne manquante: %', col;
            
            -- Ajouter la colonne selon son type
            IF col = 'user_id' THEN
                ALTER TABLE public.system_settings ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
                RAISE NOTICE '✅ Colonne user_id ajoutée';
            ELSIF col = 'key' THEN
                ALTER TABLE public.system_settings ADD COLUMN key VARCHAR(255) NOT NULL;
                RAISE NOTICE '✅ Colonne key ajoutée';
            ELSIF col = 'value' THEN
                ALTER TABLE public.system_settings ADD COLUMN value TEXT;
                RAISE NOTICE '✅ Colonne value ajoutée';
            ELSIF col = 'created_at' THEN
                ALTER TABLE public.system_settings ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
                RAISE NOTICE '✅ Colonne created_at ajoutée';
            ELSIF col = 'updated_at' THEN
                ALTER TABLE public.system_settings ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
                RAISE NOTICE '✅ Colonne updated_at ajoutée';
            END IF;
        ELSE
            RAISE NOTICE '✅ Colonne présente: %', col;
        END IF;
    END LOOP;
END $$;

-- 7. VÉRIFICATION FINALE
SELECT '=== 7. VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure finale
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;

-- Vérifier les contraintes finales
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) as columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'system_settings'
    AND tc.constraint_type = 'UNIQUE'
GROUP BY tc.constraint_name, tc.constraint_type;

-- 8. TEST D'INSERTION AVEC ON CONFLICT
SELECT '=== 8. TEST D INSERTION AVEC ON CONFLICT ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_setting_id UUID;
    has_user_id BOOLEAN := FALSE;
    has_key BOOLEAN := FALSE;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Vérifier la structure
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id'
    ) INTO has_user_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) INTO has_key;
    
    RAISE NOTICE '🔍 Test d''insertion avec ON CONFLICT pour utilisateur: % (user_id=%, key=%)', current_user_id, has_user_id, has_key;
    
    -- Test d'insertion avec ON CONFLICT selon la structure
    IF has_user_id AND has_key THEN
        -- Structure avec user_id et key
        INSERT INTO public.system_settings (
            user_id,
            key,
            value
        )
        VALUES (
            current_user_id,
            'test_setting',
            'test_value'
        )
        ON CONFLICT (user_id, key) 
        DO UPDATE SET 
            value = EXCLUDED.value,
            updated_at = NOW()
        RETURNING id INTO test_setting_id;
        
    ELSIF has_key AND NOT has_user_id THEN
        -- Structure avec key seulement
        INSERT INTO public.system_settings (
            key,
            value
        )
        VALUES (
            'test_setting',
            'test_value'
        )
        ON CONFLICT (key) 
        DO UPDATE SET 
            value = EXCLUDED.value,
            updated_at = NOW()
        RETURNING id INTO test_setting_id;
        
    ELSE
        -- Structure minimale
        INSERT INTO public.system_settings (
            key,
            value
        )
        VALUES (
            'test_setting',
            'test_value'
        )
        RETURNING id INTO test_setting_id;
    END IF;
    
    RAISE NOTICE '✅ Setting créé avec ID: %', test_setting_id;
    
    -- Nettoyer
    DELETE FROM public.system_settings WHERE id = test_setting_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 9. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 9. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 10. RÉSUMÉ FINAL
SELECT '=== 10. RÉSUMÉ FINAL ===' as section;

-- Résumé des corrections
SELECT 
    'Résumé corrections system_settings' as info,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name IN ('user_id', 'key', 'value') THEN 1 END) as colonnes_essentielles,
    (SELECT COUNT(*) FROM information_schema.table_constraints 
     WHERE table_schema = 'public' 
         AND table_name = 'system_settings' 
         AND constraint_type = 'UNIQUE') as contraintes_uniques
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings';

SELECT 'CORRECTION CONTRAINTE UNIQUE SYSTEM_SETTINGS TERMINÉE' as status;
