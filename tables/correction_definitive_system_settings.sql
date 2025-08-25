-- =====================================================
-- CORRECTION DÉFINITIVE - TABLE SYSTEM_SETTINGS
-- =====================================================
-- Objectif: Résoudre définitivement tous les problèmes de system_settings
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier toutes les colonnes existantes
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;

-- 2. SUPPRESSION DE TOUTES LES COLONNES PROBLÉMATIQUES
SELECT '=== 2. SUPPRESSION COLONNES PROBLÉMATIQUES ===' as section;

-- Supprimer toutes les colonnes problématiques qui pourraient causer des conflits
DO $$
BEGIN
    -- Supprimer setting_key si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_key'
    ) THEN
        ALTER TABLE public.system_settings DROP COLUMN setting_key;
        RAISE NOTICE '✅ Colonne setting_key supprimée';
    ELSE
        RAISE NOTICE '✅ Colonne setting_key n''existe pas';
    END IF;
    
    -- Supprimer setting_value si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_value'
    ) THEN
        ALTER TABLE public.system_settings DROP COLUMN setting_value;
        RAISE NOTICE '✅ Colonne setting_value supprimée';
    ELSE
        RAISE NOTICE '✅ Colonne setting_value n''existe pas';
    END IF;
    
    -- Supprimer setting_name si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_name'
    ) THEN
        ALTER TABLE public.system_settings DROP COLUMN setting_name;
        RAISE NOTICE '✅ Colonne setting_name supprimée';
    ELSE
        RAISE NOTICE '✅ Colonne setting_name n''existe pas';
    END IF;
    
    -- Supprimer setting_type si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_type'
    ) THEN
        ALTER TABLE public.system_settings DROP COLUMN setting_type;
        RAISE NOTICE '✅ Colonne setting_type supprimée';
    ELSE
        RAISE NOTICE '✅ Colonne setting_type n''existe pas';
    END IF;
END $$;

-- 3. SUPPRESSION DE TOUTES LES CONTRAINTES
SELECT '=== 3. SUPPRESSION CONTRAINTES ===' as section;

-- Supprimer toutes les contraintes existantes
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT constraint_name, constraint_type
        FROM information_schema.table_constraints 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings'
            AND constraint_type IN ('UNIQUE', 'PRIMARY KEY', 'FOREIGN KEY')
    LOOP
        EXECUTE format('ALTER TABLE public.system_settings DROP CONSTRAINT %I', constraint_record.constraint_name);
        RAISE NOTICE '✅ Contrainte supprimée: % (%)', constraint_record.constraint_name, constraint_record.constraint_type;
    END LOOP;
END $$;

-- 4. RECRÉATION COMPLÈTE DE LA TABLE
SELECT '=== 4. RECRÉATION COMPLÈTE ===' as section;

-- Sauvegarder les données existantes
CREATE TEMP TABLE temp_system_settings AS 
SELECT * FROM public.system_settings;

-- Supprimer la table existante
DROP TABLE IF EXISTS public.system_settings CASCADE;

-- Recréer la table avec la structure correcte
CREATE TABLE public.system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    key VARCHAR(255) NOT NULL,
    value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CRÉATION DES CONTRAINTES UNIQUES
SELECT '=== 5. CRÉATION CONTRAINTES UNIQUES ===' as section;

-- Créer la contrainte unique sur (user_id, key)
DO $$
BEGIN
    ALTER TABLE public.system_settings 
    ADD CONSTRAINT system_settings_user_id_key_unique UNIQUE (user_id, key);
    
    RAISE NOTICE '✅ Contrainte unique créée: system_settings_user_id_key_unique (user_id, key)';
END $$;

-- 6. RESTAURATION DES DONNÉES
SELECT '=== 6. RESTAURATION DONNÉES ===' as section;

-- Restaurer les données si elles existent
DO $$
DECLARE
    record_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO record_count FROM temp_system_settings;
    
    IF record_count > 0 THEN
        -- Insérer les données restaurées
        INSERT INTO public.system_settings (id, user_id, key, value, created_at, updated_at)
        SELECT 
            id,
            user_id,
            COALESCE(key, setting_key, 'unknown_key'),
            COALESCE(value, setting_value, ''),
            COALESCE(created_at, NOW()),
            COALESCE(updated_at, NOW())
        FROM temp_system_settings;
        
        RAISE NOTICE '✅ % enregistrements restaurés', record_count;
    ELSE
        RAISE NOTICE '✅ Aucune donnée à restaurer';
    END IF;
END $$;

-- 7. CRÉATION DES INDEX
SELECT '=== 7. CRÉATION INDEX ===' as section;

-- Créer des index pour améliorer les performances
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);
    CREATE INDEX IF NOT EXISTS idx_system_settings_key ON public.system_settings(key);
    CREATE INDEX IF NOT EXISTS idx_system_settings_user_key ON public.system_settings(user_id, key);
    
    RAISE NOTICE '✅ Index créés pour system_settings';
END $$;

-- 8. ACTIVATION RLS
SELECT '=== 8. ACTIVATION RLS ===' as section;

-- Activer RLS et créer les politiques
DO $$
BEGIN
    -- Activer RLS
    ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
    
    -- Créer les politiques RLS
    DROP POLICY IF EXISTS "Users can view their own settings" ON public.system_settings;
    CREATE POLICY "Users can view their own settings" ON public.system_settings
        FOR SELECT USING (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can insert their own settings" ON public.system_settings;
    CREATE POLICY "Users can insert their own settings" ON public.system_settings
        FOR INSERT WITH CHECK (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can update their own settings" ON public.system_settings;
    CREATE POLICY "Users can update their own settings" ON public.system_settings
        FOR UPDATE USING (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can delete their own settings" ON public.system_settings;
    CREATE POLICY "Users can delete their own settings" ON public.system_settings
        FOR DELETE USING (auth.uid() = user_id);
    
    RAISE NOTICE '✅ RLS activé et politiques créées';
END $$;

-- 9. VÉRIFICATION FINALE
SELECT '=== 9. VÉRIFICATION FINALE ===' as section;

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
GROUP BY tc.constraint_name, tc.constraint_type;

-- 10. TEST D'INSERTION
SELECT '=== 10. TEST D INSERTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_setting_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: %', current_user_id;
    
    -- Test d'insertion simple
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
    RETURNING id INTO test_setting_id;
    
    RAISE NOTICE '✅ Setting créé avec ID: %', test_setting_id;
    
    -- Test d'insertion avec ON CONFLICT
    INSERT INTO public.system_settings (
        user_id,
        key,
        value
    )
    VALUES (
        current_user_id,
        'test_setting',
        'updated_value'
    )
    ON CONFLICT (user_id, key) 
    DO UPDATE SET 
        value = EXCLUDED.value,
        updated_at = NOW();
    
    RAISE NOTICE '✅ Test ON CONFLICT réussi';
    
    -- Nettoyer
    DELETE FROM public.system_settings WHERE id = test_setting_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 11. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 11. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 12. RÉSUMÉ FINAL
SELECT '=== 12. RÉSUMÉ FINAL ===' as section;

-- Résumé des corrections
SELECT 
    'Résumé corrections system_settings' as info,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name IN ('user_id', 'key', 'value') THEN 1 END) as colonnes_essentielles,
    COUNT(CASE WHEN is_nullable = 'NO' THEN 1 END) as colonnes_not_null,
    (SELECT COUNT(*) FROM information_schema.table_constraints 
     WHERE table_schema = 'public' 
         AND table_name = 'system_settings' 
         AND constraint_type = 'UNIQUE') as contraintes_uniques
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings';

-- Nettoyer la table temporaire
DROP TABLE IF EXISTS temp_system_settings;

SELECT 'CORRECTION DÉFINITIVE SYSTEM_SETTINGS TERMINÉE' as status;
