-- =====================================================
-- CORRECTION COLONNE SETTING_KEY - TABLE SYSTEM_SETTINGS
-- =====================================================
-- Objectif: Corriger l'incohérence entre key et setting_key
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

-- 2. ANALYSE DE L'INCOHÉRENCE
SELECT '=== 2. ANALYSE DE L INCOHÉRENCE ===' as section;

-- Analyser quelle colonne existe et quelle est attendue
DO $$
DECLARE
    has_key BOOLEAN := FALSE;
    has_setting_key BOOLEAN := FALSE;
    has_user_id BOOLEAN := FALSE;
    has_setting_value BOOLEAN := FALSE;
    has_value BOOLEAN := FALSE;
BEGIN
    -- Vérifier les colonnes existantes
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) INTO has_key;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_key'
    ) INTO has_setting_key;
    
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
            AND column_name = 'setting_value'
    ) INTO has_setting_value;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'value'
    ) INTO has_value;
    
    RAISE NOTICE 'Structure system_settings: key=%, setting_key=%, user_id=%, setting_value=%, value=%', 
        has_key, has_setting_key, has_user_id, has_setting_value, has_value;
    
    IF has_setting_key AND NOT has_key THEN
        RAISE NOTICE '⚠️ Structure détectée: colonnes setting_key/setting_value (backend)';
    ELSIF has_key AND NOT has_setting_key THEN
        RAISE NOTICE '⚠️ Structure détectée: colonnes key/value (frontend)';
    ELSIF has_key AND has_setting_key THEN
        RAISE NOTICE '⚠️ Structure détectée: colonnes mixtes (problématique)';
    ELSE
        RAISE NOTICE '⚠️ Structure détectée: colonnes inconnues';
    END IF;
END $$;

-- 3. CORRECTION DE L'INCOHÉRENCE
SELECT '=== 3. CORRECTION DE L INCOHÉRENCE ===' as section;

-- Option 1: Si setting_key existe mais pas key, renommer setting_key en key
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_key'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) THEN
        -- Renommer setting_key en key
        ALTER TABLE public.system_settings RENAME COLUMN setting_key TO key;
        RAISE NOTICE '✅ Colonne setting_key renommée en key';
    ELSE
        RAISE NOTICE '✅ Pas de renommage nécessaire pour setting_key/key';
    END IF;
END $$;

-- Option 2: Si setting_value existe mais pas value, renommer setting_value en value
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_value'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'value'
    ) THEN
        -- Renommer setting_value en value
        ALTER TABLE public.system_settings RENAME COLUMN setting_value TO value;
        RAISE NOTICE '✅ Colonne setting_value renommée en value';
    ELSE
        RAISE NOTICE '✅ Pas de renommage nécessaire pour setting_value/value';
    END IF;
END $$;

-- 4. AJOUT DES COLONNES MANQUANTES
SELECT '=== 4. AJOUT DES COLONNES MANQUANTES ===' as section;

-- Ajouter key si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) THEN
        ALTER TABLE public.system_settings ADD COLUMN key VARCHAR(255);
        RAISE NOTICE '✅ Colonne key ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne key existe déjà';
    END IF;
END $$;

-- Ajouter value si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'value'
    ) THEN
        ALTER TABLE public.system_settings ADD COLUMN value TEXT;
        RAISE NOTICE '✅ Colonne value ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne value existe déjà';
    END IF;
END $$;

-- Ajouter user_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.system_settings ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà';
    END IF;
END $$;

-- Ajouter created_at si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.system_settings ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà';
    END IF;
END $$;

-- Ajouter updated_at si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.system_settings ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà';
    END IF;
END $$;

-- 5. CORRECTION DES CONTRAINTES NOT NULL
SELECT '=== 5. CORRECTION DES CONTRAINTES NOT NULL ===' as section;

-- Rendre key nullable si elle a une contrainte NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.system_settings ALTER COLUMN key DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de key';
    ELSE
        RAISE NOTICE '✅ Colonne key n''a pas de contrainte NOT NULL';
    END IF;
END $$;

-- Rendre value nullable si elle a une contrainte NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'value'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.system_settings ALTER COLUMN value DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de value';
    ELSE
        RAISE NOTICE '✅ Colonne value n''a pas de contrainte NOT NULL';
    END IF;
END $$;

-- 6. CRÉATION DE LA CONTRAINTE UNIQUE
SELECT '=== 6. CRÉATION DE LA CONTRAINTE UNIQUE ===' as section;

-- Créer la contrainte unique appropriée
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

-- 8. TEST D'INSERTION
SELECT '=== 8. TEST D INSERTION ===' as section;

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
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: % (user_id=%, key=%)', current_user_id, has_user_id, has_key;
    
    -- Test d'insertion selon la structure
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
    COUNT(CASE WHEN is_nullable = 'YES' THEN 1 END) as colonnes_nullables,
    (SELECT COUNT(*) FROM information_schema.table_constraints 
     WHERE table_schema = 'public' 
         AND table_name = 'system_settings' 
         AND constraint_type = 'UNIQUE') as contraintes_uniques
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings';

SELECT 'CORRECTION COLONNE SETTING_KEY SYSTEM_SETTINGS TERMINÉE' as status;
