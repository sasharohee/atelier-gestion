-- =====================================================
-- CORRECTION COLONNE CATEGORY - TABLE SYSTEM_SETTINGS
-- =====================================================
-- Objectif: Ajouter la colonne category si elle est nécessaire
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier si la colonne category existe
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
    AND column_name = 'category';

-- 2. AJOUT DE LA COLONNE CATEGORY
SELECT '=== 2. AJOUT COLONNE CATEGORY ===' as section;

DO $$
BEGIN
    -- Ajouter la colonne category si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'category'
    ) THEN
        ALTER TABLE public.system_settings ADD COLUMN category VARCHAR(100);
        RAISE NOTICE '✅ Colonne category ajoutée à system_settings';
    ELSE
        RAISE NOTICE '✅ Colonne category existe déjà dans system_settings';
    END IF;
END $$;

-- 3. MISE À JOUR DES DONNÉES EXISTANTES
SELECT '=== 3. MISE À JOUR DONNÉES EXISTANTES ===' as section;

DO $$
BEGIN
    -- Mettre à jour les catégories basées sur les clés existantes
    UPDATE public.system_settings 
    SET category = CASE 
        WHEN key LIKE 'workshop_%' THEN 'workshop'
        WHEN key LIKE 'notification_%' THEN 'notifications'
        WHEN key LIKE 'email_%' THEN 'emails'
        WHEN key LIKE 'security_%' THEN 'security'
        WHEN key LIKE 'display_%' THEN 'display'
        WHEN key LIKE 'system_%' THEN 'system'
        WHEN key LIKE 'backup_%' THEN 'backup'
        WHEN key LIKE 'integration_%' THEN 'integrations'
        ELSE 'general'
    END
    WHERE category IS NULL;
    
    RAISE NOTICE '✅ Catégories mises à jour pour les enregistrements existants';
END $$;

-- 4. VÉRIFICATION FINALE
SELECT '=== 4. VÉRIFICATION FINALE ===' as section;

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

-- Vérifier les données avec catégories
SELECT 
    category,
    COUNT(*) as count
FROM public.system_settings 
GROUP BY category 
ORDER BY category;

-- 5. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 5. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 6. TEST D'INSERTION
SELECT '=== 6. TEST D INSERTION ===' as section;

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
    
    -- Test d'insertion avec catégorie
    INSERT INTO public.system_settings (
        user_id,
        key,
        value,
        category
    )
    VALUES (
        current_user_id,
        'test_setting_with_category',
        'test_value',
        'test_category'
    )
    RETURNING id INTO test_setting_id;
    
    RAISE NOTICE '✅ Setting avec catégorie créé avec ID: %', test_setting_id;
    
    -- Nettoyer
    DELETE FROM public.system_settings WHERE id = test_setting_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

SELECT 'CORRECTION COLONNE CATEGORY SYSTEM_SETTINGS TERMINÉE' as status;
