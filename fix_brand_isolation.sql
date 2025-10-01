-- Script pour corriger l'isolation des données des marques
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier la structure de la table device_brands
SELECT '=== STRUCTURE DE LA TABLE device_brands ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les données actuelles
SELECT '=== DONNÉES ACTUELLES ===' as info;

SELECT id, name, user_id, created_at 
FROM public.device_brands 
ORDER BY created_at DESC 
LIMIT 10;

-- 3. Vérifier si la colonne user_id existe
SELECT '=== VÉRIFICATION COLONNE user_id ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'device_brands' 
            AND column_name = 'user_id'
            AND table_schema = 'public'
        ) THEN '✅ Colonne user_id existe'
        ELSE '❌ Colonne user_id manquante'
    END as status;

-- 4. Ajouter la colonne user_id si elle n'existe pas
DO $$
BEGIN
    -- Vérifier si la colonne user_id existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'user_id'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne user_id
        ALTER TABLE public.device_brands 
        ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        
        RAISE NOTICE '✅ Colonne user_id ajoutée à device_brands';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans device_brands';
    END IF;
END $$;

-- 5. Ajouter la colonne created_by si elle n'existe pas
DO $$
BEGIN
    -- Vérifier si la colonne created_by existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'created_by'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne created_by
        ALTER TABLE public.device_brands 
        ADD COLUMN created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
        
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_brands';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_brands';
    END IF;
END $$;

-- 6. Ajouter la colonne updated_by si elle n'existe pas
DO $$
BEGIN
    -- Vérifier si la colonne updated_by existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'device_brands' 
        AND column_name = 'updated_by'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne updated_by
        ALTER TABLE public.device_brands 
        ADD COLUMN updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
        
        RAISE NOTICE '✅ Colonne updated_by ajoutée à device_brands';
    ELSE
        RAISE NOTICE '✅ Colonne updated_by existe déjà dans device_brands';
    END IF;
END $$;

-- 7. Mettre à jour les marques existantes sans user_id
-- ATTENTION: Cette étape assigne les marques au premier utilisateur trouvé
-- Vous devrez peut-être ajuster cette logique selon vos besoins
DO $$
DECLARE
    first_user_id UUID;
BEGIN
    -- Récupérer le premier utilisateur
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
        -- Mettre à jour les marques sans user_id
        UPDATE public.device_brands 
        SET 
            user_id = first_user_id,
            created_by = first_user_id,
            updated_by = first_user_id
        WHERE user_id IS NULL;
        
        RAISE NOTICE '✅ Marques existantes assignées à l''utilisateur: %', first_user_id;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur trouvé pour assigner les marques existantes';
    END IF;
END $$;

-- 8. Vérifier les politiques RLS pour device_brands
SELECT '=== POLITIQUES RLS POUR device_brands ===' as info;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_brands'
ORDER BY policyname;

-- 9. Créer les politiques RLS si elles n'existent pas
DO $$
BEGIN
    -- Vérifier si RLS est activé
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_class 
        WHERE relname = 'device_brands' 
        AND relrowsecurity = true
    ) THEN
        -- Activer RLS
        ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS activé pour device_brands';
    ELSE
        RAISE NOTICE '✅ RLS déjà activé pour device_brands';
    END IF;
END $$;

-- 10. Créer les politiques RLS
-- Politique pour SELECT (lecture)
DROP POLICY IF EXISTS "Users can view their own brands" ON public.device_brands;
CREATE POLICY "Users can view their own brands" ON public.device_brands
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour INSERT (création)
DROP POLICY IF EXISTS "Users can create their own brands" ON public.device_brands;
CREATE POLICY "Users can create their own brands" ON public.device_brands
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour UPDATE (modification)
DROP POLICY IF EXISTS "Users can update their own brands" ON public.device_brands;
CREATE POLICY "Users can update their own brands" ON public.device_brands
    FOR UPDATE USING (auth.uid() = user_id);

-- Politique pour DELETE (suppression)
DROP POLICY IF EXISTS "Users can delete their own brands" ON public.device_brands;
CREATE POLICY "Users can delete their own brands" ON public.device_brands
    FOR DELETE USING (auth.uid() = user_id);

-- 11. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE DE device_brands ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 12. Vérifier les données avec user_id
SELECT '=== DONNÉES AVEC user_id ===' as info;

SELECT id, name, user_id, created_by, updated_by, created_at 
FROM public.device_brands 
ORDER BY created_at DESC 
LIMIT 10;

-- 13. Vérifier les politiques finales
SELECT '=== POLITIQUES RLS FINALES ===' as info;

SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'device_brands'
ORDER BY policyname;

SELECT '✅ Isolation des données des marques configurée !' as result;
